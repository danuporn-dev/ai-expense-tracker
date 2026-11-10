# ภาพการทำงาน My Wallet AI

ภาพแคป 53 ภาพจากแอป Flutter ที่รันบน Android emulator จริง ระหว่างวันที่ 9–11 พฤศจิกายน 2026 โดยใช้บัญชี **My Wallet Demo** และข้อมูลสาธิต ยอดเงินและอีเมลในภาพเป็นตัวอย่างสำหรับแสดงการทำงาน

คลิกภาพเพื่อเปิดขนาดเต็ม ดู [คู่มือติดตั้งและโค้ดของโปรเจกต์](../README.md)

| Process | เนื้อหา | จำนวนภาพ |
| --- | --- | --- |
| [1. บัญชีผู้ใช้](#process-1) | บัญชีผู้ใช้ | 3 |
| [2. Dashboard](#process-2) | Dashboard | 4 |
| [3. สแกนบิล AI](#process-3) | เลือกบิลและผลการเชื่อมต่อบริการภายนอก | 13 |
| [4. รายรับ](#process-4) | รายรับ | 5 |
| [5. รายจ่าย](#process-5) | รายจ่าย | 3 |
| [6. Subscription](#process-6) | Subscription | 7 |
| [7. งบประมาณ](#process-7) | งบประมาณ | 4 |
| [8. ผ่อนสินค้า](#process-8) | ผ่อนสินค้า | 14 |

<a id="process-1"></a>

## Process 1 — บัญชีผู้ใช้

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="01-auth-welcome.png" width="240" alt="เข้าสู่ระบบ — ยินดีต้อนรับ">](01-auth-welcome.png)<br>เข้าสู่ระบบ — ยินดีต้อนรับ | [<img src="01-auth-register.png" width="240" alt="สมัครสมาชิก">](01-auth-register.png)<br>สมัครสมาชิก |
| [<img src="01-auth-profile.png" width="240" alt="แก้ไขข้อมูลส่วนตัว">](01-auth-profile.png)<br>แก้ไขข้อมูลส่วนตัว | — |

<a id="process-2"></a>

## Process 2 — Dashboard

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="02-dashboard-month.png" width="240" alt="ภาพรวมรายเดือน">](02-dashboard-month.png)<br>ภาพรวมรายเดือน | [<img src="02-dashboard-day.png" width="240" alt="เปลี่ยนเป็นรายวัน">](02-dashboard-day.png)<br>เปลี่ยนเป็นรายวัน |
| [<img src="02-dashboard-year.png" width="240" alt="เปลี่ยนเป็นรายปี">](02-dashboard-year.png)<br>เปลี่ยนเป็นรายปี | [<img src="02-dashboard-analytics.png" width="240" alt="กราฟแนวโน้มรายรับ–รายจ่าย">](02-dashboard-analytics.png)<br>กราฟแนวโน้มรายรับ–รายจ่าย |

<a id="process-3"></a>

## Process 3 — สแกนบิล AI

วันที่ 11 พฤศจิกายน 2026 สแกนบิลใหม่สองใบผ่านผู้ให้บริการ AI จริงสำเร็จ: Tay Ho Oakland วันที่ 2019-02-19 ยอด 14.18 และ Bar Ristorante San Montano วันที่ 2018-08-28 ยอด 34.00 ใบแรกตรวจข้อมูล แก้วันที่รายการเป็น 11/11/2026 แล้วบันทึกเป็นรายจ่ายและเปิดรูปแนบได้ ใบที่สองแสดงผลอ่านและฟอร์มตรวจสอบ ยังไม่ได้กดบันทึก ภาพข้อผิดพลาดเดิมวันที่ 10 พฤศจิกายนเก็บไว้แสดงกรณีบริการเชื่อมต่อไม่ได้

ใช้ [บิลตัวอย่างจาก ExpressExpense.com](../docs/sample-receipts/README.md) ซึ่งเป็นบิล USD และ EUR แอปแสดงรูปแบบบาทโดยไม่ได้แปลงค่าเงิน ตัวเลขเหล่านี้ใช้สาธิตเท่านั้น

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="03-receipt-start.png" width="240" alt="เริ่มสแกนบิล">](03-receipt-start.png)<br>เริ่มสแกนบิล | [<img src="03-receipt-selected.png" width="240" alt="เลือกรูปบิลตัวอย่าง">](03-receipt-selected.png)<br>เลือกรูปบิลตัวอย่าง |
| [<img src="03-receipt-error.png" width="240" alt="ข้อความเมื่อเชื่อมต่อผู้ให้บริการ AI ไม่สำเร็จ (10 พ.ย.)">](03-receipt-error.png)<br>ข้อความเมื่อเชื่อมต่อผู้ให้บริการ AI ไม่สำเร็จ (10 พ.ย.) | [<img src="03-receipt-new-selected.png" width="240" alt="เลือกบิลใหม่ Tay Ho Oakland">](03-receipt-new-selected.png)<br>เลือกบิลใหม่ Tay Ho Oakland |
| [<img src="03-receipt-analyzing.png" width="240" alt="ระหว่างส่งบิลให้ AI อ่านข้อมูลจริง">](03-receipt-analyzing.png)<br>ระหว่างส่งบิลให้ AI อ่านข้อมูลจริง | [<img src="03-receipt-result.png" width="240" alt="AI อ่านร้าน วันที่ ยอดรวม 14.18 และรายการสินค้าได้">](03-receipt-result.png)<br>AI อ่านร้าน วันที่ ยอดรวม 14.18 และรายการสินค้าได้ |
| [<img src="03-receipt-confirm.png" width="240" alt="ตรวจข้อมูลที่ AI เติมให้ก่อนบันทึก">](03-receipt-confirm.png)<br>ตรวจข้อมูลที่ AI เติมให้ก่อนบันทึก | [<img src="03-receipt-confirm-edited.png" width="240" alt="แก้วันที่รายการเป็น 11/11/2026 เพื่อสาธิตรายจ่ายเดือนปัจจุบัน">](03-receipt-confirm-edited.png)<br>แก้วันที่รายการเป็น 11/11/2026 เพื่อสาธิตรายจ่ายเดือนปัจจุบัน |
| [<img src="03-receipt-saved.png" width="240" alt="บันทึกรายจ่ายจากบิลสำเร็จพร้อมรูปแนบ">](03-receipt-saved.png)<br>บันทึกรายจ่ายจากบิลสำเร็จพร้อมรูปแนบ | [<img src="03-receipt-saved-preview.png" width="240" alt="เปิดดูรูปบิลจากรายการรายจ่ายที่บันทึก">](03-receipt-saved-preview.png)<br>เปิดดูรูปบิลจากรายการรายจ่ายที่บันทึก |
| [<img src="03-receipt-second-selected.png" width="240" alt="เลือกบิลเพิ่มเติม Bar Ristorante San Montano">](03-receipt-second-selected.png)<br>เลือกบิลเพิ่มเติม Bar Ristorante San Montano | [<img src="03-receipt-second-result.png" width="240" alt="AI อ่านบิลใบที่สองได้ยอดรวม 34.00 และรายการสินค้า">](03-receipt-second-result.png)<br>AI อ่านบิลใบที่สองได้ยอดรวม 34.00 และรายการสินค้า |
| [<img src="03-receipt-second-confirm.png" width="240" alt="ตรวจฟอร์มจากบิลใบที่สอง พร้อมวันที่ 28/08/2018">](03-receipt-second-confirm.png)<br>ตรวจฟอร์มจากบิลใบที่สอง พร้อมวันที่ 28/08/2018 | — |

<a id="process-4"></a>

## Process 4 — รายรับ

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="04-income-list.png" width="240" alt="รายการรายรับ">](04-income-list.png)<br>รายการรายรับ | [<img src="04-income-add.png" width="240" alt="กรอกฟอร์มเพิ่มรายรับ">](04-income-add.png)<br>กรอกฟอร์มเพิ่มรายรับ |
| [<img src="04-income-saved.png" width="240" alt="รายรับหลังบันทึกสำเร็จ">](04-income-saved.png)<br>รายรับหลังบันทึกสำเร็จ | [<img src="04-income-edit.png" width="240" alt="เปิดฟอร์มแก้ไขรายการ">](04-income-edit.png)<br>เปิดฟอร์มแก้ไขรายการ |
| [<img src="04-income-delete-confirm.png" width="240" alt="ยืนยันก่อนลบรายการ">](04-income-delete-confirm.png)<br>ยืนยันก่อนลบรายการ | — |

<a id="process-5"></a>

## Process 5 — รายจ่าย

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="05-expense-list.png" width="240" alt="รายการรายจ่าย รวมรายการที่บันทึกและเชื่อมจาก Subscription">](05-expense-list.png)<br>รายการรายจ่าย รวมรายการที่บันทึกและเชื่อมจาก Subscription | [<img src="05-expense-add.png" width="240" alt="กรอกฟอร์มเพิ่มรายจ่าย">](05-expense-add.png)<br>กรอกฟอร์มเพิ่มรายจ่าย |
| [<img src="05-expense-edit.png" width="240" alt="เปิดฟอร์มแก้ไขรายจ่าย">](05-expense-edit.png)<br>เปิดฟอร์มแก้ไขรายจ่าย | — |

<a id="process-6"></a>

## Process 6 — Subscription

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="06-subscription-calendar.png" width="240" alt="ปฏิทินรอบชำระ">](06-subscription-calendar.png)<br>ปฏิทินรอบชำระ | [<img src="06-subscription-due.png" width="240" alt="รายการที่ครบกำหนด">](06-subscription-due.png)<br>รายการที่ครบกำหนด |
| [<img src="06-subscription-paid.png" width="240" alt="สถานะหลังบันทึกชำระ">](06-subscription-paid.png)<br>สถานะหลังบันทึกชำระ | [<img src="06-subscription-add.png" width="240" alt="กรอกบริการและรอบชำระ">](06-subscription-add.png)<br>กรอกบริการและรอบชำระ |
| [<img src="06-subscription-created.png" width="240" alt="บริการใหม่ในรายการ">](06-subscription-created.png)<br>บริการใหม่ในรายการ | [<img src="06-subscription-edit.png" width="240" alt="แก้ไขบริการ">](06-subscription-edit.png)<br>แก้ไขบริการ |
| [<img src="06-subscription-disable-confirm.png" width="240" alt="ยืนยันก่อนปิดการติดตาม">](06-subscription-disable-confirm.png)<br>ยืนยันก่อนปิดการติดตาม | — |

<a id="process-7"></a>

## Process 7 — งบประมาณ

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="07-budget-overview.png" width="240" alt="งบรวมและงบแยกหมวด">](07-budget-overview.png)<br>งบรวมและงบแยกหมวด | [<img src="07-budget-set.png" width="240" alt="กรอกวงเงินรายเดือน">](07-budget-set.png)<br>กรอกวงเงินรายเดือน |
| [<img src="07-budget-saved.png" width="240" alt="งบประมาณหลังบันทึก">](07-budget-saved.png)<br>งบประมาณหลังบันทึก | [<img src="07-budget-warning.png" width="240" alt="ความคืบหน้าและแจ้งเตือนเมื่อเกินงบ">](07-budget-warning.png)<br>ความคืบหน้าและแจ้งเตือนเมื่อเกินงบ |

<a id="process-8"></a>

## Process 8 — ผ่อนสินค้า

ฟอร์มผ่อน 0% และยอดตามสัญญาใช้ข้อมูลสาธิต การแนบไฟล์ใช้รูปบิลตัวอย่างเพื่อแสดงขั้นตอนอัปโหลดและเปิดดูไฟล์แนบ

| ขั้นตอน | ขั้นตอนถัดไป |
| --- | --- |
| [<img src="08-installment-active.png" width="240" alt="รายการที่กำลังผ่อน">](08-installment-active.png)<br>รายการที่กำลังผ่อน | [<img src="08-installment-add.png" width="240" alt="กรอกราคาสินค้า เงินดาวน์ และจำนวนงวด">](08-installment-add.png)<br>กรอกราคาสินค้า เงินดาวน์ และจำนวนงวด |
| [<img src="08-installment-preview.png" width="240" alt="ตรวจยอดผ่อน 0% ก่อนบันทึก">](08-installment-preview.png)<br>ตรวจยอดผ่อน 0% ก่อนบันทึก | [<img src="08-installment-contract.png" width="240" alt="คำนวณยอดตามสัญญารวมดอกเบี้ยหรือค่าธรรมเนียม">](08-installment-contract.png)<br>คำนวณยอดตามสัญญารวมดอกเบี้ยหรือค่าธรรมเนียม |
| [<img src="08-installment-created.png" width="240" alt="รายการผ่อนที่สร้างสำเร็จ">](08-installment-created.png)<br>รายการผ่อนที่สร้างสำเร็จ | [<img src="08-installment-detail.png" width="240" alt="รายละเอียดสินค้าและยอดคงเหลือ">](08-installment-detail.png)<br>รายละเอียดสินค้าและยอดคงเหลือ |
| [<img src="08-installment-schedule.png" width="240" alt="ตารางชำระรายเดือน">](08-installment-schedule.png)<br>ตารางชำระรายเดือน | [<img src="08-installment-payment.png" width="240" alt="ฟอร์มชำระงวด">](08-installment-payment.png)<br>ฟอร์มชำระงวด |
| [<img src="08-installment-payment-proof.png" width="240" alt="แนบไฟล์ตัวอย่างก่อนยืนยัน">](08-installment-payment-proof.png)<br>แนบไฟล์ตัวอย่างก่อนยืนยัน | [<img src="08-installment-paid.png" width="240" alt="ยอดคงเหลือหลังชำระและสร้างรายจ่าย">](08-installment-paid.png)<br>ยอดคงเหลือหลังชำระและสร้างรายจ่าย |
| [<img src="08-installment-proof-preview.png" width="240" alt="เปิดดูไฟล์แนบ">](08-installment-proof-preview.png)<br>เปิดดูไฟล์แนบ | [<img src="08-installment-undo-confirm.png" width="240" alt="ยืนยันยกเลิกการบันทึกที่ผิด">](08-installment-undo-confirm.png)<br>ยืนยันยกเลิกการบันทึกที่ผิด |
| [<img src="08-installment-undone.png" width="240" alt="งวดกลับเป็นรอชำระหลังยกเลิก">](08-installment-undone.png)<br>งวดกลับเป็นรอชำระหลังยกเลิก | [<img src="08-installment-history.png" width="240" alt="ประวัติสินค้าที่ผ่อนครบแล้ว">](08-installment-history.png)<br>ประวัติสินค้าที่ผ่อนครบแล้ว |
