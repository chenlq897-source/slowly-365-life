param([string]$OutputDirectory = (Split-Path -Parent $PSScriptRoot))
Add-Type -AssemblyName System.Drawing
foreach ($size in @(192, 512)) {
  $bmp = [System.Drawing.Bitmap]::new($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#71866F'))
  $cream = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#FAF8F3'))
  $sage = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#71866F'), [Math]::Max(5, $size * .04))
  $g.FillEllipse($cream, $size * .23, $size * .20, $size * .54, $size * .54)
  $g.DrawArc($sage, $size * .34, $size * .40, $size * .32, $size * .20, 200, 140)
  $eye = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#71866F'))
  $r = [Math]::Max(3, $size * .018)
  $g.FillEllipse($eye, $size * .42, $size * .42, $r, $r)
  $g.FillEllipse($eye, $size * .57, $size * .42, $r, $r)
  $bmp.Save((Join-Path $OutputDirectory "icon-$size.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $eye.Dispose(); $sage.Dispose(); $cream.Dispose(); $g.Dispose(); $bmp.Dispose()
}

