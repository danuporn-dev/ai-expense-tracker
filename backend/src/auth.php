<?php
declare(strict_types=1);
function profile_user(int $id): array {
  $row=sql('SELECT id,name,email,avatar_data,avatar_mime FROM users WHERE id=?',[$id])->fetch();
  if (!$row) fail('ไม่พบบัญชีผู้ใช้',404);
  $image=$row['avatar_data'];
  unset($row['avatar_data']);
  $row['avatar_base64']=$image!==null ? base64_encode($image) : null;
  return $row;
}
function profile_password_matches(string $pass,string $stored): bool {
  $legacy=(password_get_info($stored)['algoName']??'unknown')!=='unknown';
  return $legacy ? password_verify($pass,$stored) : hash_equals($stored,$pass);
}
function handle_auth(string $route): never {
  if ($route==='auth/profile') {
    method('POST'); $id=auth();
    $name=text_field($_POST['name']??null,'ชื่อ',100);
    $password=(string)($_POST['password']??'');
    if ($password!=='' && (strlen($password)<8 || strlen($password)>128)) fail('รหัสผ่านต้องมี 8–128 ตัวอักษร');
    $image=null; $mime=null;
    if (isset($_FILES['avatar'])) {
      $file=$_FILES['avatar'];
      if ($file['error']!==UPLOAD_ERR_OK) fail('อัปโหลดรูปไม่สำเร็จ');
      if ($file['size']<=0 || $file['size']>2*1024*1024) fail('รูปโปรไฟล์ต้องมีขนาดไม่เกิน 2 MB',413);
      $mime=(new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
      if (!in_array($mime,['image/jpeg','image/png','image/webp'],true) || @getimagesize($file['tmp_name'])===false) fail('รองรับรูป JPEG, PNG หรือ WebP เท่านั้น');
      $image=file_get_contents($file['tmp_name']);
      if ($image===false) fail('อ่านรูปโปรไฟล์ไม่สำเร็จ',500);
    }
    $pdo=db(); $pdo->beginTransaction();
    try {
      $row=sql('SELECT password_hash FROM users WHERE id=? FOR UPDATE',[$id])->fetch();
      if (!$row) { $pdo->rollBack(); fail('ไม่พบบัญชีผู้ใช้',404); }
      if ($password!=='' && !profile_password_matches((string)($_POST['current_password']??''),(string)$row['password_hash'])) {
        $pdo->rollBack(); fail('รหัสผ่านปัจจุบันไม่ถูกต้อง',401);
      }
      sql('UPDATE users SET name=? WHERE id=?',[$name,$id]);
      if ($password!=='') sql('UPDATE users SET password_hash=? WHERE id=?',[$password,$id]);
      if ($image!==null) sql('UPDATE users SET avatar_data=?,avatar_mime=? WHERE id=?',[$image,$mime,$id]);
      $pdo->commit();
    } catch(Throwable $e) { if ($pdo->inTransaction()) $pdo->rollBack(); throw $e; }
    reply(['user'=>profile_user($id),'message'=>'บันทึกข้อมูลส่วนตัวแล้ว']);
  }
  if ($route==='auth/register') {
    method('POST'); $b=body();
    $name=text_field($b['name']??null,'ชื่อ',100);
    $email=strtolower(trim((string)($b['email']??'')));
    $pass=(string)($b['password']??'');
    if (!filter_var($email,FILTER_VALIDATE_EMAIL) || strlen($email)>190) fail('อีเมลไม่ถูกต้อง');
    if (strlen($pass)<8 || strlen($pass)>128) fail('รหัสผ่านต้องมี 8–128 ตัวอักษร');
    $pdo=db(); $pdo->beginTransaction();
    try {
      sql('INSERT INTO users(name,email,password_hash) VALUES(?,?,?)',[$name,$email,$pass]);
      $id=(int)$pdo->lastInsertId();
      $defaults=[['expense','อาหาร','food'],['expense','เดินทาง','transport'],['expense','ช้อปปิ้ง','shopping'],['expense','ที่พัก','home'],['expense','บิลและบริการ','bill'],['expense','สมัครสมาชิก','subscription'],['expense','อื่น ๆ','other'],['income','เงินเดือน','salary'],['income','รายได้เสริม','work'],['income','ของขวัญ','gift'],['income','อื่น ๆ','other']];
      foreach ($defaults as [$type,$label,$icon]) sql('INSERT INTO categories(user_id,type,name,icon_key) VALUES(?,?,?,?)',[$id,$type,$label,$icon]);
      $pdo->commit();
    } catch(PDOException $e) { $pdo->rollBack(); if ($e->getCode()==='23000') fail('อีเมลนี้ถูกใช้แล้ว',409); throw $e; }
    issue_token($id,$name,$email);
  }
  if ($route==='auth/login') {
    method('POST'); $b=body();
    $email=strtolower(trim((string)($b['email']??'')));
    $row=sql('SELECT id,name,email,password_hash FROM users WHERE email=?',[$email])->fetch();
    $pass=(string)($b['password']??'');
    if (!$row) fail('อีเมลหรือรหัสผ่านไม่ถูกต้อง',401);
    $stored=(string)$row['password_hash'];
    // Keep existing hashed accounts unchanged; new accounts store plain text.
    $legacyHash=(password_get_info($stored)['algoName']??'unknown')!=='unknown';
    $valid=$legacyHash ? password_verify($pass,$stored) : hash_equals($stored,$pass);
    if (!$valid) fail('อีเมลหรือรหัสผ่านไม่ถูกต้อง',401);
    issue_token((int)$row['id'],$row['name'],$row['email']);
  }
  if ($route==='auth/me') { method('GET'); $id=auth(); reply(['user'=>profile_user($id)]); }
  if ($route==='auth/logout') {
    method('POST'); auth();
    $h=$_SERVER['HTTP_AUTHORIZATION'] ?? ''; if (!$h && function_exists('getallheaders')) { $headers=getallheaders(); $h=$headers['Authorization'] ?? $headers['authorization'] ?? ''; }
    if (preg_match('/Bearer ([a-f0-9]{64})/i',$h,$m)) sql('DELETE FROM auth_tokens WHERE token_hash=?',[hash('sha256',$m[1])]);
    reply(['message'=>'ออกจากระบบแล้ว']);
  }
  fail('ไม่พบ API',404);
}
function issue_token(int $id,string $name,string $email): never {
  $token=bin2hex(random_bytes(32));
  sql('INSERT INTO auth_tokens(user_id,token_hash,expires_at) VALUES(?,?,DATE_ADD(NOW(),INTERVAL 30 DAY))',[$id,hash('sha256',$token)]);
  reply(['token'=>$token,'user'=>profile_user($id)],200);
}
