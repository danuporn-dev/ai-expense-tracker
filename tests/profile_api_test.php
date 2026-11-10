<?php
// Integration test against local XAMPP; creates and deletes two temporary accounts.
require (getenv('BACKEND_ROOT') ?: 'C:/xampp/htdocs/mobileapp_backend/backend').'/src/common.php';
$base=getenv('TEST_API_URL') ?: 'http://localhost/mobileapp_backend/backend/api/index.php';
function call_api(string $route,string $method='GET',array $data=[],?string $token=null,bool $multipart=false): array {
  global $base;
  $curl=curl_init($base.'?route='.rawurlencode($route));
  $headers=$token!==null ? ['Authorization: Bearer '.$token] : [];
  if (!$multipart) $headers[]='Content-Type: application/json';
  curl_setopt_array($curl,[CURLOPT_CUSTOMREQUEST=>$method,CURLOPT_HTTPHEADER=>$headers,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>10]);
  if ($method!=='GET') curl_setopt($curl,CURLOPT_POSTFIELDS,$multipart ? $data : json_encode($data));
  $response=curl_exec($curl);
  $status=curl_getinfo($curl,CURLINFO_HTTP_CODE);
  if ($response===false) throw new RuntimeException('Local request failed: '.curl_error($curl));
  $body=json_decode($response,true);
  if (!is_array($body)) throw new RuntimeException('Non-JSON local response, status '.$status);
  return [$status,$body];
}
function check(bool $valid,string $label): void {
  if (!$valid) throw new RuntimeException('FAIL: '.$label);
  echo 'PASS: '.$label.PHP_EOL;
}
$suffix=bin2hex(random_bytes(10));
$emails=['profile-a-'.$suffix.'@example.invalid','profile-b-'.$suffix.'@example.invalid'];
$password='Test!'.bin2hex(random_bytes(12));
$newPassword='New!'.bin2hex(random_bytes(12));
$image=tempnam(sys_get_temp_dir(),'profile_png_');
$invalid=tempnam(sys_get_temp_dir(),'profile_bad_');
$png=base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=');
file_put_contents($image,$png);
file_put_contents($invalid,'not an image');
try {
  [$status,$a]=call_api('auth/register','POST',['name'=>'Profile test A','email'=>$emails[0],'password'=>$password]);
  check($status===200,'first temporary account registered');
  [$status,$b]=call_api('auth/register','POST',['name'=>'Profile test B','email'=>$emails[1],'password'=>$password]);
  check($status===200,'second temporary account registered');
  $token=$a['token'];
  sql('DELETE FROM categories WHERE user_id=?',[$a['user']['id']]);
  [$status,$categories]=call_api('categories','GET',[],$token);
  check($status===200 && count($categories['items'])===11,'missing standard categories restored');
  [$status,$again]=call_api('categories','GET',[],$token);
  check(count($again['items'])===11,'category restoration is idempotent');
  $food=null;
  foreach ($categories['items'] as $category) {
    if ($category['type']==='expense' && $category['name']==='อาหาร') $food=$category['id'];
  }
  check($food!==null,'AI food category available');
  [$status]=call_api('transactions','POST',['type'=>'expense','title'=>'Test receipt','amount'=>156.77,'transaction_date'=>'2017-03-27','category_id'=>$food,'note'=>'']);
  // An authenticated request must be supplied for saving the suggested category.
  check($status===401,'anonymous transaction rejected');
  [$status]=call_api('transactions','POST',['type'=>'expense','title'=>'Test receipt','amount'=>156.77,'transaction_date'=>'2017-03-27','category_id'=>$food,'note'=>''],$token);
  check($status===201,'expense saved with suggested category');
  [$status,$saved]=call_api('transactions','GET',[],$token);
  check(count($saved['items'])===1 && $saved['items'][0]['category_name']==='อาหาร','saved expense retains suggested food category');
  [$status]=call_api('auth/profile','POST',['name'=>'Unauthorized'],null,true);
  check($status===401,'unauthenticated update rejected');
  [$status,$result]=call_api('auth/profile','POST',['name'=>'ชื่อใหม่','user_id'=>$b['user']['id'],'avatar'=>new CURLFile($image,'image/png','avatar.png')],$token,true);
  check($status===200 && $result['user']['name']==='ชื่อใหม่','name and avatar updated');
  check(base64_decode($result['user']['avatar_base64'])===$png && $result['user']['avatar_mime']==='image/png','uploaded avatar returned exactly');
  check(!isset($result['user']['password_hash']),'password excluded from response');
  [$status,$result]=call_api('auth/me','GET',[],$b['token']);
  check($result['user']['name']==='Profile test B' && $result['user']['avatar_base64']===null,'other user cannot be changed through user_id');
  [$status]=call_api('auth/profile','POST',['name'=>'Should not save','password'=>$newPassword,'current_password'=>'wrong-password'],$token,true);
  check($status===401,'wrong current password rejected');
  [$status,$result]=call_api('auth/me','GET',[],$token);
  check($result['user']['name']==='ชื่อใหม่','failed password change leaves name unchanged');
  [$status]=call_api('auth/profile','POST',['name'=>'Should not save','avatar'=>new CURLFile($invalid,'image/png','avatar.png')],$token,true);
  check($status===400,'invalid avatar rejected');
  [$status]=call_api('auth/profile','POST',['name'=>'ชื่อใหม่','password'=>$newPassword,'current_password'=>$password],$token,true);
  check($status===200,'password changed using current password');
  [$status]=call_api('auth/login','POST',['email'=>$emails[0],'password'=>$password]);
  check($status===401,'previous password rejected');
  [$status,$result]=call_api('auth/login','POST',['email'=>$emails[0],'password'=>$newPassword]);
  check($status===200 && $result['user']['name']==='ชื่อใหม่' && base64_decode($result['user']['avatar_base64'])===$png,'new login restores name and avatar');
  [$status]=call_api('auth/profile','POST',['name'=>''],$token,true);
  check($status===400,'empty name rejected');
  [$status]=call_api('auth/profile','POST',['name'=>'ชื่อใหม่','password'=>'short','current_password'=>$newPassword],$token,true);
  check($status===400,'short new password rejected');
  file_put_contents($invalid,str_repeat('x',2*1024*1024+1));
  [$status]=call_api('auth/profile','POST',['name'=>'ชื่อใหม่','avatar'=>new CURLFile($invalid,'image/png','large.png')],$token,true);
  check($status===413,'oversized avatar rejected');
  $legacy=password_hash($password,PASSWORD_DEFAULT);
  sql('UPDATE users SET password_hash=? WHERE email=?',[$legacy,$emails[1]]);
  [$status]=call_api('auth/profile','POST',['name'=>'Legacy renamed'],$b['token'],true);
  check($status===200 && sql('SELECT password_hash FROM users WHERE email=?',[$emails[1]])->fetchColumn()===$legacy,'name edit preserves legacy password hash');
  [$status]=call_api('auth/profile','POST',['name'=>'Legacy renamed','password'=>$newPassword,'current_password'=>$password],$b['token'],true);
  check($status===200,'legacy password can be changed after verification');
} finally {
  foreach ($emails as $email) sql('DELETE FROM users WHERE email=?',[$email]);
  @unlink($image); @unlink($invalid);
}
