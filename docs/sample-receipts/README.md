# บิลตัวอย่างสำหรับสแกน AI

ดาวน์โหลดจาก [ExpressExpense Sample Receipt Dataset (SRD)](https://expressexpense.com/blog/free-receipt-images-ocr-machine-learning-dataset/) วันที่ 11 พฤศจิกายน 2026 ผู้เผยแพร่ระบุว่าใช้ได้ภายใต้ MIT License และขอให้ระบุ ExpressExpense.com เป็นแหล่งที่มา ดู [ข้อความใบอนุญาต](LICENSE-MIT.txt)

| ไฟล์ต้นฉบับ | บิล | จุดที่ใช้สาธิต |
| --- | --- | --- |
| [1078-receipt.jpg](1078-receipt.jpg) | Tay Ho Oakland | เลือกรูป วิเคราะห์ด้วย AI ตรวจผล และบันทึกรายจ่าย |
| [1197-receipt.jpg](1197-receipt.jpg) | Bar Ristorante San Montano | ทดลองอ่านบิลเพิ่มเติมจากภาพอีกใบ |

เก็บภาพ JPEG ต้นฉบับสองใบนี้โดยไม่แก้ไขภาพ ชุด ZIP ต้นทางชื่อ `large-receipt-image-dataset-SRD.zip` มี MD5 `c8eb0f2d286da5ab742e7a5b59f15147` ตรงกับค่าที่ผู้เผยแพร่ระบุ

บิลตัวอย่างเป็นบิลต่างประเทศ ใช้สาธิตการอ่านข้อมูลและตัวเลขเท่านั้น แอปแสดงจำนวนเงินด้วยรูปแบบบาทและไม่มีการแปลงอัตราแลกเปลี่ยน ข้อมูลในบัญชีที่ใช้แคปเป็นข้อมูลสาธิต
