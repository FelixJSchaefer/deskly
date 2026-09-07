param(
    [string] $SourceLogo = "..\..\src\ErgonomiePhasen\Assets\DesklyIcon.png"
)

Add-Type -AssemblyName System.Drawing
$projectRoot = $PSScriptRoot
$sourcePath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $SourceLogo))
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
$iconFolder = Join-Path $projectRoot "Deskly\Resources\Assets.xcassets\AppIcon.appiconset"
$logoFolder = Join-Path $projectRoot "Deskly\Resources\Assets.xcassets\DesklyLogo.imageset"

function Save-AppIcon([int] $size, [string] $name) {
    $bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 255, 247, 241))
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $logoSize = $size * 0.88
    $offset = ($size - $logoSize) / 2
    $graphics.DrawImage($source, $offset, $offset, $logoSize, $logoSize)
    $graphics.Dispose()
    $bitmap.Save((Join-Path $iconFolder $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Save-TransparentLogo([int] $size, [string] $name) {
    $bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.DrawImage($source, 0, 0, $size, $size)
    $graphics.Dispose()
    $bitmap.Save((Join-Path $logoFolder $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$icons = @(
    @(20, "Icon-20.png"), @(40, "Icon-20@2x.png"), @(60, "Icon-20@3x.png"),
    @(29, "Icon-29.png"), @(58, "Icon-29@2x.png"), @(87, "Icon-29@3x.png"),
    @(40, "Icon-40.png"), @(80, "Icon-40@2x.png"), @(120, "Icon-40@3x.png"),
    @(120, "Icon-60@2x.png"), @(180, "Icon-60@3x.png"),
    @(76, "Icon-76.png"), @(152, "Icon-76@2x.png"), @(167, "Icon-83.5@2x.png"),
    @(1024, "Icon-1024.png")
)
foreach ($icon in $icons) { Save-AppIcon ([int]$icon[0]) ([string]$icon[1]) }
Save-TransparentLogo 256 "DesklyLogo.png"
Save-TransparentLogo 512 "DesklyLogo@2x.png"
Save-TransparentLogo 768 "DesklyLogo@3x.png"
$source.Dispose()

# 12-second mono PCM knocking sound. It loops only while Deskly is foregrounded;
# iOS plays the bundled file once when a local notification arrives in background.
$sampleRate = 44100
$seconds = 12
$sampleCount = $sampleRate * $seconds
$audio = New-Object byte[] ($sampleCount * 2)
$random = [System.Random]::new(34721)
$pulseStarts = @(0.20, 0.48, 1.75, 2.03, 3.30, 3.58, 4.85, 5.13, 6.40, 6.68, 7.95, 8.23, 9.50, 9.78, 11.05, 11.33)
for ($i = 0; $i -lt $sampleCount; $i++) {
    $time = $i / [double]$sampleRate
    $value = 0.0
    foreach ($start in $pulseStarts) {
        $age = $time - $start
        if ($age -ge 0 -and $age -lt 0.16) {
            $envelope = [Math]::Exp(-32 * $age)
            $tone = [Math]::Sin(2 * [Math]::PI * 165 * $age) + 0.45 * [Math]::Sin(2 * [Math]::PI * 245 * $age)
            $noise = ($random.NextDouble() * 2 - 1) * 0.18
            $value += ($tone * 0.42 + $noise) * $envelope
        }
    }
    $sample = [Math]::Max(-1, [Math]::Min(1, $value)) * 32767
    $integer = [int16]$sample
    $bytes = [BitConverter]::GetBytes($integer)
    $audio[$i * 2] = $bytes[0]
    $audio[$i * 2 + 1] = $bytes[1]
}
$wavePath = Join-Path $projectRoot "Deskly\Resources\Knock.wav"
$stream = [System.IO.File]::Create($wavePath)
$writer = [System.IO.BinaryWriter]::new($stream)
$writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
$writer.Write([int](36 + $audio.Length))
$writer.Write([Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
$writer.Write([int]16)
$writer.Write([int16]1)
$writer.Write([int16]1)
$writer.Write([int]$sampleRate)
$writer.Write([int]($sampleRate * 2))
$writer.Write([int16]2)
$writer.Write([int16]16)
$writer.Write([Text.Encoding]::ASCII.GetBytes("data"))
$writer.Write([int]$audio.Length)
$writer.Write($audio)
$writer.Dispose()
