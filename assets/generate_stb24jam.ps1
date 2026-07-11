param(
    [Parameter(Mandatory=$true)]
    [string]$TanggalStr, # Format: "dd-MM-yyyy"
    [Parameter(Mandatory=$true)]
    [string]$MonthlyFile,
    [Parameter(Mandatory=$true)]
    [string]$HasilPingFolder
)

# Set output encoding to UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Helper to get Excel column letters
function Get-ColumnLetter($colIndex) {
    $letter = ""
    while ($colIndex -gt 0) {
        $modulo = ($colIndex - 1) % 26
        $letter = [char](65 + $modulo) + $letter
        $colIndex = [int]([math]::Floor(($colIndex - $modulo) / 26))
    }
    return $letter
}

try {
    $tanggal = [datetime]::ParseExact($TanggalStr, "dd-MM-yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
} catch {
    $errJson = @{
        success = $false
        message = "Format tanggal tidak valid: $TanggalStr. Gunakan format dd-MM-yyyy."
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

$ddMMyyyy = $tanggal.ToString("ddMMyyyy")
$resultFiles = @{
    'JAM 00.00' = $null
    'JAM 01.00' = $null
    'JAM 02.00' = $null
    'JAM 03.00' = $null
}

if (-not (Test-Path -Path $HasilPingFolder)) {
    $errJson = @{
        success = $false
        message = "Folder hasil ping tidak ditemukan: $HasilPingFolder"
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

# Scan folder untuk mencari file ping dengan pola AutoPing_STB_{ddMMyyyy}_XXYY.xlsx
$pattern = "^AutoPing_STB_${ddMMyyyy}_(\d{2})\d{2}\.xlsx$"
$candidates = @{} # jamKey -> FileInfo

Get-ChildItem -Path $HasilPingFolder -File | ForEach-Object {
    if ($_.Name -match $pattern) {
        $jamPrefix = $Matches[1]
        $jamKey = $null
        if ($jamPrefix -eq '00') { $jamKey = 'JAM 00.00' }
        elseif ($jamPrefix -eq '01') { $jamKey = 'JAM 01.00' }
        elseif ($jamPrefix -eq '02') { $jamKey = 'JAM 02.00' }
        elseif ($jamPrefix -eq '03') { $jamKey = 'JAM 03.00' }
        
        if ($jamKey) {
            $existing = $candidates[$jamKey]
            if ($null -eq $existing -or $_.LastWriteTime -gt $existing.LastWriteTime) {
                $candidates[$jamKey] = $_
            }
        }
    }
}

# Periksa kelengkapan 4 file ping
$missing = @()
$pingKeys = @('JAM 00.00', 'JAM 01.00', 'JAM 02.00', 'JAM 03.00')
foreach ($key in $pingKeys) {
    if ($candidates.Contains($key)) {
        $resultFiles[$key] = $candidates[$key].FullName
    } else {
        $missing += $key
    }
}

if ($missing.Count -gt 0) {
    $msg = "File hasil ping untuk jam berikut tidak ditemukan di folder `"$HasilPingFolder`":`n" + ($missing -join "`n")
    $errJson = @{
        success = $false
        message = $msg
    } | ConvertTo-Json -Compress
    Write-Output $errJson
    exit 1
}

# --- OTOMATISASI PEMBUATAN FILE BULAN BARU JIKA BELUM ADA ---
if (-not (Test-Path -Path $MonthlyFile)) {
    $targetDir = Split-Path $MonthlyFile -Parent
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Cari file bulan sebelumnya
    $indonesianMonths = @(
        'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
        'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    )
    $prevMonthDate = $tanggal.AddMonths(-1)
    $prevMonthName = $indonesianMonths[$prevMonthDate.Month - 1]
    $prevMonthYear = $prevMonthDate.Year.ToString()
    
    # $MonthlyFile path format: root\tahun\STB 24 JAM BULAN.xlsx
    $rekapFolderRoot = Split-Path $targetDir -Parent
    $prevMonthFile = Join-Path $rekapFolderRoot "$prevMonthYear\STB 24 JAM $prevMonthName.xlsx"
    
    if (-not (Test-Path -Path $prevMonthFile)) {
        $errJson = @{
            success = $false
            message = "Gagal membuat file bulan baru otomatis karena file bulan sebelumnya tidak ditemukan di:`n$prevMonthFile"
        } | ConvertTo-Json -Compress
        Write-Output $errJson
        exit 1
    }
    
    # Salin file bulan sebelumnya sebagai basis file bulan baru
    Copy-Item -Path $prevMonthFile -Destination $MonthlyFile -Force
    
    # Bersihkan file baru tersebut menjadi template bulan baru
    $initExcel = $null
    $initWorkbook = $null
    try {
        $initExcel = New-Object -ComObject Excel.Application
        $initExcel.Visible = $false
        $initExcel.DisplayAlerts = $false
        
        $initWorkbook = $initExcel.Workbooks.Open($MonthlyFile, 0, $false)
        
        # 1. Hapus sheet harian yang tidak diperlukan (simpan hanya 3 hari terakhir dari bulan lalu)
        $keepDays = @(
            $tanggal.AddDays(-3).Day.ToString(),
            $tanggal.AddDays(-2).Day.ToString(),
            $tanggal.AddDays(-1).Day.ToString()
        )
        
        $sheetsToDelete = @()
        foreach ($sheet in $initWorkbook.Worksheets) {
            $name = $sheet.Name
            # Jika sheet harian (nama angka) dan bukan 3 hari terakhir bulan lalu
            if ($name -match '^\d+$') {
                if ($keepDays -notcontains $name) {
                    $sheetsToDelete += $sheet
                }
            }
        }
        foreach ($sheet in $sheetsToDelete) {
            $sheet.Delete()
        }
        
        # 2. Hapus kolom-kolom tanggal bulan lalu di sheet TREND
        $trendSheet = $initWorkbook.Worksheets.Item("TREND")
        if ($trendSheet -ne $null) {
            $totalColIndex = $null
            for ($c = 1; $c -le 50; $c++) {
                if ($trendSheet.Cells.Item(9, $c).Text -eq "Total") {
                    $totalColIndex = $c
                    break
                }
            }
            if ($null -eq $totalColIndex) { $totalColIndex = 13 }
            
            # Kolom tanggal dimulai dari indeks 5 (Column E)
            if ($totalColIndex -gt 5) {
                $colsToDelete = $totalColIndex - 5
                for ($i = 0; $i -lt $colsToDelete; $i++) {
                    $trendSheet.Columns.Item(5).Delete() | Out-Null
                }
            }
        }
        
        $initWorkbook.Save()
        $initWorkbook.Close($false)
        $initWorkbook = $null
    } catch {
        $errJson = @{
            success = $false
            message = "Gagal memproses inisialisasi file bulan baru: " + $_.Exception.Message
        } | ConvertTo-Json -Compress
        Write-Output $errJson
        if ($initWorkbook -ne $null) { $initWorkbook.Close($false) }
        if ($initExcel -ne $null) { $initExcel.Quit() }
        exit 1
    } finally {
        if ($initExcel -ne $null) {
            $initExcel.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($initExcel) | Out-Null
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

# Inisialisasi Excel COM Utama
$excel = $null
$workbook = $null
$yesterdaySheet = $null
$newSheet = $null
$trend = $null

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

try {
    # Buka workbook bulanan dengan UpdateLinks = 0 (jangan auto-update)
    $workbook = $excel.Workbooks.Open($MonthlyFile, 0, $false)
    
    $day = $tanggal.Day
    $yesterday = $tanggal.AddDays(-1)
    $yesterdaySheetName = $yesterday.Day.ToString()
    
    # 1. HAPUS SHEET HARI INI JIKA SUDAH ADA (Agar proses tindih/overwrite berhasil tanpa error)
    $existingTodaySheet = $null
    foreach ($sheet in $workbook.Worksheets) {
        if ($sheet.Name -eq $day.ToString()) {
            $existingTodaySheet = $sheet
            break
        }
    }
    if ($null -ne $existingTodaySheet) {
        $existingTodaySheet.Delete()
    }
    
    # Cari sheet hari kemarin
    foreach ($sheet in $workbook.Worksheets) {
        if ($sheet.Name -eq $yesterdaySheetName) {
            $yesterdaySheet = $sheet
            break
        }
    }
    
    if ($null -eq $yesterdaySheet) {
        $errJson = @{
            success = $false
            message = "Sheet hari kemarin ('$yesterdaySheetName') tidak ditemukan di file bulanan."
        } | ConvertTo-Json -Compress
        Write-Output $errJson
        exit 1
    }
    
    # Salin sheet kemarin untuk ditaruh sebelum sheet kemarin (aman di PowerShell COM)
    $yesterdaySheet.Copy($yesterdaySheet)
    $newSheet = $workbook.ActiveSheet
    $newSheet.Name = $day.ToString()
    
    # Pindahkan sheet baru agar berada setelah sheet kemarin (urutan maju)
    $newSheet.Move([System.Reflection.Missing]::Value, $yesterdaySheet)
    
    # Tentukan baris data terakhir di sheet kemarin
    $yesterdayMaxRow = $yesterdaySheet.Cells.Item($yesterdaySheet.Rows.Count, 2).End(-4162).Row # -4162 = xlUp
    
    # BEKUKAN (freeze) rumus kolom G s.d O di sheet kemarin menggunakan Copy & PasteSpecial (xlPasteValues)
    $yesterdayFreezeRange = $yesterdaySheet.Range("G3:O$yesterdayMaxRow")
    $yesterdayFreezeRange.Copy() | Out-Null
    $yesterdayFreezeRange.PasteSpecial(-4163) | Out-Null # -4163 = xlPasteValues
    
    # Tentukan baris data terakhir di sheet baru
    $maxRow = $newSheet.Cells.Item($newSheet.Rows.Count, 2).End(-4162).Row
    
    # --- UPDATE KOLOM H-3, H-2, H-1 (G, H, I) ---
    $d3 = $tanggal.AddDays(-3)
    $d2 = $tanggal.AddDays(-2)
    $d1 = $tanggal.AddDays(-1)
    
    $newSheet.Cells.Item(1, 7).Value2 = $d3.Day.ToString()
    $newSheet.Cells.Item(1, 8).Value2 = $d2.Day.ToString()
    $newSheet.Cells.Item(1, 9).Value2 = $d1.Day.ToString()
    
    $newSheet.Range("G3:G$maxRow").Formula = "=VLOOKUP(B3, '$($d3.Day)'!`$B`$3:`$O`$1000, 14, 0)"
    $newSheet.Range("H3:H$maxRow").Formula = "=VLOOKUP(B3, '$($d2.Day)'!`$B`$3:`$O`$1000, 14, 0)"
    $newSheet.Range("I3:I$maxRow").Formula = "=VLOOKUP(B3, '$($d1.Day)'!`$B`$3:`$O`$1000, 14, 0)"
    
    # --- BERIKAN FORMAT CONDITIONAL PADA KOLOM G, H, I ---
    # Mewarnai sel "NOK" menjadi merah muda (background) & merah tua (teks), "OK" tetap putih
    $formatRange = $newSheet.Range("G3:I$maxRow")
    $formatRange.FormatConditions.Delete() | Out-Null
    $condition = $formatRange.FormatConditions.Add(1, 3, "=`"NOK`"")
    $condition.Interior.Color = 13551615 # Light Pink BGR (206, 199, 255)
    $condition.Font.Color = 393372      # Dark Red BGR (6, 0, 156)
    
    # --- UPDATE KOLOM PING (J, K, L, M) ---
    $ping00 = $resultFiles['JAM 00.00']
    $ping01 = $resultFiles['JAM 01.00']
    $ping02 = $resultFiles['JAM 02.00']
    $ping03 = $resultFiles['JAM 03.00']
    
    $newSheet.Range("J3:J$maxRow").Formula = "=IFERROR(VLOOKUP(B3, '$ping00'!`$B`$2:`$F`$1000, 5, 0), ""NOK"")"
    $newSheet.Range("K3:K$maxRow").Formula = "=IFERROR(VLOOKUP(B3, '$ping01'!`$B`$2:`$F`$1000, 5, 0), ""NOK"")"
    $newSheet.Range("L3:L$maxRow").Formula = "=IFERROR(VLOOKUP(B3, '$ping02'!`$B`$2:`$F`$1000, 5, 0), ""NOK"")"
    $newSheet.Range("M3:M$maxRow").Formula = "=IFERROR(VLOOKUP(B3, '$ping03'!`$B`$2:`$F`$1000, 5, 0), ""NOK"")"
    
    # --- UPDATE KOLOM KETERANGAN (Q) ---
    # Keterangan otomatis hanya jika jumlah NOK (TEST di kolom N) lebih dari 1 (> 1)
    $newSheet.Range("Q3:Q$maxRow").Formula = "=IF(N3>1, ""PERLU CEK POWER STB SEBELUM TOKO TUTUP"", """")"
    
    # --- BACA DATA PING UNTUK REPORT TOKO TANPA DATA PING ---
    $pingLookups = @{
        'JAM 00.00' = @{}
        'JAM 01.00' = @{}
        'JAM 02.00' = @{}
        'JAM 03.00' = @{}
    }
    
    foreach ($jam in $pingKeys) {
        $filePath = $resultFiles[$jam]
        if ($filePath) {
            $pw = $excel.Workbooks.Open($filePath, 0, $true)
            $psheet = $pw.Worksheets.Item(1)
            $pMaxRow = $psheet.Cells.Item($psheet.Rows.Count, 2).End(-4162).Row
            for ($pr = 2; $pr -le $pMaxRow; $pr++) {
                $pkode = $psheet.Cells.Item($pr, 2).Text
                if ($pkode) {
                    $pingLookups[$jam][$pkode] = $true
                }
            }
            $pw.Close($false)
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($psheet) | Out-Null
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($pw) | Out-Null
        }
    }
    
    $tanpaData = @()
    for ($r = 3; $r -le $maxRow; $r++) {
        $kodeToko = $newSheet.Cells.Item($r, 2).Text
        if (-not $kodeToko) { continue }
        
        foreach ($jam in @('JAM 00.00', 'JAM 01.00', 'JAM 02.00', 'JAM 03.00')) {
            if (-not $pingLookups[$jam].Contains($kodeToko)) {
                $tanpaData += "$kodeToko ($jam)"
            }
        }
    }
    
    # Hitung ulang agar kolom TEST (kolom N) terupdate dengan data terbaru sebelum diurutkan
    $excel.CalculateFullRebuild()
    
    # --- URUTKAN BERDASARKAN KOLOM TEST (KOLOM N) DESCENDING ---
    # Mengurutkan kolom B s.d Q saja agar kolom A (penomoran No) tetap berurutan 1, 2, 3...
    $sortRange = $newSheet.Range("B3:Q$maxRow")
    $keyRange = $newSheet.Range("N3")
    $sortRange.Sort($keyRange, 2, 
                    [System.Reflection.Missing]::Value, 
                    [System.Reflection.Missing]::Value, 
                    1, 
                    [System.Reflection.Missing]::Value, 
                    1, 
                    2) | Out-Null
    
    # --- UPDATE SHEET TREND ---
    $trend = $workbook.Worksheets.Item("TREND")
    $trendMaxRow = $trend.Cells.Item($trend.Rows.Count, 2).End(-4162).Row
    
    # Cari posisi kolom "Total" di baris 9
    $totalColIndex = $null
    for ($c = 1; $c -le 50; $c++) {
        $headerVal = $trend.Cells.Item(9, $c).Text
        if ($headerVal -eq "Total") {
            $totalColIndex = $c
            break
        }
    }
    
    if ($null -eq $totalColIndex) {
        # Fallback mencari total / keterangan
        for ($c = 1; $c -le 50; $c++) {
            $headerVal = $trend.Cells.Item(8, $c).Text
            if ($headerVal -eq "Total" -or $headerVal -eq "KETERANGAN") {
                $totalColIndex = $c
                if ($headerVal -eq "KETERANGAN") { $totalColIndex = $c - 1 }
                break
            }
        }
    }
    
    if ($null -eq $totalColIndex) { $totalColIndex = 13 }
    
    # Cari apakah kolom untuk tanggal hari ini sudah ada di TREND (agar tidak terjadi kolom duplikat saat re-generate)
    $existingColIndex = $null
    for ($c = 5; $c -lt $totalColIndex; $c++) {
        if ($trend.Cells.Item(9, $c).Text -eq $day.ToString()) {
            $existingColIndex = $c
            break
        }
    }
    
    $newColIndex = $null
    $totalColIndexShifted = $totalColIndex
    $ketColIndexShifted = $totalColIndex + 1
    
    if ($null -ne $existingColIndex) {
        # Kolom tanggal sudah ada, gunakan kolom yang ada
        $newColIndex = $existingColIndex
    } else {
        # Kolom tanggal belum ada, sisipkan kolom baru tepat sebelum kolom Total
        $trend.Columns.Item($totalColIndex).Insert()
        $newColIndex = $totalColIndex
        $totalColIndexShifted = $totalColIndex + 1
        $ketColIndexShifted = $totalColIndex + 2
        
        # Salin format dari kolom kemarin ke kolom baru agar warnanya seragam
        $trend.Range($trend.Cells.Item(10, $newColIndex - 1), $trend.Cells.Item($trendMaxRow, $newColIndex - 1)).Copy() | Out-Null
        $trend.Range($trend.Cells.Item(10, $newColIndex), $trend.Cells.Item($trendMaxRow, $newColIndex)).PasteSpecial(-4122) | Out-Null # xlPasteFormats = -4122
        
        # Salin format ringkasan atas (rows 2-5)
        $trend.Range($trend.Cells.Item(2, $newColIndex - 1), $trend.Cells.Item(5, $newColIndex - 1)).Copy() | Out-Null
        $trend.Range($trend.Cells.Item(2, $newColIndex), $trend.Cells.Item(5, $newColIndex)).PasteSpecial(-4122) | Out-Null
        
        # Header tanggal baru
        $trend.Cells.Item(9, $newColIndex).Value2 = $day.ToString()
    }
    
    $newColLetter = Get-ColumnLetter $newColIndex
    $totalColLetter = Get-ColumnLetter $totalColIndexShifted
    
    # Isi VLOOKUP di kolom ke sheet hari ini
    $trend.Range($trend.Cells.Item(10, $newColIndex), $trend.Cells.Item($trendMaxRow, $newColIndex)).Formula = "=VLOOKUP(B10, '$day'!`$B`$3:`$O`$1000, 14, 0)"
    
    # Update formulas ringkasan atas (rows 2-5)
    $trend.Cells.Item(2, $newColIndex).Value2 = $day.ToString()
    $trend.Cells.Item(3, $newColIndex).Formula = "=COUNTIF(${newColLetter}10:${newColLetter}$trendMaxRow, ""OK"") + COUNTIF(${newColLetter}10:${newColLetter}$trendMaxRow, ""NOK"")"
    $trend.Cells.Item(4, $newColIndex).Formula = "=COUNTIF(${newColLetter}10:${newColLetter}$trendMaxRow, ""OK"")"
    $trend.Cells.Item(5, $newColIndex).Formula = "=COUNTIF(${newColLetter}10:${newColLetter}$trendMaxRow, ""NOK"")"
    
    # Update rumus COUNTIF di kolom Total (shifted)
    $trend.Range($trend.Cells.Item(10, $totalColIndexShifted), $trend.Cells.Item($trendMaxRow, $totalColIndexShifted)).Formula = "=COUNTIF(E10:${newColLetter}10, ""NOK"")"
    
    # Update rumus KETERANGAN (shifted) agar membaca sheet hari ini
    $trend.Range($trend.Cells.Item(10, $ketColIndexShifted), $trend.Cells.Item($trendMaxRow, $ketColIndexShifted)).Formula = "=VLOOKUP(B10, '$day'!`$B`$3:`$Q`$1000, 16, 0)"
    
    # Hitung ulang seluruh rumus kembali agar data TREND terisi sebelum diurutkan
    $excel.CalculateFullRebuild()
    
    # --- URUTKAN SHEET TREND BERDASARKAN TANGGAL BARU ASCENDING (A-Z) ---
    # Mengurutkan kolom B s.d KETERANGAN (index $ketColIndexShifted) agar kolom A (No) tetap berurutan 1, 2, 3...
    # Pengurutan Ascending (1) menempatkan "NOK" di atas (karena N < O) dan "OK" di bawah
    $trendSortRange = $trend.Range($trend.Cells.Item(10, 2), $trend.Cells.Item($trendMaxRow, $ketColIndexShifted))
    $trendKeyRange = $trend.Cells.Item(10, $newColIndex)
    $trendSortRange.Sort($trendKeyRange, 1, 
                         [System.Reflection.Missing]::Value, 
                         [System.Reflection.Missing]::Value, 
                         1, 
                         [System.Reflection.Missing]::Value, 
                         1, 
                         2) | Out-Null
    
    # Hitung ulang final setelah pengurutan selesai
    $excel.CalculateFullRebuild()
    
    # Hitung ringkasan statistik (OK / NOK) untuk JSON output
    $totalToko = $maxRow - 2
    $totalOk = 0
    $totalNok = 0
    for ($r = 3; $r -le $maxRow; $r++) {
        $cekVal = $newSheet.Cells.Item($r, 15).Text
        if ($cekVal -eq "OK") { $totalOk++ }
        elseif ($cekVal -eq "NOK") { $totalNok++ }
    }
    
    # Simpan workbook
    $workbook.Save()
    
    # Output JSON sukses
    $successJson = @{
        success = $true
        message = "Sheet `"$day`" dan TREND berhasil diperbarui menggunakan Excel COM Automation."
        totalToko = $totalToko
        totalOk = $totalOk
        totalNok = $totalNok
        tokoTanpaDataPing = $tanpaData
    } | ConvertTo-Json -Compress
    Write-Output $successJson
    
} catch {
    $errJson = @{
        success = $false
        message = "Kesalahan proses Excel: " + $_.Exception.Message
    } | ConvertTo-Json -Compress
    Write-Output $errJson
} finally {
    # COM Cleanup secara menyeluruh
    if ($newSheet -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($newSheet) | Out-Null }
    if ($yesterdaySheet -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($yesterdaySheet) | Out-Null }
    if ($trend -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($trend) | Out-Null }
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
