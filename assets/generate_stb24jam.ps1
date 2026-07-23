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

# Helper function untuk menutup file Excel yang sedang terbuka di instance Excel mana pun
function Close-ExcelFile {
    param([string]$FilePath)
    
    try {
        $excelProc = Get-Process -Name "EXCEL" -ErrorAction SilentlyContinue
        if ($excelProc) {
            # Sambungkan ke instance Excel yang sedang aktif/berjalan di Windows
            $runningExcel = [System.Runtime.InteropServices.Marshal]::GetActiveObject("Excel.Application")
            if ($runningExcel) {
                $runningExcel.DisplayAlerts = $false
                foreach ($wb in $runningExcel.Workbooks) {
                    if ($wb.FullName -eq $FilePath -or $wb.Name -eq (Split-Path $FilePath -Leaf)) {
                        $wb.Close($false)
                        break
                    }
                }
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($runningExcel) | Out-Null
            }
        }
    } catch {
        # Silent fail - jika tidak ada instance aktif atau gagal mengakses
    }
}

# Helper function untuk mengekstrak kode toko dari file Excel hasil ping secara langsung (tanpa Excel COM)
# Sangat cepat, efisien, dan menghindari crash COM/file lock.
function Get-StoreCodesFromExcel {
    param([string]$filePath)
    
    $storeCodes = @()
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [System.IO.Compression.ZipFile]::OpenRead($filePath)
        
        # 1. Baca shared strings
        $sstEntry = $archive.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
        $sharedStrings = @()
        if ($sstEntry) {
            $stream = $sstEntry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xmlText = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            
            $xmlSst = [xml]$xmlText
            # Mengambil text di dalam <si><t> atau rich text <si><r><t>
            $sharedStrings = $xmlSst.sst.si | ForEach-Object {
                if ($_.t) {
                    $_.t.'#text'
                } else {
                    ($_.r | ForEach-Object { $_.t.'#text' }) -join ''
                }
            }
        }
        
        # 2. Baca data sheet1 (tabel utama)
        $sheetEntry = $archive.Entries | Where-Object { $_.FullName -eq 'xl/worksheets/sheet1.xml' }
        if ($sheetEntry) {
            $stream = $sheetEntry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xmlText = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            
            $xmlSheet = [xml]$xmlText
            $rows = $xmlSheet.worksheet.sheetData.row
            foreach ($row in $rows) {
                $rIndex = [int]$row.r
                if ($rIndex -lt 2) { continue } # Lewati baris header (1)
                
                foreach ($c in $row.c) {
                    # Cari sel pada Kolom B (Kode Toko)
                    if ($c.r -like 'B*') {
                        $val = $c.v
                        if ($c.t -eq 's') {
                            $idx = [int]$val
                            $storeCodes += $sharedStrings[$idx]
                        } else {
                            $storeCodes += $val
                        }
                    }
                }
            }
        }
        $archive.Dispose()
    } catch {
        # Silent fail - kembalikan data kosong atau yang sudah terbaca
    }
    return $storeCodes
}

# Helper function untuk mengambil map status ping (Kode Toko -> Status) dari file Excel hasil ping secara langsung (tanpa Excel COM)
function Get-PingStatusMapFromExcel {
    param([string]$filePath)
    
    $statusMap = @{}
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [System.IO.Compression.ZipFile]::OpenRead($filePath)
        
        # 1. Baca shared strings
        $sstEntry = $archive.Entries | Where-Object { $_.FullName -eq 'xl/sharedStrings.xml' }
        $sharedStrings = @()
        if ($sstEntry) {
            $stream = $sstEntry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xmlText = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            
            $xmlSst = [xml]$xmlText
            $sharedStrings = $xmlSst.sst.si | ForEach-Object {
                if ($_.t) {
                    $_.t.'#text'
                } else {
                    ($_.r | ForEach-Object { $_.t.'#text' }) -join ''
                }
            }
        }
        
        # 2. Baca data sheet1 (tabel utama)
        $sheetEntry = $archive.Entries | Where-Object { $_.FullName -eq 'xl/worksheets/sheet1.xml' }
        if ($sheetEntry) {
            $stream = $sheetEntry.Open()
            $reader = New-Object System.IO.StreamReader($stream)
            $xmlText = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            
            $xmlSheet = [xml]$xmlText
            $rows = $xmlSheet.worksheet.sheetData.row
            foreach ($row in $rows) {
                $rIndex = [int]$row.r
                if ($rIndex -lt 2) { continue } # Lewati baris header (1)
                
                $kodeToko = $null
                $status = $null
                
                foreach ($c in $row.c) {
                    # Ambil nilai dari Kolom B (Kode Toko)
                    if ($c.r -like 'B*') {
                        $val = $c.v
                        if ($c.t -eq 's') {
                            $kodeToko = $sharedStrings[[int]$val]
                        } else {
                            $kodeToko = $val
                        }
                    }
                    # Ambil nilai dari Kolom F (Status - OK / NOK)
                    elseif ($c.r -like 'F*') {
                        $val = $c.v
                        if ($c.t -eq 's') {
                            $status = $sharedStrings[[int]$val]
                        } else {
                            $status = $val
                        }
                    }
                }
                
                if ($kodeToko -and $status) {
                    $statusMap[$kodeToko] = $status
                }
            }
        }
        $archive.Dispose()
    } catch {
        # Silent fail
    }
    return $statusMap
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
        
        # Tutup file jika sedang terbuka
        Close-ExcelFile -FilePath $MonthlyFile
        
        # Retry mechanism untuk membuka file
        $maxRetries = 3
        $retryCount = 0
        $workbookOpened = $false
        
        while (-not $workbookOpened -and $retryCount -lt $maxRetries) {
            try {
                $initWorkbook = $initExcel.Workbooks.Open($MonthlyFile, 0, $false)
                $workbookOpened = $true
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Start-Sleep -Seconds 2
                    Close-ExcelFile -FilePath $MonthlyFile
                } else {
                    throw "Gagal membuka file Excel setelah $maxRetries percobaan: $($_.Exception.Message)"
                }
            }
        }
        
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
    # Tutup file jika sedang terbuka
    Close-ExcelFile -FilePath $MonthlyFile
    
    # Retry mechanism untuk membuka file
    $maxRetries = 3
    $retryCount = 0
    $workbookOpened = $false
    
    while (-not $workbookOpened -and $retryCount -lt $maxRetries) {
        try {
            $workbook = $excel.Workbooks.Open($MonthlyFile, 0, $false)
            $workbookOpened = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 2
                Close-ExcelFile -FilePath $MonthlyFile
            } else {
                throw "Gagal membuka file Excel setelah $maxRetries percobaan. `nPastikan file tidak sedang dibuka di aplikasi lain dan tidak di-lock. `nDetail Error: $($_.Exception.Message)"
            }
        }
    }
    
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
    
    $statusMap00 = Get-PingStatusMapFromExcel -filePath $ping00
    $statusMap01 = Get-PingStatusMapFromExcel -filePath $ping01
    $statusMap02 = Get-PingStatusMapFromExcel -filePath $ping02
    $statusMap03 = Get-PingStatusMapFromExcel -filePath $ping03

    # Tulis data ping langsung ke sel sebagai VALUE (bukan formula VLOOKUP)
    # Ini 100% aman dari file corrupt dan tidak memerlukan Excel COM untuk membaca file ping
    for ($r = 3; $r -le $maxRow; $r++) {
        $kodeToko = $newSheet.Cells.Item($r, 2).Text
        if ($kodeToko) {
            # Jam 00.00
            $val00 = "NOK"
            if ($statusMap00.ContainsKey($kodeToko)) { $val00 = $statusMap00[$kodeToko] }
            $newSheet.Cells.Item($r, 10).Value2 = $val00
            
            # Jam 01.00
            $val01 = "NOK"
            if ($statusMap01.ContainsKey($kodeToko)) { $val01 = $statusMap01[$kodeToko] }
            $newSheet.Cells.Item($r, 11).Value2 = $val01

            # Jam 02.00
            $val02 = "NOK"
            if ($statusMap02.ContainsKey($kodeToko)) { $val02 = $statusMap02[$kodeToko] }
            $newSheet.Cells.Item($r, 12).Value2 = $val02

            # Jam 03.00
            $val03 = "NOK"
            if ($statusMap03.ContainsKey($kodeToko)) { $val03 = $statusMap03[$kodeToko] }
            $newSheet.Cells.Item($r, 13).Value2 = $val03
        }
    }
    
    # --- BERIKAN FORMAT CONDITIONAL PADA KOLOM J, K, L, M (Jam 00-03) ---
    # Mewarnai sel "NOK" menjadi Light Red Fill with Dark Red Text
    $pingFormatRange = $newSheet.Range("J3:M$maxRow")
    $pingFormatRange.FormatConditions.Delete() | Out-Null
    $pingCondition = $pingFormatRange.FormatConditions.Add(1, 3, "=`"NOK`"")
    $pingCondition.Interior.Color = 13551615 # Light Pink BGR (206, 199, 255)
    $pingCondition.Font.Color = 393372       # Dark Red BGR (6, 0, 156)
    
    # --- UPDATE KOLOM TEST (N) & CEK (O) & KETERANGAN (Q) ---
    $newSheet.Range("N3:N$maxRow").Formula = "=COUNTIF(J3:M3, ""NOK"")"
    $newSheet.Range("O3:O$maxRow").Formula = "=IF(N3>=2, ""NOK"", ""OK"")"
    
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
            $storeCodes = Get-StoreCodesFromExcel -filePath $filePath
            foreach ($pkode in $storeCodes) {
                if ($pkode) {
                    $pingLookups[$jam][$pkode] = $true
                }
            }
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
    
    # --- AUTOHIDE KOLOM TREND (MAKSIMAL 15 HARI TERAKHIR YANG TAMPIL) ---
    # Tampilkan seluruh kolom terlebih dahulu agar tidak ada kolom tersembunyi yang terlewat
    $trend.Columns.Hidden = $false
    
    # Cari kembali indeks kolom Total terbaru setelah ada pergeseran
    $currentTotalColIndex = $null
    for ($c = 1; $c -le 100; $c++) {
        $headerVal = $trend.Cells.Item(9, $c).Text
        if ($headerVal -eq "Total") {
            $currentTotalColIndex = $c
            break
        }
    }
    
    if ($null -ne $currentTotalColIndex -and $currentTotalColIndex -gt 5) {
        $firstDateCol = 5 # Kolom tanggal dimulai dari Kolom E (indeks 5)
        $lastDateCol = $currentTotalColIndex - 1
        $totalDateCols = $lastDateCol - $firstDateCol + 1
        
        if ($totalDateCols -gt 15) {
            $colsToHide = $totalDateCols - 15
            # Sembunyikan kolom tanggal terlama dari Kolom E sampai Kolom E + colsToHide - 1
            for ($c = $firstDateCol; $c -lt ($firstDateCol + $colsToHide); $c++) {
                $trend.Columns.Item($c).EntireColumn.Hidden = $true
            }
        }
    }
    
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
