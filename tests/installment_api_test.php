<?php
declare(strict_types=1);
require (getenv('BACKEND_ROOT') ?: 'C:/xampp/htdocs/mobileapp_backend/backend').'/src/common.php';
$base=getenv('TEST_API_URL') ?: 'http://localhost/mobileapp_backend/backend/api/index.php';
$users=[]; $tokens=[]; $suffix=bin2hex(random_bytes(8));
function installment_api(string $route,string $method='GET',array $data=[],int $user=0,array $query=[],bool $multipart=false): array {
  global $base,$tokens;
  $curl=curl_init($base.'?'.http_build_query(['route'=>$route,...$query]));
  $headers=isset($tokens[$user]) ? ['Authorization: Bearer '.$tokens[$user]] : [];
  if (!$multipart) $headers[]='Content-Type: application/json';
  curl_setopt_array($curl,[CURLOPT_CUSTOMREQUEST=>$method,CURLOPT_HTTPHEADER=>$headers,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>15]);
  if ($method!=='GET') curl_setopt($curl,CURLOPT_POSTFIELDS,$multipart ? $data : json_encode($data));
  $raw=curl_exec($curl);
  if ($raw===false) throw new RuntimeException(curl_error($curl));
  $status=curl_getinfo($curl,CURLINFO_HTTP_CODE); curl_close($curl);
  $body=$route==='installments/proof' && $status===200 ? $raw : json_decode($raw,true);
  if (!is_array($body) && !is_string($body)) throw new RuntimeException('Invalid response: '.$raw);
  return [$status,$body];
}
function expect_installment(bool $ok,string $label): void {
  if (!$ok) throw new RuntimeException('FAIL: '.$label);
  echo 'PASS: '.$label.PHP_EOL;
}
function get_plan(int $id): array {
  [$status,$data]=installment_api('installments','GET',[],0,['id'=>$id]);
  expect_installment($status===200,'plan loaded'); return $data['items'][0];
}
$image=tempnam(sys_get_temp_dir(),'installment_png_');
$invalid=tempnam(sys_get_temp_dir(),'installment_bad_');
$png=base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=');
file_put_contents($image,$png); file_put_contents($invalid,'not an image');
try {
  for ($i=0;$i<2;$i++) {
    sql('INSERT INTO users(name,email,password_hash) VALUES(?,?,?)',['Installment temporary test','installment-'.$suffix.'-'.$i.'@example.invalid','test-only']);
    $users[]=(int)db()->lastInsertId(); $tokens[]=bin2hex(random_bytes(32));
    sql('INSERT INTO auth_tokens(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 1 DAY))',[$users[$i],hash('sha256',$tokens[$i])]);
  }
  [$status]=installment_api('installments','GET',[],2);
  expect_installment($status===401,'anonymous denied');
  [$status,$cats]=installment_api('categories'); $cat=null;
  foreach ($cats['items'] as $c) if ($c['name']==='ช้อปปิ้ง') $cat=(int)$c['id'];
  $request=['product_name'=>'Test phone','price'=>'24000','down_payment'=>'4000','installment_count'=>10,'first_due_date'=>date('Y-m-d'),'category_id'=>$cat,'down_payment_mode'=>'record','down_payment_date'=>date('Y-m-d')];
  [$status,$created]=installment_api('installments','POST',$request);
  expect_installment($status===201,'plan and down payment created'); $id=$created['id']; $plan=get_plan($id);
  expect_installment(count($plan['payments'])===10 && (float)$plan['total_payable']===20000.0,'ten scheduled installments');
  expect_installment((float)$plan['remaining_amount']===20000.0 && $plan['status']==='active','initial outstanding balance');
  [$status,$txs]=installment_api('transactions','GET',[],0,['type'=>'expense','month'=>date('Y-m')]);
  expect_installment($txs['count']===1 && (float)$txs['total']===4000.0,'down payment expense recorded once');
  [$status]=installment_api('installments','GET',[],1,['id'=>$id]); expect_installment($status===404,'cross-user plan denied');
  $payment=$plan['payments'][0]; $pay=['payment_id'=>$payment['id'],'paid_date'=>date('Y-m-d')];
  [$status]=installment_api('installments/pay','POST',$pay,1); expect_installment($status===404,'cross-user pay denied');
  [$status]=installment_api('installments/pay','POST',[...$pay,'paid_date'=>date('Y-m-d',strtotime('+1 day'))]); expect_installment($status===400,'future paid date denied');
  [$status]=installment_api('installments/pay','POST',[...$pay,'proof'=>new CURLFile($invalid,'image/png','bad.png')],0,[],true); expect_installment($status===400,'invalid proof rejected before expense');
  [$status,$paid]=installment_api('installments/pay','POST',[...$pay,'proof'=>new CURLFile($image,'image/png','proof.png')],0,[],true);
  expect_installment($status===201,'payment with proof recorded');
  [$status]=installment_api('installments/pay','POST',$pay); expect_installment($status===409,'duplicate payment denied');
  [$status,$proof]=installment_api('installments/proof','GET',[],0,['id'=>$payment['id']]); expect_installment($status===200 && $proof===$png,'proof round trips');
  [$status]=installment_api('installments/proof','GET',[],1,['id'=>$payment['id']]); expect_installment($status===404,'cross-user proof denied');
  $plan=get_plan($id); expect_installment($plan['paid_count']===1 && (float)$plan['remaining_amount']===18000.0,'paid count and remaining balance');
  [$status,$txs]=installment_api('transactions','GET',[],0,['type'=>'expense','month'=>date('Y-m')]); expect_installment($txs['count']===2 && (float)$txs['total']===6000.0,'monthly expenses include down and installment once');
  [$status]=installment_api('transactions','DELETE',[],0,['id'=>$paid['transaction_id']]); expect_installment($status===409,'linked installment transaction protected');
  [$status]=installment_api('installments','DELETE',[],0,['id'=>$id]); expect_installment($status===409,'paid history protected from deletion');
  [$status]=installment_api('installments/unpay','POST',['payment_id'=>$payment['id']],1); expect_installment($status===404,'cross-user undo denied');
  [$status]=installment_api('installments/unpay','POST',['payment_id'=>$payment['id']]); expect_installment($status===200,'accidental payment undone');
  $plan=get_plan($id); expect_installment($plan['paid_count']===0 && (float)$plan['remaining_amount']===20000.0 && !$plan['payments'][0]['has_proof'],'undo restores plan and removes proof');
  [$status,$txs]=installment_api('transactions'); expect_installment($txs['count']===1 && (float)$txs['total']===4000.0,'undo removes only its expense');
  foreach ($plan['payments'] as $row) { [$status]=installment_api('installments/pay','POST',['payment_id'=>$row['id'],'paid_date'=>date('Y-m-d')]); expect_installment($status===201,'scheduled installment paid'); }
  $plan=get_plan($id); expect_installment($plan['status']==='completed' && (float)$plan['remaining_amount']===0.0 && $plan['next_payment']===null,'final payment completes plan');
  [$status,$summary]=installment_api('installments'); expect_installment($summary['summary']['active_count']===0 && (float)$summary['summary']['due_this_month']===0.0,'completed plan removed from outstanding summary');
  $rounding=[...$request,'product_name'=>'Satang test','price'=>'100','down_payment'=>'0','down_payment_mode'=>'none','installment_count'=>3,'first_due_date'=>'2028-01-31'];
  [$status,$created]=installment_api('installments','POST',$rounding); expect_installment($status===201,'rounding plan created'); $small=get_plan($created['id']);
  expect_installment(array_column($small['payments'],'due_date')===['2028-01-31','2028-02-29','2028-03-31'] && (float)$small['payments'][2]['amount']===33.34,'API preserves rounding and anchor date');
  [$status]=installment_api('installments','DELETE',[],0,['id'=>$created['id']]); expect_installment($status===200,'unpaid plan can be deleted');
  foreach ([['price'=>'0'],['down_payment'=>'24000'],['installment_count'=>0],['installment_count'=>361],['monthly_amount'=>'1'],['price'=>'1.234']] as $bad) {
    [$status]=installment_api('installments','POST',[...$request,...$bad]); expect_installment($status===400,'invalid financial input denied');
  }
  // Link a manual down payment, without creating another expense.
  [$status,$tx]=installment_api('transactions','POST',['type'=>'expense','title'=>'Existing down','amount'=>4000,'transaction_date'=>date('Y-m-d')]);
  expect_installment($status===201,'existing down transaction created');
  [$status]=installment_api('installments','POST',[...$request,'down_payment_mode'=>'existing','down_transaction_id'=>$tx['id']]); expect_installment($status===201,'existing down linked');
  [$status]=installment_api('installments','POST',[...$request,'down_payment_mode'=>'existing','down_transaction_id'=>$tx['id']]); expect_installment($status===409,'same down cannot link twice');
  [$status]=installment_api('transactions','DELETE',[],0,['id'=>$tx['id']]); expect_installment($status===409,'linked manual down protected');
  [$status,$txs]=installment_api('transactions'); expect_installment($txs['count']===12 && (float)$txs['total']===28000.0,'linking down creates no duplicate expense');
} finally {
  if (db()->inTransaction()) db()->rollBack();
  foreach ($users as $uid) sql('DELETE FROM users WHERE id=?',[$uid]);
  @unlink($image); @unlink($invalid);
}
