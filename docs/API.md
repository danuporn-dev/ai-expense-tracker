# Backend REST API

Base URL: `http://localhost/mobileapp_backend/backend/api/index.php?route=ROUTE`

Android emulator ใช้ `http://10.0.2.2/mobileapp_backend/backend/api/index.php` ตัวที่ Apache ใช้งานอยู่คือ `C:\xampp\htdocs\mobileapp_backend\backend`; แก้สำเนาในโปรเจกต์แล้วรัน `sync_backend.ps1` เพื่ออัปเดตตัวที่ใช้งานจริง

API ของชุดนี้ใช้ **query parameter `route=`** เพื่อให้ทำงานกับ Apache/XAMPP โดยไม่ต้องตั้ง rewrite rules

| Route | HTTP | หน้าที่ |
|---|---|---|
| `health` | GET | ตรวจการทำงาน ไม่ต้องล็อกอิน |
| `auth/register` | POST | สมัครสมาชิก + สร้างหมวดเริ่มต้น |
| `auth/login` | POST | คืน bearer token และ user |
| `auth/me` | GET | ตรวจสถานะและข้อมูลผู้ใช้ |
| `auth/logout` | POST | ยกเลิก token ปัจจุบัน |
| `auth/profile` | POST multipart | แก้ชื่อ รหัสผ่าน และรูปโปรไฟล์ |
| `categories` | GET, POST | ดู/สร้างหมวดหมู่ |
| `transactions` | GET, POST, PUT, DELETE | ดู/เพิ่ม/แก้ไข/ลบรายรับรายจ่าย |
| `dashboard` | GET | สรุปภาพรวมและชุดกราฟ |
| `budgets` | GET, POST, DELETE | ดู/บันทึกแบบ upsert/ลบงบประมาณ |
| `subscriptions` | GET, POST, PUT, DELETE | รายการบริการและปฏิทินรอบชำระ |
| `subscriptions/pay` | POST | ชำระรอบที่กำหนด + เพิ่มรายจ่ายหนึ่งครั้ง |
| `installments` | GET, POST, DELETE | สรุปยอดผ่อน / สร้างตารางงวด / ลบรายการที่ยังไม่มีประวัติชำระ |
| `installments/pay` | POST JSON หรือ multipart | บันทึกชำระงวดและสร้างรายจ่าย พร้อมหลักฐานรูปภาพถ้ามี |
| `installments/unpay` | POST | ยกเลิกการบันทึกงวดและนำรายจ่ายของงวดนั้นออก |
| `installments/proof` | GET | อ่านหลักฐานชำระเฉพาะบัญชีเจ้าของรายการ |
| `ai/scan` | POST multipart | รูป image -> ข้อมูล JSON จาก AI |
| `receipts/image` | GET | โหลดภาพบิลผ่านการตรวจ user token |

หลังล็อกอิน ให้ส่ง Header `Authorization: Bearer <TOKEN>` ในทุก endpoint ยกเว้น `health`, `auth/register`, `auth/login`

`GET transactions` คืน `items` (ล่าสุดไม่เกิน 300 รายการ), `total` (ผลรวมทุกรายการที่ตรงตัวกรอง) และ `count` (จำนวนรายการทั้งหมดที่ตรงตัวกรอง) โดยทั้งสามค่าใช้ตัวกรอง `type`, `month`, `q` และบัญชีผู้ใช้เดียวกัน ทดสอบกรณีเกิน 300 รายการด้วย `C:\xampp\php\php.exe tests/transaction_totals_test.php`

## ตัวอย่าง Request

Register:

การตั้งค่าทดลองในเครื่องปัจจุบันเก็บรหัสผ่านของบัญชีใหม่เป็นข้อความธรรมดาในคอลัมน์ `users.password_hash` บัญชีเก่าที่มี hash ยังเข้าสู่ระบบได้และจะไม่ถูกแปลงรหัสผ่าน การตั้งค่านี้ไม่เหมาะสำหรับใช้งานจริง

```json
{"name":"Student","email":"student@example.com","password":"example1234"}
```

Profile update: `POST ?route=auth/profile` พร้อม Bearer token และ `multipart/form-data`:

- `name`: ชื่อที่ต้องการใช้ ความยาว 1–100 ตัวอักษร
- `avatar`: รูป JPEG, PNG หรือ WebP ไม่เกิน 2 MB (ไม่บังคับ)
- `password`: รหัสผ่านใหม่ 8–128 bytes (เว้นว่างเพื่อคงรหัสผ่านเดิม)
- `current_password`: รหัสผ่านปัจจุบัน ต้องส่งเมื่อเปลี่ยนรหัสผ่าน

คืนค่า `user` ซึ่งมี `id`, `name`, `email`, `avatar_mime` และ `avatar_base64` โดยไม่ส่งรหัสผ่านกลับ รูปถูกจัดเก็บในฐานข้อมูลของผู้ใช้ และคำตอบจาก `auth/login`, `auth/register`, `auth/me` มีข้อมูลรูปเช่นเดียวกัน ก่อนใช้กับฐานข้อมูลเดิมให้รัน [migration รูปโปรไฟล์](../backend/sql/migrations/001_profile_avatar.sql)

ทดสอบกับ XAMPP ในเครื่องด้วย `C:\xampp\php\php.exe tests/profile_api_test.php` สคริปต์สร้างบัญชีทดสอบชั่วคราวและลบหลังทดสอบ รองรับ `BACKEND_ROOT` และ `TEST_API_URL` หากใช้พาธอื่น

Add income:

```http
POST ?route=transactions
Authorization: Bearer TOKEN
Content-Type: application/json
```

```json
{"type":"income","title":"งานฟรีแลนซ์","amount":1500,"transaction_date":"2026-10-12","category_id":null,"note":"ออกแบบโลโก้"}
```

Add budget:

```json
{"month":"2026-10","category_id":null,"amount":5000}
```

Add Subscription:

```json
{"service_name":"YouTube Premium","icon_key":"youtube","amount":179,"start_date":"2026-10-16","billing_day":16,"cycle":"monthly"}
```

Mark paid:

```json
{"subscription_id":1,"due_date":"2026-10-16"}
```

Subscription รายเดือนบันทึกจ่ายได้ครั้งเดียวต่อเดือน และรายปีครั้งเดียวต่อปี โดยตรวจภายใต้ row lock ของบริการ เปลี่ยนวันตัดรอบ ยอด หรือเดือนเริ่มต้นแล้วสถานะชำระของรอบที่จ่ายไปยังคงอยู่ ไม่แก้ยอดหรือวันที่ในประวัติเดิม `GET subscriptions` คืน `paid`, `paid_due_date`, `paid_date` และใช้ยอดที่ชำระจริงสำหรับ event ที่จ่ายแล้ว หากจ่ายรอบเดิมซ้ำคืน HTTP 409; แก้บริการที่ไม่พบหรือไม่ใช่เจ้าของคืน 404

จำนวนเงินใน transactions, budgets และ subscriptions ต้องเป็นตัวเลขบวก 0.01–9,999,999,999.99 บาท ทศนิยมไม่เกิน 2 ตำแหน่ง ส่งเป็น JSON number หรือ string ได้ ค่าอย่าง `0.004`, `1.234`, `0`, ค่าติดลบ หรือเกินเพดานคืน HTTP 400 และไม่มีรายการใหม่ เงินดาวน์ผ่อนสินค้าใช้กติกาเดียวกันแต่เป็น 0 ได้

Scan receipt:

```text
POST ?route=ai/scan
Content-Type: multipart/form-data
file parameter name: image (jpg/png/webp, <= 8MB)
response: {"receipt_id": 1, "data": {"merchant":"...", "date":"YYYY-MM-DD", "total":100.00, ...}}
```

หลังผู้ใช้ตรวจบิลแล้วส่ง `POST transactions` โดยใส่ `receipt_id` เพื่อยืนยันการบันทึก

## Query parameters

- `GET transactions`: `type=income|expense`, `month=YYYY-MM`, `q=keyword`, ตอบกลับสูงสุด 300 รายการสำหรับ MVP
- `PUT/DELETE transactions`: `id=ID`
- `GET dashboard`: `period=day|month|year`, `date=YYYY-MM-DD`
- `GET budgets`, `GET subscriptions`: `month=YYYY-MM`
- `PUT/DELETE subscriptions`, `DELETE budgets`: `id=ID`
- `GET receipts/image`: `id=receipt_id`

## API Security

- prepared statements (`PDO`) + ทุก resource ผูกกับ user ที่ได้จาก token
- secret สำหรับ AI อยู่ฝั่ง PHP, token เก็บเป็น SHA-256 hash ใน DB
- การอัปโหลดบิลจำกัด MIME และขนาด / เก็บใต้ `storage` ที่ปิดไม่ให้เปิดผ่าน Apache
- ระดับ production ต้องเพิ่ม HTTPS, password reset, email verification, rate limiting, การจัดการ expired token และ CORS allowlist สำหรับโดเมนจริง
