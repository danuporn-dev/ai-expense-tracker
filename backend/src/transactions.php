<?php
declare(strict_types=1);
function handle_categories(int $uid): never {
  if ($_SERVER['REQUEST_METHOD']==='GET') {
    // Existing/imported accounts may be missing the standard categories.
    $defaults=[['expense','อาหาร','food'],['expense','เดินทาง','transport'],['expense','ช้อปปิ้ง','shopping'],['expense','ที่พัก','home'],['expense','บิลและบริการ','bill'],['expense','สมัครสมาชิก','subscription'],['expense','อื่น ๆ','other'],['income','เงินเดือน','salary'],['income','รายได้เสริม','work'],['income','ของขวัญ','gift'],['income','อื่น ๆ','other']];
    $values=[]; $params=[];
    foreach ($defaults as [$type,$name,$icon]) {
      $values[]='(?,?,?,?)'; array_push($params,$uid,$type,$name,$icon);
    }
    sql('INSERT IGNORE INTO categories(user_id,type,name,icon_key) VALUES '.implode(',',$values),$params);
    reply(['items'=>sql('SELECT id,type,name,icon_key FROM categories WHERE user_id=? ORDER BY type,name',[$uid])->fetchAll()]);
  }
  if ($_SERVER['REQUEST_METHOD']==='POST') {
    $b=body(); $type=(string)($b['type']??''); if (!in_array($type,['income','expense'],true)) fail('ประเภทไม่ถูกต้อง');
    $name=text_field($b['name']??null,'ชื่อหมวดหมู่',80);
    try { sql('INSERT INTO categories(user_id,type,name,icon_key) VALUES(?,?,?,?)',[$uid,$type,$name,'other']); } catch(PDOException $e) { if($e->getCode()==='23000') fail('หมวดหมู่นี้มีอยู่แล้ว',409); throw $e; }
    reply(['message'=>'สร้างหมวดหมู่สำเร็จ'],201);
  }
  fail('Method ไม่รองรับ',405);
}
function handle_transactions(int $uid): never {
  $method=$_SERVER['REQUEST_METHOD'];
  if ($method==='GET') {
    $where=['t.user_id=?']; $args=[$uid];
    if (isset($_GET['type'])) { if (!in_array($_GET['type'],['income','expense'],true)) fail('ประเภทไม่ถูกต้อง'); $where[]='t.type=?'; $args[]=$_GET['type']; }
    if (isset($_GET['month'])) { [$from,$to]=starts(month_field($_GET['month'])); $where[]='t.transaction_date>=? AND t.transaction_date<?'; array_push($args,$from,$to); }
    if (isset($_GET['q']) && trim($_GET['q'])!=='') { $where[]='t.title LIKE ?'; $args[]='%'.substr(trim($_GET['q']),0,80).'%'; }
    $rows=sql('SELECT t.*,c.name AS category_name,r.id AS receipt_id,(p.id IS NOT NULL) AS installment_linked,COALESCE(i.plan_id,p.id) AS installment_plan_id FROM transactions t LEFT JOIN categories c ON c.id=t.category_id LEFT JOIN receipts r ON r.transaction_id=t.id LEFT JOIN installment_plans p ON p.down_transaction_id=t.id LEFT JOIN installment_payments i ON i.transaction_id=t.id WHERE '.implode(' AND ',$where).' ORDER BY t.transaction_date DESC,t.id DESC LIMIT 300',$args)->fetchAll();
    $summary=sql('SELECT COUNT(*) AS count,COALESCE(SUM(t.amount),0) AS total FROM transactions t WHERE '.implode(' AND ',$where),$args)->fetch();
    reply(['items'=>$rows,'total'=>(float)$summary['total'],'count'=>(int)$summary['count']]);
  }
  if ($method==='POST' || $method==='PUT') {
    $b=body(); $type=(string)($b['type']??''); if (!in_array($type,['income','expense'],true)) fail('ประเภทไม่ถูกต้อง');
    $title=text_field($b['title']??null,'ชื่อรายการ'); $amount=amount_field($b['amount']??null);
    $date=date_field($b['transaction_date']??''); $cat=category_check($uid,$b['category_id']??null,$type);
    $note=trim((string)($b['note']??'')); if (mb_strlen($note)>1000) fail('หมายเหตุยาวเกินไป');
    if ($method==='PUT') {
      $id=id_param();
      $pdo=db(); $pdo->beginTransaction();
      try {
      $exists=sql('SELECT id,source FROM transactions WHERE id=? AND user_id=? FOR UPDATE',[$id,$uid])->fetch(); if (!$exists) fail('ไม่พบรายการ',404);
      // Subscription amounts are managed via their payment record; do not overwrite its financial transaction.
      if ($exists['source']==='subscription') fail('รายการชำระ Subscription ไม่สามารถแก้ไขโดยตรง',409);
      if ($exists['source']==='installment' || installment_transaction_locked($id)) fail('จัดการรายการชำระนี้ผ่านหน้าผ่อนสินค้า',409);
      sql('UPDATE transactions SET type=?,title=?,amount=?,transaction_date=?,category_id=?,note=? WHERE id=? AND user_id=?',[$type,$title,$amount,$date,$cat,$note,$id,$uid]);
      $pdo->commit();
      reply(['message'=>'แก้ไขแล้ว']);
      } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
    }
    $source='manual'; $rid=isset($b['receipt_id'])?scalar_id($b['receipt_id']):null;
    $pdo=db(); $pdo->beginTransaction();
    try {
      if ($rid) {
        if ($type!=='expense') fail('บิลใช้ได้กับรายจ่ายเท่านั้น');
        $receipt=sql('SELECT id,transaction_id FROM receipts WHERE id=? AND user_id=? FOR UPDATE',[$rid,$uid])->fetch();
        if (!$receipt || $receipt['transaction_id']!==null) fail('บิลนี้ถูกบันทึกไปแล้ว',409);
        $source='ai';
      }
      sql('INSERT INTO transactions(user_id,type,title,amount,transaction_date,category_id,note,source) VALUES(?,?,?,?,?,?,?,?)',[$uid,$type,$title,$amount,$date,$cat,$note,$source]);
      $new=(int)$pdo->lastInsertId();
      if ($rid) sql('UPDATE receipts SET transaction_id=? WHERE id=? AND user_id=?',[$new,$rid,$uid]);
      $pdo->commit();
      reply(['id'=>$new,'message'=>'บันทึกแล้ว'],201);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  if ($method==='DELETE') {
    $id=id_param(); $pdo=db(); $pdo->beginTransaction();
    try {
    $row=sql('SELECT source FROM transactions WHERE id=? AND user_id=? FOR UPDATE',[$id,$uid])->fetch(); if (!$row) fail('ไม่พบรายการ',404);
    if ($row['source']==='subscription') fail('รายการชำระ Subscription ไม่สามารถลบโดยตรง',409);
    if ($row['source']==='installment' || installment_transaction_locked($id)) fail('จัดการรายการชำระนี้ผ่านหน้าผ่อนสินค้า',409);
    sql('DELETE FROM transactions WHERE id=? AND user_id=?',[$id,$uid]); $pdo->commit(); reply(['message'=>'ลบแล้ว']);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  fail('Method ไม่รองรับ',405);
}
