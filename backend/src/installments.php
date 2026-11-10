<?php
declare(strict_types=1);
require_once __DIR__.'/installment_schedule.php';

function installment_money($raw, bool $zero=false): int {
  return money_cents_field($raw,$zero);
}

function installment_payment_rows(int $uid, ?int $planId=null): array {
  $args=[$uid]; $where='p.user_id=?';
  if ($planId!==null) { $where.=' AND p.id=?'; $args[]=$planId; }
  return sql('SELECT i.id,i.plan_id,i.installment_number,i.due_date,i.amount,i.transaction_id,i.paid_date,(i.proof_data IS NOT NULL) AS has_proof FROM installment_payments i JOIN installment_plans p ON p.id=i.plan_id WHERE '.$where.' ORDER BY i.due_date,i.installment_number',$args)->fetchAll();
}

function installment_transaction_locked(int $tx): bool {
  return (bool)sql('SELECT id FROM installment_plans WHERE down_transaction_id=? LIMIT 1',[$tx])->fetchColumn();
}

function handle_installments(int $uid,string $route): never {
  if ($route==='installments/proof') {
    method('GET'); $id=id_param();
    $row=sql('SELECT i.proof_data,i.proof_mime FROM installment_payments i JOIN installment_plans p ON p.id=i.plan_id WHERE i.id=? AND p.user_id=?',[$id,$uid])->fetch();
    if (!$row || $row['proof_data']===null) fail('ไม่พบหลักฐาน',404);
    header('Content-Type: '.$row['proof_mime']); header('Cache-Control: private, no-store'); header('X-Content-Type-Options: nosniff');
    echo $row['proof_data']; exit;
  }
  if ($route==='installments/pay' || $route==='installments/unpay') {
    method('POST');
    $multipart=str_starts_with($_SERVER['CONTENT_TYPE']??'','multipart/form-data');
    $b=$multipart ? $_POST : body();
    $id=filter_var($b['payment_id']??null,FILTER_VALIDATE_INT);
    if (!$id || $id<1) fail('งวดไม่ถูกต้อง');
    $paidDate=$route==='installments/pay' ? date_field($b['paid_date']??'') : null;
    if ($paidDate!==null && ($paidDate>date('Y-m-d') || $paidDate<'1900-01-01')) fail('วันที่ชำระต้องไม่เป็นวันในอนาคต');
    $proof=null; $mime=null;
    if ($route==='installments/pay' && isset($_FILES['proof']) && $_FILES['proof']['error']!==UPLOAD_ERR_NO_FILE) {
      $f=$_FILES['proof'];
      if ($f['error']===UPLOAD_ERR_INI_SIZE || $f['error']===UPLOAD_ERR_FORM_SIZE || $f['size']>2*1024*1024) fail('หลักฐานต้องไม่เกิน 2 MB',413);
      if ($f['error']!==UPLOAD_ERR_OK || !is_uploaded_file($f['tmp_name'])) fail('อัปโหลดหลักฐานไม่สำเร็จ');
      $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
      if (!in_array($mime,['image/png','image/jpeg','image/webp'],true) || !getimagesize($f['tmp_name'])) fail('หลักฐานต้องเป็นรูป JPEG, PNG หรือ WebP');
      $proof=file_get_contents($f['tmp_name']);
    }
    $pdo=db(); $pdo->beginTransaction();
    try {
      $row=sql('SELECT i.*,p.user_id,p.product_name,p.category_id FROM installment_payments i JOIN installment_plans p ON p.id=i.plan_id WHERE i.id=? AND p.user_id=? FOR UPDATE',[$id,$uid])->fetch();
      if (!$row) fail('ไม่พบงวดผ่อน',404);
      if ($route==='installments/unpay') {
        if ($row['transaction_id']===null) fail('งวดนี้ยังไม่ชำระ',409);
        sql('UPDATE installment_payments SET transaction_id=NULL,paid_date=NULL,proof_data=NULL,proof_mime=NULL WHERE id=?',[$id]);
        sql('DELETE FROM transactions WHERE id=? AND user_id=?',[$row['transaction_id'],$uid]);
        $pdo->commit(); reply(['message'=>'ยกเลิกการบันทึกชำระและนำรายจ่ายออกแล้ว']);
      }
      if ($row['transaction_id']!==null) fail('งวดนี้บันทึกชำระแล้ว',409);
      $title=$row['product_name'].' · งวด '.$row['installment_number'];
      sql("INSERT INTO transactions(user_id,category_id,type,title,amount,transaction_date,note,source) VALUES(?,?,'expense',?,?,?,'ผ่อนชำระสินค้า','installment')",[$uid,$row['category_id'],$title,$row['amount'],$paidDate]);
      $tx=(int)$pdo->lastInsertId();
      sql('UPDATE installment_payments SET transaction_id=?,paid_date=?,proof_data=?,proof_mime=? WHERE id=?',[$tx,$paidDate,$proof,$mime,$id]);
      $pdo->commit(); reply(['message'=>'บันทึกชำระและเพิ่มรายจ่ายแล้ว','transaction_id'=>$tx],201);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  if ($_SERVER['REQUEST_METHOD']==='GET') {
    $id=isset($_GET['id']) ? id_param() : null;
    $args=[$uid]; $where='p.user_id=?';
    if ($id!==null) { $where.=' AND p.id=?'; $args[]=$id; }
    $plans=sql('SELECT p.*,c.name AS category_name FROM installment_plans p LEFT JOIN categories c ON c.id=p.category_id WHERE '.$where.' ORDER BY p.id DESC',$args)->fetchAll();
    if ($id!==null && !$plans) fail('ไม่พบรายการผ่อน',404);
    $payments=installment_payment_rows($uid,$id); $grouped=[];
    foreach ($payments as $payment) {
      $payment['has_proof']=(bool)$payment['has_proof'];
      $payment['status']=$payment['transaction_id']!==null ? 'paid' : ($payment['due_date']<date('Y-m-d') ? 'overdue' : 'pending');
      $grouped[$payment['plan_id']][]=$payment;
    }
    $summary=['remaining'=>0,'paid'=>0,'due_this_month'=>0,'overdue'=>0,'active_count'=>0];
    foreach ($plans as &$plan) {
      $plan['payments']=$grouped[$plan['id']]??[]; $paid=0; $paidCount=0; $next=null;
      foreach ($plan['payments'] as $payment) {
        if ($payment['status']==='paid') { $paid+=(int)round((float)$payment['amount']*100); $paidCount++; }
        else {
          if ($next===null) $next=$payment;
          if (substr($payment['due_date'],0,7)===date('Y-m')) $summary['due_this_month']+=(int)round((float)$payment['amount']*100);
          if ($payment['status']==='overdue') $summary['overdue']+=(int)round((float)$payment['amount']*100);
        }
      }
      $remaining=(int)round((float)$plan['total_payable']*100)-$paid;
      $plan['paid_amount']=$paid/100; $plan['remaining_amount']=$remaining/100;
      $plan['paid_count']=$paidCount; $plan['status']=$next===null ? 'completed' : 'active'; $plan['next_payment']=$next;
      $summary['remaining']+=$remaining; $summary['paid']+=$paid;
      if ($next!==null) $summary['active_count']++;
    }
    unset($plan);
    foreach (['remaining','paid','due_this_month','overdue'] as $key) $summary[$key]/=100;
    reply(['items'=>$plans,'summary'=>$summary]);
  }
  if ($_SERVER['REQUEST_METHOD']==='POST') {
    $b=body(); $name=text_field($b['product_name']??null,'ชื่อสินค้า',100);
    $price=installment_money($b['price']??null); $down=installment_money($b['down_payment']??0,true);
    if ($down>=$price) fail('เงินดาวน์ต้องน้อยกว่าราคาสินค้า');
    $count=filter_var($b['installment_count']??null,FILTER_VALIDATE_INT);
    if (!$count || $count<1 || $count>360) fail('จำนวนงวดต้องเป็น 1–360');
    $first=date_field($b['first_due_date']??'');
    $contract=isset($b['monthly_amount']) ? installment_money($b['monthly_amount']) : null;
    try { $schedule=installment_schedule($price-$down,$count,$first,$contract); }
    catch (InvalidArgumentException $e) { fail($e->getMessage()); }
    $cat=category_check($uid,$b['category_id']??null,'expense');
    $note=trim((string)($b['note']??'')); if (mb_strlen($note)>1000) fail('หมายเหตุยาวเกินไป');
    $mode=$b['down_payment_mode']??'none';
    if (!in_array($mode,['none','record','existing'],true)) fail('วิธีบันทึกเงินดาวน์ไม่ถูกต้อง');
    if ($down===0 && $mode!=='none') fail('ไม่มีเงินดาวน์ให้บันทึก');
    $downDate=$mode==='record' ? date_field($b['down_payment_date']??'') : null;
    if ($downDate!==null && ($downDate>date('Y-m-d') || $downDate<'1900-01-01')) fail('วันที่จ่ายดาวน์ไม่ถูกต้อง');
    $existing=$mode==='existing' ? filter_var($b['down_transaction_id']??null,FILTER_VALIDATE_INT) : null;
    if ($mode==='existing' && (!$existing || $existing<1)) fail('เลือกรายจ่ายเงินดาวน์เดิม');
    $total=array_sum(array_column($schedule,'amount_cents'));
    $pdo=db(); $pdo->beginTransaction();
    try {
      $tx=null;
      if ($mode==='existing') {
        $row=sql("SELECT id,amount,source FROM transactions WHERE id=? AND user_id=? AND type='expense' FOR UPDATE",[$existing,$uid])->fetch();
        if (!$row || (int)round((float)$row['amount']*100)!==$down || !in_array($row['source'],['manual','ai'],true)) fail('รายจ่ายเดิมต้องเป็นเงินดาวน์ยอดเดียวกัน');
        if (installment_transaction_locked((int)$existing)) fail('รายจ่ายนี้เชื่อมกับรายการผ่อนแล้ว',409);
        $tx=$existing;
      } elseif ($mode==='record') {
        sql("INSERT INTO transactions(user_id,category_id,type,title,amount,transaction_date,note,source) VALUES(?,?,'expense',?,?,?,'เงินดาวน์สินค้า','installment')",[$uid,$cat,$name.' · เงินดาวน์',$down/100,$downDate]);
        $tx=(int)$pdo->lastInsertId();
      }
      sql('INSERT INTO installment_plans(user_id,category_id,product_name,price,down_payment,down_transaction_id,installment_count,first_due_date,total_payable,note) VALUES(?,?,?,?,?,?,?,?,?,?)',[$uid,$cat,$name,$price/100,$down/100,$tx,$count,$first,$total/100,$note]);
      $id=(int)$pdo->lastInsertId();
      foreach ($schedule as $payment) sql('INSERT INTO installment_payments(plan_id,installment_number,due_date,amount) VALUES(?,?,?,?)',[$id,$payment['installment_number'],$payment['due_date'],$payment['amount_cents']/100]);
      $pdo->commit(); reply(['id'=>$id,'message'=>'เพิ่มรายการผ่อนแล้ว'],201);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  if ($_SERVER['REQUEST_METHOD']==='DELETE') {
    $id=id_param(); $pdo=db(); $pdo->beginTransaction();
    try {
      $plan=sql('SELECT * FROM installment_plans WHERE id=? AND user_id=? FOR UPDATE',[$id,$uid])->fetch();
      if (!$plan) fail('ไม่พบรายการผ่อน',404);
      if ($plan['down_transaction_id']!==null || sql('SELECT id FROM installment_payments WHERE plan_id=? AND transaction_id IS NOT NULL LIMIT 1',[$id])->fetchColumn()) fail('รายการที่มีประวัติชำระแล้วไม่สามารถลบได้',409);
      sql('DELETE FROM installment_plans WHERE id=? AND user_id=?',[$id,$uid]);
      $pdo->commit(); reply(['message'=>'ลบรายการผ่อนแล้ว']);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  fail('Method ไม่รองรับ',405);
}
