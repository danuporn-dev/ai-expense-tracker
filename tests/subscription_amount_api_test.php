<?php
declare(strict_types=1);
require (getenv('BACKEND_ROOT') ?: 'C:/xampp/htdocs/mobileapp_backend/backend').'/src/common.php';
$base=getenv('TEST_API_URL') ?: 'http://localhost/mobileapp_backend/backend/api/index.php';
$users=[]; $tokens=[];
function regression_api(string $route,string $method='GET',array $data=[],array $query=[],int $user=0): array {
  global $base,$tokens;
  $curl=curl_init($base.'?'.http_build_query(['route'=>$route,...$query]));
  curl_setopt_array($curl,[CURLOPT_CUSTOMREQUEST=>$method,CURLOPT_RETURNTRANSFER=>true,CURLOPT_HTTPHEADER=>['Content-Type: application/json','Authorization: Bearer '.$tokens[$user]],CURLOPT_TIMEOUT=>15]);
  if ($method!=='GET') curl_setopt($curl,CURLOPT_POSTFIELDS,json_encode($data));
  $raw=curl_exec($curl);
  if ($raw===false) throw new RuntimeException(curl_error($curl));
  $status=curl_getinfo($curl,CURLINFO_HTTP_CODE); curl_close($curl);
  $response=json_decode($raw,true);
  if (!is_array($response)) throw new RuntimeException('Invalid API response');
  return [$status,$response];
}
function regression_check(bool $ok,string $label): void {
  if (!$ok) throw new RuntimeException('FAIL: '.$label);
  echo 'PASS: '.$label.PHP_EOL;
}
function subscription_create(array $data): int {
  [$status]=regression_api('subscriptions','POST',$data);
  regression_check($status===201,'subscription created');
  [$status,$list]=regression_api('subscriptions');
  foreach ($list['items'] as $row) if ($row['service_name']===$data['service_name']) return (int)$row['id'];
  throw new RuntimeException('Missing created subscription');
}
function subscription_event(int $id,string $month): array {
  [$status,$list]=regression_api('subscriptions','GET',[],['month'=>$month]);
  foreach ($list['events'] as $row) if ((int)$row['subscription_id']===$id) return $row;
  throw new RuntimeException('Missing event');
}
try {
  for ($i=0;$i<2;$i++) {
    sql('INSERT INTO users(name,email,password_hash) VALUES(?,?,?)',['Subscription amount regression','regression-'.bin2hex(random_bytes(12)).'@example.invalid','temporary-password']);
    $users[]=(int)db()->lastInsertId(); $tokens[]=bin2hex(random_bytes(32));
    sql('INSERT INTO auth_tokens(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 1 DAY))',[$users[$i],hash('sha256',$tokens[$i])]);
  }
  $monthly=['service_name'=>'Monthly test','amount'=>'179.00','start_date'=>'2026-10-01','billing_day'=>5,'cycle'=>'monthly','icon_key'=>'other'];
  $id=subscription_create($monthly);
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$id,'due_date'=>'2026-10-05']);
  regression_check($status===201,'monthly payment saved');
  $changed=[...$monthly,'billing_day'=>6,'amount'=>'199.00'];
  [$status]=regression_api('subscriptions','PUT',$changed,['id'=>$id]); regression_check($status===200,'paid billing day and amount updated');
  $event=subscription_event($id,'2026-10');
  regression_check($event['paid']===true && $event['due_date']==='2026-10-06' && $event['paid_due_date']==='2026-10-05' && (float)$event['amount']===179.0,'paid status and historical amount survive schedule edit');
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$id,'due_date'=>'2026-10-06']); regression_check($status===409,'edited billing day cannot duplicate month');
  regression_check((int)sql('SELECT COUNT(*) FROM subscription_payments WHERE subscription_id=?',[$id])->fetchColumn()===1,'duplicate creates no payment record');
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$id,'due_date'=>'2026-11-06']); regression_check($status===201,'next month still payable');
  [$status]=regression_api('subscriptions','PUT',$changed,['id'=>$id],1); regression_check($status===404,'cross-user schedule edit denied');
  [$status]=regression_api('subscriptions','PUT',$changed,['id'=>999999999]); regression_check($status===404,'nonexistent edit returns 404');

  // Concurrent requests must serialize on the subscription's parent row.
  $multi=curl_multi_init(); $handles=[];
  for ($i=0;$i<2;$i++) {
    $curl=curl_init($base.'?route=subscriptions/pay');
    curl_setopt_array($curl,[CURLOPT_POST=>true,CURLOPT_RETURNTRANSFER=>true,CURLOPT_HTTPHEADER=>['Content-Type: application/json','Authorization: Bearer '.$tokens[0]],CURLOPT_POSTFIELDS=>json_encode(['subscription_id'=>$id,'due_date'=>'2026-12-06']),CURLOPT_TIMEOUT=>15]);
    curl_multi_add_handle($multi,$curl); $handles[]=$curl;
  }
  do { $state=curl_multi_exec($multi,$running); if ($running) curl_multi_select($multi,1); } while ($running && $state===CURLM_OK);
  $statuses=[];
  foreach ($handles as $curl) { $statuses[]=curl_getinfo($curl,CURLINFO_HTTP_CODE); curl_multi_remove_handle($multi,$curl); curl_close($curl); }
  curl_multi_close($multi); sort($statuses);
  regression_check($statuses===[201,409],'concurrent payments create one expense');

  $yearly=['service_name'=>'Yearly test','amount'=>'1000.00','start_date'=>'2025-01-01','billing_day'=>31,'cycle'=>'yearly','icon_key'=>'other'];
  $yearId=subscription_create($yearly);
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$yearId,'due_date'=>'2026-01-31']); regression_check($status===201,'yearly payment saved');
  $newYearly=[...$yearly,'start_date'=>'2025-02-01','billing_day'=>5,'amount'=>'1200.00'];
  [$status]=regression_api('subscriptions','PUT',$newYearly,['id'=>$yearId]); regression_check($status===200,'yearly anniversary changed');
  $event=subscription_event($yearId,'2026-02');
  regression_check($event['paid']===true && $event['paid_due_date']==='2026-01-31' && (float)$event['amount']===1000.0,'yearly paid status follows the year');
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$yearId,'due_date'=>'2026-02-05']); regression_check($status===409,'changed anniversary cannot duplicate the year');
  [$status]=regression_api('subscriptions/pay','POST',['subscription_id'=>$yearId,'due_date'=>'2027-02-05']); regression_check($status===201,'next year still payable');

  $countsBefore=[(int)sql('SELECT COUNT(*) FROM transactions WHERE user_id=?',[$users[0]])->fetchColumn(),(int)sql('SELECT COUNT(*) FROM budgets WHERE user_id=?',[$users[0]])->fetchColumn(),(int)sql('SELECT COUNT(*) FROM subscriptions WHERE user_id=?',[$users[0]])->fetchColumn()];
  $badAmounts=[0.004,'0.004',1.234,'1.234',0,-1,true,[],null,'NaN','Infinity','1e3','10000000000','9999999999.999'];
  foreach ($badAmounts as $bad) {
    foreach (['transactions'=>['type'=>'expense','title'=>'Invalid money','transaction_date'=>'2026-10-13'],'budgets'=>['month'=>'2026-10'],'subscriptions'=>$monthly] as $route=>$fields) {
      [$status]=regression_api($route,'POST',[...$fields,'amount'=>$bad]);
      regression_check($status===400,$route.' rejects '.json_encode($bad));
    }
  }
  $countsAfter=[(int)sql('SELECT COUNT(*) FROM transactions WHERE user_id=?',[$users[0]])->fetchColumn(),(int)sql('SELECT COUNT(*) FROM budgets WHERE user_id=?',[$users[0]])->fetchColumn(),(int)sql('SELECT COUNT(*) FROM subscriptions WHERE user_id=?',[$users[0]])->fetchColumn()];
  regression_check($countsBefore===$countsAfter,'invalid amounts leave database unchanged');
  foreach (['0.01','1.20','9999999999.99'] as $amount) {
    [$status,$saved]=regression_api('transactions','POST',['type'=>'expense','title'=>'Valid money','amount'=>$amount,'transaction_date'=>'2026-10-13']);
    regression_check($status===201 && sql('SELECT amount FROM transactions WHERE id=?',[$saved['id']])->fetchColumn()===$amount,'valid amount retained exactly: '.$amount);
    [$status]=regression_api('budgets','POST',['month'=>'2026-10','amount'=>$amount]); regression_check($status===201,'budget accepts '.$amount);
    [$status]=regression_api('subscriptions','POST',[...$monthly,'amount'=>$amount]); regression_check($status===201,'subscription accepts '.$amount);
  }
  regression_check((int)sql('SELECT COUNT(*) FROM transactions WHERE user_id=? AND amount=0',[$users[0]])->fetchColumn()===0,'no zero-value transaction created');
  foreach (['config/app-config.example.php','storage/receipts/.gitkeep','src/common.php','sql/schema.sql'] as $resource) {
    $curl=curl_init(dirname($base,2).'/'.$resource); curl_setopt_array($curl,[CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>10]);
    curl_exec($curl); $status=curl_getinfo($curl,CURLINFO_HTTP_CODE); curl_close($curl);
    regression_check($status===403,'direct HTTP access denied: '.$resource);
  }
} finally {
  if (db()->inTransaction()) db()->rollBack();
  foreach ($users as $uid) sql('DELETE FROM users WHERE id=?',[$uid]);
}
