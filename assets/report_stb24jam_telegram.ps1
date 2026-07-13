param(
    [Parameter(Mandatory=$true)]
    [string]$MonthlyFile,
    [Parameter(Mandatory=$true)]
    [string]$SheetName,
    [Parameter(Mandatory=$true)]
    [string]$BotToken,
    [Parameter(Mandatory=$true)]
    [string]$ChatId
)

$OutputEncoding = [System.Text.Encoding]::UTF8

# Helper function untuk menutup file Excel yang sedang terbuka
function Close-ExcelFile {
    param([string]$FilePath)
    
    try {
        $excelProc = Get-Process -Name "EXCEL" -ErrorAction SilentlyContinue
        if ($excelProc) {
            $tempExcel = New-Object -ComObject Excel.Application -ErrorAction SilentlyContinue
            if ($tempExcel) {
                $tempExcel.DisplayAlerts = $false
                foreach ($wb in $tempExcel.Workbooks) {
                    if ($wb.FullName -eq $FilePath) {
                        $wb.Close($false)
                        break
                    }
                }
                $tempExcel.Quit()
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($tempExcel) | Out-Null
            }
        }
    } catch {
        # Silent fail - tidak masalah jika gagal menutup
    }
}

# Validasi parameter
if (-not (Test-Path -Path $MonthlyFile)) {
    $errJson = @{
        success = $false
        message = "File bulanan tidak ditemukan: $MonthlyFile"
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

if ([string]::IsNullOrWhiteSpace($BotToken) -or [string]::IsNullOrWhiteSpace($ChatId)) {
    $errJson = @{
        success = $false
        message = "Bot Token dan Chat ID tidak boleh kosong. Silakan konfigurasi di halaman Settings."
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

$tempFolder = [System.IO.Path]::GetTempPath()
$imgDaily = Join-Path $tempFolder "stb24jam_daily_$SheetName.png"
$imgTrend = Join-Path $tempFolder "stb24jam_trend.png"

# Load .NET assemblies untuk akses clipboard
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── FUNGSI: Screenshot Sheet Excel ke File PNG ──
# Menghasilkan gambar persis seperti ketika blok sel → copy → paste sebagai gambar
function Export-SheetAsImage {
    param(
        [object]$Worksheet,
        [string]$OutputPath
    )
    
    # Tentukan range data yang terisi
    $lastRow = $Worksheet.Cells.Item($Worksheet.Rows.Count, 2).End(-4162).Row  # xlUp
    $lastCol = $Worksheet.Cells.Item(2, $Worksheet.Columns.Count).End(-4159).Column  # xlToLeft
    
    # Pastikan minimal ada data
    if ($lastRow -lt 2) { $lastRow = 10 }
    if ($lastCol -lt 22) { $lastCol = 22 }  # Minimal sampai kolom V (Result Total)
    
    $range = $Worksheet.Range($Worksheet.Cells.Item(1, 1), $Worksheet.Cells.Item($lastRow, $lastCol))
    
    # CopyPicture ke clipboard (xlScreen=1, xlBitmap=2)
    # Ini persis sama dengan blok sel → Copy as Picture di Excel
    $range.CopyPicture(1, 2) | Out-Null
    
    # Ambil gambar langsung dari Windows clipboard
    Start-Sleep -Milliseconds 300  # Beri waktu clipboard terisi
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    
    if ($null -ne $img) {
        $img.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $img.Dispose()
    }
    
    return $OutputPath
}

# ── FUNGSI: Kirim Foto ke Telegram ──
function Send-TelegramPhoto {
    param(
        [string]$Token,
        [string]$ChatId,
        [string]$PhotoPath,
        [string]$Caption
    )
    
    $uri = "https://api.telegram.org/bot$Token/sendPhoto"
    
    # Deteksi Topic ID (jika ada format ChatId_TopicId, misal -1002151560847_1485)
    $actualChatId = $ChatId
    $threadId = $null
    if ($ChatId -match "^(-?\d+)_(.+)$") {
        $actualChatId = $Matches[1]
        $threadId = $Matches[2]
    }
    
    # Buat multipart form-data menggunakan .NET
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBin = [System.IO.File]::ReadAllBytes($PhotoPath)
    $fileName = [System.IO.Path]::GetFileName($PhotoPath)
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"chat_id`"",
        "",
        $actualChatId,
        "--$boundary",
        "Content-Disposition: form-data; name=`"caption`"",
        "",
        $Caption,
        "--$boundary",
        "Content-Disposition: form-data; name=`"parse_mode`"",
        "",
        "HTML"
    )
    
    # Tambahkan parameter message_thread_id SEBELUM file part
    # agar tidak tercampur ke dalam binary data file
    if ($null -ne $threadId) {
        $bodyLines += @(
            "--$boundary",
            "Content-Disposition: form-data; name=`"message_thread_id`"",
            "",
            $threadId
        )
    }
    
    # File part HARUS TERAKHIR karena binary data disambung terpisah
    $bodyLines += @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"photo`"; filename=`"$fileName`"",
        "Content-Type: image/png",
        ""
    )
    
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes(($bodyLines -join "`r`n") + "`r`n")
    $footerBytes = [System.Text.Encoding]::UTF8.GetBytes("`r`n--$boundary--`r`n")
    
    $bodyStream = New-Object System.IO.MemoryStream
    $bodyStream.Write($headerBytes, 0, $headerBytes.Length)
    $bodyStream.Write($fileBin, 0, $fileBin.Length)
    $bodyStream.Write($footerBytes, 0, $footerBytes.Length)
    
    $bodyArray = $bodyStream.ToArray()
    $bodyStream.Dispose()
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body $bodyArray `
            -TimeoutSec 60
        return $response.ok
    } catch {
        return $false
    }
}

# ── FUNGSI: Kirim Dokumen ke Telegram ──
function Send-TelegramDocument {
    param(
        [string]$Token,
        [string]$ChatId,
        [string]$DocumentPath,
        [string]$Caption
    )
    
    $uri = "https://api.telegram.org/bot$Token/sendDocument"
    
    # Deteksi Topic ID (jika ada format ChatId_TopicId, misal -1002151560847_1485)
    $actualChatId = $ChatId
    $threadId = $null
    if ($ChatId -match "^(-?\d+)_(.+)$") {
        $actualChatId = $Matches[1]
        $threadId = $Matches[2]
    }
    
    $boundary = [System.Guid]::NewGuid().ToString()
    # Baca file dengan FileShare.ReadWrite agar tidak blocked oleh sisa lock Excel
    $fs = [System.IO.File]::Open($DocumentPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $fileBin = New-Object byte[] $fs.Length
    $fs.Read($fileBin, 0, $fs.Length) | Out-Null
    $fs.Close()
    $fs.Dispose()
    $fileName = [System.IO.Path]::GetFileName($DocumentPath)
    
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"chat_id`"",
        "",
        $actualChatId,
        "--$boundary",
        "Content-Disposition: form-data; name=`"caption`"",
        "",
        $Caption
    )
    
    # Tambahkan parameter message_thread_id SEBELUM file part
    # agar tidak tercampur ke dalam binary data file
    if ($null -ne $threadId) {
        $bodyLines += @(
            "--$boundary",
            "Content-Disposition: form-data; name=`"message_thread_id`"",
            "",
            $threadId
        )
    }
    
    # File part HARUS TERAKHIR karena binary data disambung terpisah
    $bodyLines += @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"document`"; filename=`"$fileName`"",
        "Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ""
    )
    
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes(($bodyLines -join "`r`n") + "`r`n")
    $footerBytes = [System.Text.Encoding]::UTF8.GetBytes("`r`n--$boundary--`r`n")
    
    $bodyStream = New-Object System.IO.MemoryStream
    $bodyStream.Write($headerBytes, 0, $headerBytes.Length)
    $bodyStream.Write($fileBin, 0, $fileBin.Length)
    $bodyStream.Write($footerBytes, 0, $footerBytes.Length)
    
    $bodyArray = $bodyStream.ToArray()
    $bodyStream.Dispose()
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body $bodyArray `
            -TimeoutSec 120
        return $response.ok
    } catch {
        return $false
    }
}

# ══════════════════════════════════════════════════════════════
# MAIN PROCESS
# ══════════════════════════════════════════════════════════════

$excel = $null
$workbook = $null
$tempDailyWb = $null
$tempTrendWb = $null

try {
    $excel = New-Object -ComObject Excel.Application
} catch {
    $errJson = @{
        success = $false
        message = "Microsoft Excel tidak terinstall atau COM interface tidak terdaftar di sistem ini."
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

$excel.Visible = $false
$excel.DisplayAlerts = $false
$excel.AskToUpdateLinks = $false
$excel.AutomationSecurity = 3

# Tunggu sebentar agar Excel COM siap
Start-Sleep -Milliseconds 500

try {
    # Coba tutup file jika sedang terbuka
    Close-ExcelFile -FilePath $MonthlyFile
    
    # Retry mechanism untuk membuka file
    $maxRetries = 3
    $retryCount = 0
    $workbookOpened = $false
    
    while (-not $workbookOpened -and $retryCount -lt $maxRetries) {
        try {
            # Buka workbook READ-ONLY agar tidak mengunci file
            $workbook = $excel.Workbooks.Open($MonthlyFile, 0, $true)
            $workbookOpened = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 2
                Close-ExcelFile -FilePath $MonthlyFile
            } else {
                throw "Gagal membuka file Excel setelah $maxRetries percobaan. `nPastikan file tidak sedang dibuka di aplikasi lain dan tidak corrupt. `nError: $($_.Exception.Message)"
            }
        }
    }
    
    if (-not $workbookOpened) {
        throw "Tidak dapat membuka file Excel: $MonthlyFile"
    }
    
    # ── STEP 1: Screenshot Sheet Harian ──
    $dailySheet = $null
    foreach ($sheet in $workbook.Worksheets) {
        if ($sheet.Name -eq $SheetName) {
            $dailySheet = $sheet
            break
        }
    }
    
    if ($null -eq $dailySheet) {
        $errJson = @{
            success = $false
            message = "Sheet harian '$SheetName' tidak ditemukan di file Excel."
        } | ConvertTo-Json -Compress
        Write-Output $errJson
        exit 1
    }
    
    # Hitung statistik dari sheet harian
    $maxRow = $dailySheet.Cells.Item($dailySheet.Rows.Count, 2).End(-4162).Row
    $lastCol = $dailySheet.Cells.Item(2, $dailySheet.Columns.Count).End(-4159).Column
    if ($lastCol -lt 22) { $lastCol = 22 }  # Minimal sampai kolom V (Result Total)
    
    $totalToko = $maxRow - 2
    $totalOk = 0
    $totalNok = 0
    $nokRows = @()
    
    # Kumpulkan baris NOK (Kolom O = CEK)
    for ($r = 3; $r -le $maxRow; $r++) {
        $cekVal = $dailySheet.Cells.Item($r, 15).Text  # Kolom O = CEK
        if ($cekVal -eq "OK") { $totalOk++ }
        elseif ($cekVal -eq "NOK") { 
            $totalNok++ 
            $nokRows += $r
        }
    }
    
    # ── Simpan Result Total VALUES dari sheet ASLI ke variabel ──
    $savedResultValues = @{}
    for ($r = 2; $r -le 8; $r++) {
        for ($c = 19; $c -le $lastCol; $c++) {
            $key = "$r,$c"
            $savedResultValues[$key] = $dailySheet.Cells.Item($r, $c).Value2
        }
    }
    
    # Buat workbook penampung sementara untuk harian
    $tempDailyWb = $excel.Workbooks.Add()
    $tempDailySheet = $tempDailyWb.Worksheets.Item(1)
    
    # 1. Copy header row 1-2, cols 1-17 (tanpa Result Total formula)
    $headerRange = $dailySheet.Range($dailySheet.Cells.Item(1, 1), $dailySheet.Cells.Item(2, 17))
    $headerRange.Copy($tempDailySheet.Range("A1")) | Out-Null
    
    # 2. Copy Result Total FULL (rows 2-8, cols 19-22) — PasteAll untuk format+merge
    $resultSrcRange = $dailySheet.Range($dailySheet.Cells.Item(2, 19), $dailySheet.Cells.Item(8, $lastCol))
    $resultSrcRange.Copy() | Out-Null
    $tempDailySheet.Range("S2").PasteSpecial(-4104) | Out-Null  # xlPasteAll
    $tempDailySheet.Cells.Item(100, 1).Select() | Out-Null  # Deselect
    
    # 3. Overwrite Result Total angka (rows 4, 7, 8) dengan saved values
    $dataRows = @(4, 7, 8)
    foreach ($r in $dataRows) {
        for ($c = 19; $c -le $lastCol; $c++) {
            $key = "$r,$c"
            $val = $savedResultValues[$key]
            if ($null -ne $val) {
                try { $tempDailySheet.Cells.Item($r, $c).Value2 = [int]$val } catch { }
            }
        }
    }
    
    # 4. Tulis NOK rows ke kolom 1-17 (mulai row 3)
    $destRow = 3
    foreach ($srcRow in $nokRows) {
        $srcRange = $dailySheet.Range($dailySheet.Cells.Item($srcRow, 1), $dailySheet.Cells.Item($srcRow, 17))
        $dstRange = $tempDailySheet.Range($tempDailySheet.Cells.Item($destRow, 1), $tempDailySheet.Cells.Item($destRow, 17))
        $srcRange.Copy($dstRange) | Out-Null
        $destRow++
    }
    
    # Update nomor urut (kolom A) di sheet sementara
    for ($i = 3; $i -lt $destRow; $i++) {
        $tempDailySheet.Cells.Item($i, 1).Value2 = $i - 2
    }
    
    # Samakan lebar kolom dengan sheet asli
    for ($c = 1; $c -le $lastCol; $c++) {
        $tempDailySheet.Columns.Item($c).ColumnWidth = $dailySheet.Columns.Item($c).ColumnWidth
    }
    # Samakan tinggi baris header
    $tempDailySheet.Rows.Item(1).RowHeight = $dailySheet.Rows.Item(1).RowHeight
    $tempDailySheet.Rows.Item(2).RowHeight = $dailySheet.Rows.Item(2).RowHeight
    
    # Screenshot sheet sementara (hanya NOK)
    Export-SheetAsImage -Worksheet $tempDailySheet -OutputPath $imgDaily | Out-Null
    
    # Tutup workbook sementara harian tanpa simpan
    $tempDailyWb.Close($false)
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($tempDailyWb) | Out-Null
    $tempDailyWb = $null
    
    # ── STEP 2: Screenshot Sheet TREND ──
    $trendSheet = $null
    foreach ($sheet in $workbook.Worksheets) {
        if ($sheet.Name -eq "TREND") {
            $trendSheet = $sheet
            break
        }
    }
    
    if ($null -ne $trendSheet) {
        $trendLastRow = $trendSheet.Cells.Item($trendSheet.Rows.Count, 2).End(-4162).Row
        
        # Cari kolom Total (header di row 9 berisi "Total")
        $totalCol = 0
        $trendLastCol = 16  # Default minimal sampai KETERANGAN
        for ($c = 5; $c -le 50; $c++) {
            $hdr = $trendSheet.Cells.Item(9, $c).Text
            if ($hdr -eq 'Total') { 
                $totalCol = $c
                $trendLastCol = $c + 1  # +1 untuk kolom KETERANGAN
                break
            }
        }
        
        if ($totalCol -gt 0) {
            # Cari kolom tanggal terbaru (kolom sebelum Total)
            $latestDateCol = $totalCol - 1
            
            # Kumpulkan baris yang NOK di tanggal terbaru saja
            $trendNokRows = @()
            for ($r = 10; $r -le $trendLastRow; $r++) {
                $cellVal = $trendSheet.Cells.Item($r, $latestDateCol).Text
                if ($cellVal -eq 'NOK') {
                    $trendNokRows += $r
                }
            }
            
            # Buat workbook penampung sementara untuk TREND
            $tempTrendWb = $excel.Workbooks.Add()
            $tempTrendSheet = $tempTrendWb.Worksheets.Item(1)
            
            # Copy header area (row 1-9) beserta format
            $trendHeader = $trendSheet.Range(
                $trendSheet.Cells.Item(1, 1), 
                $trendSheet.Cells.Item(9, $trendLastCol)
            )
            $trendHeader.Copy($tempTrendSheet.Range("A1")) | Out-Null
            
            # Copy baris-baris NOK di tanggal terbaru
            $destRow = 10
            foreach ($srcRow in $trendNokRows) {
                $srcRange = $trendSheet.Range(
                    $trendSheet.Cells.Item($srcRow, 1), 
                    $trendSheet.Cells.Item($srcRow, $trendLastCol)
                )
                $dstRange = $tempTrendSheet.Range(
                    $tempTrendSheet.Cells.Item($destRow, 1), 
                    $tempTrendSheet.Cells.Item($destRow, $trendLastCol)
                )
                $srcRange.Copy($dstRange) | Out-Null
                
                # Update nomor urut
                $tempTrendSheet.Cells.Item($destRow, 1).Value2 = $destRow - 9
                $destRow++
            }
            
            # Samakan lebar kolom
            for ($c = 1; $c -le $trendLastCol; $c++) {
                $tempTrendSheet.Columns.Item($c).ColumnWidth = $trendSheet.Columns.Item($c).ColumnWidth
            }
            # Samakan tinggi baris header
            for ($r = 1; $r -le 9; $r++) {
                $tempTrendSheet.Rows.Item($r).RowHeight = $trendSheet.Rows.Item($r).RowHeight
            }
            
            # ── FIX: Timpa summary (row 2-5) formula dengan VALUES dari sheet ASLI ──
            # Copy rows 2-5 dari sheet ASLI, lalu PasteSpecial Values ke temp sheet
            $summaryRange = $trendSheet.Range(
                $trendSheet.Cells.Item(2, 1), 
                $trendSheet.Cells.Item(5, $trendLastCol)
            )
            $summaryRange.Copy() | Out-Null
            $tempTrendSheet.Range("A2").PasteSpecial(-4163) | Out-Null  # xlPasteValues
            $tempTrendSheet.Cells.Item(100, 1).Select() | Out-Null  # Deselect
            
            # Screenshot sheet sementara
            Export-SheetAsImage -Worksheet $tempTrendSheet -OutputPath $imgTrend | Out-Null
            
            # Tutup workbook sementara TREND tanpa simpan
            $tempTrendWb.Close($false)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($tempTrendWb) | Out-Null
            $tempTrendWb = $null
        } else {
            # Fallback jika kolom total tidak ada
            Export-SheetAsImage -Worksheet $trendSheet -OutputPath $imgTrend | Out-Null
        }
    }
    
    # Tutup workbook utama sebelum mengirim file
    $workbook.Close($false)
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    $workbook = $null
    
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    $excel = $null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    # Tunggu sebentar agar file lock benar-benar terlepas
    Start-Sleep -Seconds 2
    
    # ── STEP 3: Kirim ke Telegram ──
    $sentCount = 0
    $failedItems = @()
    
    # Kirim screenshot sheet harian
    if (Test-Path $imgDaily) {
        $captionDaily = "<b>Rekap STB 24 Jam - Tanggal $SheetName</b>`n" +
                        "Total Toko : $totalToko`n" +
                        "OK : $totalOk | NOK : $totalNok`n"
        
        $resultDaily = Send-TelegramPhoto -Token $BotToken -ChatId $ChatId -PhotoPath $imgDaily -Caption $captionDaily
        if ($resultDaily) { $sentCount++ } else { $failedItems += "Screenshot Harian" }
    }
    
    # Kirim screenshot sheet TREND
    if (Test-Path $imgTrend) {
        $captionTrend = "<b>Report Trend STB 24 Jam</b>"
        $resultTrend = Send-TelegramPhoto -Token $BotToken -ChatId $ChatId -PhotoPath $imgTrend -Caption $captionTrend
        if ($resultTrend) { $sentCount++ } else { $failedItems += "Screenshot TREND" }
    }
    
    # Kirim file .xlsx    
    $resultDoc = Send-TelegramDocument -Token $BotToken -ChatId $ChatId -DocumentPath $MonthlyFile -Caption $captionDoc
    if ($resultDoc) { $sentCount++ } else { $failedItems += "File Excel" }
    
    # ── STEP 4: Cleanup ──
    if (Test-Path $imgDaily) { Remove-Item $imgDaily -Force -ErrorAction SilentlyContinue }
    if (Test-Path $imgTrend) { Remove-Item $imgTrend -Force -ErrorAction SilentlyContinue }
    
    # ── Output JSON ──
    if ($failedItems.Count -eq 0) {
        $successJson = @{
            success = $true
            message = "Berhasil mengirim $sentCount item ke Telegram!`nOK: $totalOk | NOK: $totalNok dari $totalToko toko."
            totalToko = $totalToko
            totalOk = $totalOk
            totalNok = $totalNok
            sentCount = $sentCount
        } | ConvertTo-Json -Compress
        Write-Output $successJson
    } else {
        $failedStr = $failedItems -join ", "
        $warnJson = @{
            success = $false
            message = "Sebagian gagal dikirim: $failedStr`nBerhasil: $sentCount item.`nPastikan Bot Token dan Chat ID sudah benar, dan bot sudah ditambahkan ke grup."
            sentCount = $sentCount
        } | ConvertTo-Json -Compress
        Write-Output $warnJson
        exit 1
    }
    
} catch {
    $errJson = @{
        success = $false
        message = "Kesalahan proses: " + $_.Exception.Message + " [at " + $_.ScriptStackTrace + "]"
    } | ConvertTo-Json -Compress
    Write-Output $errJson
} finally {
    # Cleanup gambar jika masih ada
    if (Test-Path $imgDaily -ErrorAction SilentlyContinue) { Remove-Item $imgDaily -Force -ErrorAction SilentlyContinue }
    if (Test-Path $imgTrend -ErrorAction SilentlyContinue) { Remove-Item $imgTrend -Force -ErrorAction SilentlyContinue }
    
    # COM Cleanup
    if ($tempDailyWb -ne $null) {
        $tempDailyWb.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($tempDailyWb) | Out-Null
    }
    if ($tempTrendWb -ne $null) {
        $tempTrendWb.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($tempTrendWb) | Out-Null
    }
    if ($workbook -ne $null) {
        $workbook.Close($false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    }
    if ($excel -ne $null) {
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
