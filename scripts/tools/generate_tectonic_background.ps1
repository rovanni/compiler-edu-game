Add-Type -AssemblyName System.Drawing

$width = 1280
$height = 720
$output = Join-Path $PSScriptRoot "..\..\assets\fase2_scanner\tectonic_valley.png"
$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Céu e atmosfera do vale.
$sky = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, $width, $height),
    [System.Drawing.Color]::FromArgb(255, 35, 148, 205),
    [System.Drawing.Color]::FromArgb(255, 178, 224, 218),
    90)
$graphics.FillRectangle($sky, 0, 0, $width, $height)
$sky.Dispose()

function Polygon([System.Drawing.Graphics]$g, [System.Drawing.Brush]$brush, [int[]]$points) {
    $pts = [System.Collections.Generic.List[System.Drawing.Point]]::new()
    for ($i = 0; $i -lt $points.Length; $i += 2) { $pts.Add([System.Drawing.Point]::new($points[$i], $points[$i + 1])) }
    $g.FillPolygon($brush, $pts.ToArray())
}

$back = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 83, 135, 158))
Polygon $graphics $back @(0,430,130,300,230,405,355,245,495,425,635,275,780,420,935,250,1080,410,1195,300,1280,410,1280,720,0,720)
$back.Dispose()
$mid = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 52, 107, 116))
Polygon $graphics $mid @(0,500,165,360,290,475,430,325,610,510,760,340,915,500,1060,355,1280,490,1280,720,0,720)
$mid.Dispose()
$front = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 36, 78, 73))
Polygon $graphics $front @(0,590,170,445,330,560,485,425,640,565,800,440,975,575,1130,430,1280,545,1280,720,0,720)
$front.Dispose()

# Estrada serpenteando pelo centro do vale.
$road = New-Object System.Drawing.Drawing2D.GraphicsPath
$road.AddBezier(430,720,510,625,770,585,685,510)
$road.AddBezier(685,510,610,455,730,420,850,375)
$road.AddBezier(850,375,955,335,1000,305,1085,265)
$roadBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($road)
$roadBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 118, 91, 70)
$roadBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(255, 79, 64, 59))
$graphics.FillPath($roadBrush, $road)
$roadPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 241, 207, 124), 4)
$graphics.DrawPath($roadPen, $road)
$roadBrush.Dispose(); $roadPen.Dispose(); $road.Dispose()

# Carroça com dois personagens no trecho central da estrada.
$cartWood = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 107, 57, 34))
$cartDark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 57, 37, 32))
$wheelPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 47, 32, 28), 8)
$wheelInner = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 212, 153, 70), 3)
$graphics.FillRectangle($cartWood, 590, 492, 142, 38)
$graphics.FillRectangle($cartDark, 606, 470, 110, 28)
$graphics.DrawEllipse($wheelPen, 602, 515, 30, 30); $graphics.DrawEllipse($wheelPen, 690, 515, 30, 30)
$graphics.DrawEllipse($wheelInner, 607, 520, 20, 20); $graphics.DrawEllipse($wheelInner, 695, 520, 20, 20)
$graphics.DrawLine($wheelPen, 730, 501, 805, 477)

$skin = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 229, 164, 119))
$blue = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 32, 104, 164))
$gold = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 211, 157, 47))
$graphics.FillEllipse($skin, 630, 440, 19, 19); $graphics.FillRectangle($blue, 628, 458, 23, 29)
$graphics.FillEllipse($skin, 674, 435, 19, 19); $graphics.FillRectangle($gold, 671, 453, 26, 32)
$graphics.FillEllipse($cartDark, 629, 437, 21, 8); $graphics.FillEllipse($cartDark, 673, 432, 21, 8)
$graphics.DrawLine($wheelPen, 639, 487, 630, 501); $graphics.DrawLine($wheelPen, 684, 485, 695, 500)
$graphics.DrawLine($wheelPen, 640, 472, 622, 480); $graphics.DrawLine($wheelPen, 688, 469, 705, 478)
$graphics.DrawLine($wheelPen, 805, 477, 833, 463)

# Brilho atmosférico e silhuetas de vegetação nas bordas.
$mist = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 220, 244, 230))
$graphics.FillEllipse($mist, 220, 370, 360, 95); $graphics.FillEllipse($mist, 780, 300, 330, 90)
$mist.Dispose()
$cartWood.Dispose(); $cartDark.Dispose(); $wheelPen.Dispose(); $wheelInner.Dispose(); $skin.Dispose(); $blue.Dispose(); $gold.Dispose()
$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $bitmap.Dispose()
Write-Output $output
