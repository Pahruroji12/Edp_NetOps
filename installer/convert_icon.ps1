Add-Type -AssemblyName System.Drawing

$inputPath = 'D:\DartProject\edp_netops\assets\logo.png'
$outputPath = 'D:\DartProject\edp_netops\assets\logo.ico'

$img = [System.Drawing.Image]::FromFile($inputPath)

$sizes = @(256, 48, 32, 16)
$memStream = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($memStream)

# ICO Header
$writer.Write([uint16]0)
$writer.Write([uint16]1)
$writer.Write([uint16]$sizes.Count)

# Placeholder directory entries (16 bytes each)
$dirEntryStart = $memStream.Position
foreach ($s in $sizes) {
    $writer.Write((New-Object byte[] 16))
}

# Write each PNG image
$imageOffsets = @()
$imageSizes = @()

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($img, $size, $size)
    $pngStream = New-Object System.IO.MemoryStream
    $bmp.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $pngStream.ToArray()

    $imageOffsets += $memStream.Position
    $imageSizes += $pngBytes.Length
    $writer.Write($pngBytes)

    $pngStream.Dispose()
    $bmp.Dispose()
}

# Fill directory entries
$memStream.Position = $dirEntryStart
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $w = if ($s -ge 256) { 0 } else { $s }
    $h = if ($s -ge 256) { 0 } else { $s }

    $writer.Write([byte]$w)
    $writer.Write([byte]$h)
    $writer.Write([byte]0)
    $writer.Write([byte]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]32)
    $writer.Write([uint32]$imageSizes[$i])
    $writer.Write([uint32]$imageOffsets[$i])
}

$fileBytes = $memStream.ToArray()
[System.IO.File]::WriteAllBytes($outputPath, $fileBytes)

$img.Dispose()
$memStream.Dispose()
$writer.Dispose()

Write-Host "Konversi berhasil! File ICO disimpan ke: $outputPath"
Write-Host "Ukuran file: $([math]::Round((Get-Item $outputPath).Length / 1KB, 1)) KB"
Write-Host "Resolusi yang disertakan: 256x256, 48x48, 32x32, 16x16"
