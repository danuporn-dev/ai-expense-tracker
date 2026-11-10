<?php
// Local integration test; all generated data is removed in finally.
require (getenv('BACKEND_ROOT') ?: 'C:/xampp/htdocs/mobileapp_backend/backend').'/src/common.php';
$base=getenv('TEST_API_URL') ?: 'http://localhost/mobileapp_backend/backend/api/index.php';
$email='totals-'.bin2hex(random_bytes(10)).'@example.invalid';
$token=bin2hex(random_bytes(32));
$uid=null;
function expect_total(bool $condition,string $label): void {
  if (!$condition) throw new RuntimeException('FAIL: '.$label);
  echo 'PASS: '.$label.PHP_EOL;
}
function transactions_query(array $query): array {
  global $base,$token;
  $context=stream_context_create(['http'=>['header'=>'Authorization: Bearer '.$token,'ignore_errors'=>true,'timeout'=>10]]);
  $result=file_get_contents($base.'?'.http_build_query(['route'=>'transactions',...$query]),false,$context);
  $body=json_decode((string)$result,true);
  if (!is_array($body) || !isset($body['total'],$body['count'],$body['items'])) throw new RuntimeException('Invalid totals response');
  return $body;
}
try {
  sql('INSERT INTO users(name,email,password_hash) VALUES(?,?,?)',['Temporary totals test',$email,'temporary-password']);
  $uid=(int)db()->lastInsertId();
  sql('INSERT INTO auth_tokens(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 1 DAY))',[$uid,hash('sha256',$token)]);
  db()->beginTransaction();
  for ($i=0;$i<301;$i++) sql("INSERT INTO transactions(user_id,type,title,amount,transaction_date,note,source) VALUES(?,'expense',?,?,'2026-10-12','','manual')",[$uid,'Expense '.$i,'1.25']);
  sql("INSERT INTO transactions(user_id,type,title,amount,transaction_date,note,source) VALUES(?,'income','Income',10,'2026-10-12','','manual')",[$uid]);
  sql("INSERT INTO transactions(user_id,type,title,amount,transaction_date,note,source) VALUES(?,'expense','Outside month',999,'2026-09-12','','manual')",[$uid]);
  db()->commit();
  $result=transactions_query(['type'=>'expense','month'=>'2026-10']);
  expect_total(count($result['items'])===300,'list remains capped at 300');
  expect_total($result['count']===301 && (float)$result['total']===376.25,'total includes all 301 expenses');
  $result=transactions_query(['type'=>'income','month'=>'2026-10']);
  expect_total($result['count']===1 && (float)$result['total']===10.0,'income total excludes expenses');
  $result=transactions_query(['type'=>'expense','month'=>'2026-10','q'=>'Expense 300']);
  expect_total($result['count']===1 && (float)$result['total']===1.25,'summary applies search filter');
  $result=transactions_query(['type'=>'expense','month'=>'2026-11']);
  expect_total($result['count']===0 && (float)$result['total']===0.0,'empty month returns zero');
} finally {
  if (db()->inTransaction()) db()->rollBack();
  if ($uid!==null) sql('DELETE FROM users WHERE id=?',[$uid]);
}
