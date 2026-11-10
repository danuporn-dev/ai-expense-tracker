<?php
declare(strict_types=1);
function due_for_month(array $sub, string $month): ?string {
  $start=date_field($sub['start_date']);
  $year=(int)substr($month,0,4); $mon=(int)substr($month,5,2);
  if ($month<substr($start,0,7)) return null;
  if ($sub['cycle']==='yearly' && $mon!==(int)substr($start,5,2)) return null;
  $last=(int)(new DateTimeImmutable(sprintf('%04d-%02d-01',$year,$mon)))->format('t');
  $day=min((int)$sub['billing_day'],$last);
  $due=sprintf('%04d-%02d-%02d',$year,$mon,$day);
  return $due >= $start ? $due : null;
}
function subscription_period_bounds(array $sub,string $due): array {
  if ($sub['cycle']==='yearly') {
    $year=(int)substr($due,0,4);
    return [sprintf('%04d-01-01',$year),sprintf('%04d-01-01',$year+1)];
  }
  return starts(substr($due,0,7));
}
function handle_subscriptions(int $uid,string $route): never {
  $method=$_SERVER['REQUEST_METHOD'];
  if ($route==='subscriptions/pay') {
    method('POST'); $b=body(); $id=scalar_id($b['subscription_id']??null); $due=date_field($b['due_date']??'');
    $pdo=db(); $pdo->beginTransaction();
    try {
      $sub=sql('SELECT * FROM subscriptions WHERE id=? AND user_id=? AND active=1 FOR UPDATE',[$id,$uid])->fetch();
      if (!$sub || due_for_month($sub,substr($due,0,7))!==$due) fail('รอบชำระไม่ถูกต้อง',400);
      // Locking the parent serializes payments and schedule edits. A changed
      // billing day must not open another payment in the same month/year.
      [$from,$to]=subscription_period_bounds($sub,$due);
      if (sql('SELECT id FROM subscription_payments WHERE subscription_id=? AND due_date>=? AND due_date<? LIMIT 1',[$id,$from,$to])->fetch()) fail('รอบนี้บันทึกว่าจ่ายแล้ว',409);
      $cat=sql("SELECT id FROM categories WHERE user_id=? AND type='expense' AND name='สมัครสมาชิก' LIMIT 1",[$uid])->fetchColumn();
      sql("INSERT INTO transactions(user_id,category_id,type,title,amount,transaction_date,note,source) VALUES(?,?,'expense',?,?,?,'ชำระค่าบริการ Subscription','subscription')",[$uid,$cat?:null,$sub['service_name'],$sub['amount'],date('Y-m-d')]);
      $tx=(int)$pdo->lastInsertId();
      sql('INSERT INTO subscription_payments(user_id,subscription_id,due_date,transaction_id) VALUES(?,?,?,?)',[$uid,$id,$due,$tx]);
      $pdo->commit(); reply(['message'=>'บันทึกการชำระแล้ว','transaction_id'=>$tx],201);
    } catch(Throwable $e) { if($pdo->inTransaction())$pdo->rollBack(); throw $e; }
  }
  if ($method==='GET') {
    $month=month_field($_GET['month']??date('Y-m'));
    $subs=sql('SELECT * FROM subscriptions WHERE user_id=? AND active=1 ORDER BY service_name',[$uid])->fetchAll();
    $year=(int)substr($month,0,4);
    $payments=sql('SELECT p.subscription_id,p.due_date,t.amount AS paid_amount,t.transaction_date AS paid_date FROM subscription_payments p JOIN transactions t ON t.id=p.transaction_id WHERE p.user_id=? AND p.due_date>=? AND p.due_date<? ORDER BY p.due_date,p.id',[$uid,sprintf('%04d-01-01',$year),sprintf('%04d-01-01',$year+1)])->fetchAll();
    $paidMonths=[]; $paidYears=[];
    foreach($payments as $p) {
      $paidMonths[$p['subscription_id'].'_'.substr($p['due_date'],0,7)]??=$p;
      $paidYears[$p['subscription_id'].'_'.substr($p['due_date'],0,4)]??=$p;
    }
    $events=[];
    foreach ($subs as $sub) {
      $due=due_for_month($sub,$month);
      if (!$due) continue;
      $payment=$sub['cycle']==='yearly' ? ($paidYears[$sub['id'].'_'.substr($month,0,4)]??null) : ($paidMonths[$sub['id'].'_'.$month]??null);
      $events[]=['subscription_id'=>$sub['id'],'service_name'=>$sub['service_name'],'icon_key'=>$sub['icon_key'],'amount'=>$payment['paid_amount']??$sub['amount'],'due_date'=>$due,'paid'=>$payment!==null,'paid_due_date'=>$payment['due_date']??null,'paid_date'=>$payment['paid_date']??null];
    }
    reply(['items'=>$subs,'events'=>$events,'month'=>$month]);
  }
  if ($method==='POST' || $method==='PUT') {
    $b=body(); $name=text_field($b['service_name']??null,'ชื่อบริการ',100); $amount=amount_field($b['amount']??null);
    $start=date_field($b['start_date']??''); $billingDay=(int)($b['billing_day']??0);
    if ($billingDay<1 || $billingDay>31) fail('วันตัดรอบต้องอยู่ระหว่าง 1–31');
    $cycle=(string)($b['cycle']??'monthly'); if (!in_array($cycle,['monthly','yearly'],true)) fail('รอบชำระไม่ถูกต้อง');
    $icon=(string)($b['icon_key']??'other'); if(!in_array($icon,['youtube','netflix','spotify','apple','google','other'],true))$icon='other';
    if ($method==='POST') {
      sql('INSERT INTO subscriptions(user_id,service_name,amount,start_date,billing_day,cycle,icon_key) VALUES(?,?,?,?,?,?,?)',[$uid,$name,$amount,$start,$billingDay,$cycle,$icon]);
      reply(['message'=>'เพิ่ม Subscription แล้ว'],201);
    }
    $id=id_param();
    $pdo=db(); $pdo->beginTransaction();
    try {
      if (!sql('SELECT id FROM subscriptions WHERE id=? AND user_id=? AND active=1 FOR UPDATE',[$id,$uid])->fetch()) fail('ไม่พบ Subscription',404);
      sql('UPDATE subscriptions SET service_name=?,amount=?,start_date=?,billing_day=?,cycle=?,icon_key=? WHERE id=? AND user_id=? AND active=1',[$name,$amount,$start,$billingDay,$cycle,$icon,$id,$uid]);
      $pdo->commit(); reply(['message'=>'แก้ไข Subscription แล้ว']);
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
  }
  if ($method==='DELETE') { $id=id_param(); sql('UPDATE subscriptions SET active=0 WHERE id=? AND user_id=?',[$id,$uid]); reply(['message'=>'ปิด Subscription แล้ว (ประวัติยังอยู่)']); }
  fail('Method ไม่รองรับ',405);
}
