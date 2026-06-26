Add-Type -AssemblyName System.Drawing

function RoundedRect($g, $brush, $pen, $x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($x, $y, $r*2, $r*2, 180, 90)
  $path.AddArc($x+$w-$r*2, $y, $r*2, $r*2, 270, 90)
  $path.AddArc($x+$w-$r*2, $y+$h-$r*2, $r*2, $r*2, 0, 90)
  $path.AddArc($x, $y+$h-$r*2, $r*2, $r*2, 90, 90)
  $path.CloseFigure()
  if ($brush) { $g.FillPath($brush, $path) }
  if ($pen)   { $g.DrawPath($pen, $path) }
}

$W = 1400; $H = 380
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Background gradient
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  [System.Drawing.Point]::new(0,0),
  [System.Drawing.Point]::new($W,$H),
  [System.Drawing.Color]::FromArgb(255, 0, 18, 70),
  [System.Drawing.Color]::FromArgb(255, 0, 45, 120)
)
$g.FillRectangle($bg, 0, 0, $W, $H)

# Glow blobs
$blobs = @(
  @{cx=1200;cy=-50;r=340;a=28},
  @{cx=180;cy=400;r=280;a=16}
)
foreach ($blob in $blobs) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddEllipse($blob.cx-$blob.r, $blob.cy-$blob.r, $blob.r*2, $blob.r*2)
  $gb = New-Object System.Drawing.Drawing2D.PathGradientBrush($p)
  $gb.CenterColor    = [System.Drawing.Color]::FromArgb($blob.a, 0, 179, 255)
  $gb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 18, 70))
  $g.FillPath($gb, $p)
}

$centerFmt = New-Object System.Drawing.StringFormat
$centerFmt.Alignment     = [System.Drawing.StringAlignment]::Center
$centerFmt.LineAlignment = [System.Drawing.StringAlignment]::Center

$cyanColor  = [System.Drawing.Color]::FromArgb(255, 0, 200, 255)
$cyanBrush  = New-Object System.Drawing.SolidBrush($cyanColor)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$subBrush   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(185,255,255,255))

# Badge pill
$bW = 242; $bH = 28; $bX = ($W-$bW)/2; $bY = 44
$badgeFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50,0,179,255))
$badgePen  = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160,0,210,255), 1.2)
RoundedRect $g $badgeFill $badgePen $bX $bY $bW $bH 14
$badgeFont = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$dot = [char]0x00B7
$g.DrawString("CLAUDE CODE  $dot  SKILLS", $badgeFont, $cyanBrush,
  [System.Drawing.RectangleF]::new($bX,$bY,$bW,$bH), $centerFmt)

# Title line 1 — white
$t1Font = New-Object System.Drawing.Font("Segoe UI", 52, [System.Drawing.FontStyle]::Bold)
$g.DrawString("Contact Intelligence", $t1Font, $whiteBrush,
  [System.Drawing.RectangleF]::new(0, 86, $W, 76), $centerFmt)

# Title line 2 — cyan
$t2Font = New-Object System.Drawing.Font("Segoe UI", 52, [System.Drawing.FontStyle]::Bold)
$g.DrawString("& Strategy", $t2Font, $cyanBrush,
  [System.Drawing.RectangleF]::new(0, 162, $W, 76), $centerFmt)

# Subtitle
$subFont = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Regular)
$g.DrawString(
  "From account lookup to drafted outreach - in one skill. Powered by live Salesforce data.",
  $subFont, $subBrush,
  [System.Drawing.RectangleF]::new(120, 250, $W-240, 40), $centerFmt)

# Command pill
$pW = 400; $pH = 42; $pX = ($W-$pW)/2; $pY = 304
$pillFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45,0,179,255))
$pillPen  = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(190,0,200,255), 1.8)
RoundedRect $g $pillFill $pillPen $pX $pY $pW $pH 8
$codeFont = New-Object System.Drawing.Font("Consolas", 14.5, [System.Drawing.FontStyle]::Regular)
$g.DrawString("/contact-intel [Account Name]", $codeFont, $cyanBrush,
  [System.Drawing.RectangleF]::new($pX,$pY,$pW,$pH), $centerFmt)

# Save
$out = "C:\Users\felipe.benavides\claude-projects\contact-intel-portal\assets\canvas-banner.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "Saved: $out"
