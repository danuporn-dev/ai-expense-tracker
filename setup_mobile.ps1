$ErrorActionPreference = 'Stop'
$mobile = Join-Path $PSScriptRoot 'mobile'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'ไม่พบคำสั่ง flutter: ติดตั้ง Flutter SDK แล้วเพิ่ม PATH ก่อน' }
Push-Location $mobile
try {
  flutter create --platforms=android,web --project-name my_wallet_ai .
  if ($LASTEXITCODE -ne 0) { throw 'flutter create ไม่สำเร็จ' }
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get ไม่สำเร็จ' }
  $manifest = Join-Path $mobile 'android\app\src\main\AndroidManifest.xml'
  if (Test-Path $manifest) {
    $xml = Get-Content $manifest -Raw
    if ($xml -notmatch 'android.permission.INTERNET') {
      $xml = $xml.Replace('<application', '<uses-permission android:name="android.permission.INTERNET" />' + "`n    " + '<application')
    }
    if ($xml -notmatch 'usesCleartextTraffic') {
      $xml = $xml.Replace('<application', '<application android:usesCleartextTraffic="true"')
    }
    Set-Content -Path $manifest -Value $xml -Encoding UTF8
  }
  Write-Host 'Flutter พร้อมแล้ว! ใช้ flutter run พร้อม --dart-define=API_BASE_URL=...' -ForegroundColor Green
} finally { Pop-Location }
