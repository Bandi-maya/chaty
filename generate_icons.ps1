Add-Type -AssemblyName System.Drawing
$srcPath = "c:\Users\Bandi\Desktop\chat\assets\app_icon.png"
$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}
$srcImg = [System.Drawing.Image]::FromFile($srcPath)
foreach ($key in $sizes.Keys) {
    $size = $sizes[$key]
    $destDir = "c:\Users\Bandi\Desktop\chat\android\app\src\main\res\$key"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir }
    $destPath = Join-Path $destDir "ic_launcher.png"
    $destBitmap = New-Object System.Drawing.Bitmap $size, $size
    $graph = [System.Drawing.Graphics]::FromImage($destBitmap)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graph.DrawImage($srcImg, 0, 0, $size, $size)
    $destBitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graph.Dispose()
    $destBitmap.Dispose()
    Write-Host "Generated: $destPath ($size x $size)"
}
$srcImg.Dispose()
