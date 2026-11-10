# My Wallet AI — Flutter

แอปการเงิน 8 Process: บัญชีผู้ใช้, Dashboard, สแกนบิล AI, รายรับ, รายจ่าย, Subscription, งบประมาณ และผ่อนสินค้า

จากโฟลเดอร์ `mobile`:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/mobileapp_backend/backend/api/index.php
flutter test
flutter analyze
```

Android debug/release มีสิทธิ์อินเทอร์เน็ตและอนุญาต HTTP สำหรับ XAMPP ค่าเริ่มต้นเหมาะกับ Android emulator ถ้าใช้โทรศัพท์จริงให้เปลี่ยน `API_BASE_URL` เป็น IP ของคอมพิวเตอร์

ดู [คู่มือติดตั้งและ build](../README.md), [API](../docs/API.md) และ [ผ่อนสินค้า](../docs/INSTALLMENTS.md)
