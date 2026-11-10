$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$temporaryTarget = Join-Path ([IO.Path]::GetTempPath()) ('wallet-backend-package-' + [guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Path (Join-Path $temporaryTarget 'config'),(Join-Path $temporaryTarget 'storage\receipts') -Force | Out-Null
  Set-Content -LiteralPath (Join-Path $temporaryTarget 'config\app-config.php') -Value 'existing-config-sentinel'
  Set-Content -LiteralPath (Join-Path $temporaryTarget 'storage\receipts\existing.jpg') -Value 'existing-receipt-sentinel'
  & (Join-Path $projectRoot 'sync_backend.ps1') -TargetRoot $temporaryTarget
  foreach ($relative in @('.htaccess','api\index.php','src\.htaccess','src\common.php','sql\.htaccess','sql\schema.sql','sql\migrations\001_profile_avatar.sql','sql\migrations\002_installments.sql','config\.htaccess','storage\.htaccess','storage\receipts\.gitkeep')) {
    if (-not (Test-Path -LiteralPath (Join-Path $temporaryTarget $relative))) { throw "Missing package file: $relative" }
  }
  if ((Get-Content -LiteralPath (Join-Path $temporaryTarget 'config\app-config.php') -Raw).Trim() -ne 'existing-config-sentinel') { throw 'Config overwritten' }
  if ((Get-Content -LiteralPath (Join-Path $temporaryTarget 'storage\receipts\existing.jpg') -Raw).Trim() -ne 'existing-receipt-sentinel') { throw 'Receipt overwritten' }
  Write-Output 'PASS: complete Backend package preserves real config and uploaded receipts'
} finally {
  # Verify the exact disposable target is inside the OS temp directory.
  $resolvedTarget = [IO.Path]::GetFullPath($temporaryTarget)
  $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  if (-not $resolvedTarget.StartsWith($resolvedTempRoot,[StringComparison]::OrdinalIgnoreCase) -or
      -not (Split-Path $resolvedTarget -Leaf).StartsWith('wallet-backend-package-')) { throw 'Unexpected cleanup path' }
  if (Test-Path -LiteralPath $resolvedTarget) { Remove-Item -LiteralPath $resolvedTarget -Recurse -Force }
}
