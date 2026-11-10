param(
  [string]$TargetRoot = 'C:\xampp\htdocs\mobileapp_backend\backend'
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Join-Path $PSScriptRoot 'backend'

# Copy code and SQL; preserve the target's real config and uploaded receipts.
foreach ($directory in @('api', 'src', 'sql')) {
  $sourceDirectory = Join-Path $sourceRoot $directory
  foreach ($file in Get-ChildItem -LiteralPath $sourceDirectory -File -Recurse -Force) {
    $relative = $file.FullName.Substring($sourceRoot.Length + 1)
    $destination = Join-Path $TargetRoot $relative
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
  }
}
foreach ($relative in @('.htaccess', 'config\.htaccess', 'config\app-config.example.php', 'storage\.htaccess', 'storage\receipts\.gitkeep')) {
  $destination = Join-Path $TargetRoot $relative
  New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $sourceRoot $relative) -Destination $destination -Force
}
Write-Host "Backend code updated: $TargetRoot"
