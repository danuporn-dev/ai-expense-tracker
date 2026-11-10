<?php
declare(strict_types=1);
function parse_receipt_ai_response(array $outer): ?array {
  $content=$outer['choices'][0]['message']['content']??null;
  if (is_array($content)) {
    $text=[];
    foreach ($content as $part) {
      if (is_array($part) && ($part['type']??'')==='text' && is_string($part['text']??null)) $text[]=$part['text'];
    }
    $content=implode("\n",$text);
  }
  if (!is_string($content)) return null;
  $content=trim($content);
  // Some compatible providers return Markdown fences despite JSON mode.
  if (preg_match('/\A```(?:json)?\s*\R?(.*?)\R?\s*```\z/is',$content,$matches)) $content=trim($matches[1]);
  if (!str_starts_with($content,'{')) return null;
  $parsed=json_decode($content,true);
  return json_last_error()===JSON_ERROR_NONE && is_array($parsed) ? $parsed : null;
}
function handle_ai(int $uid): never {
  global $config;
  method('POST');
  $key=$config['ai']['api_key']??''; if (!$key) fail('ยังไม่ได้ตั้งค่า AI API Key ใน Backend',503);
  if (!function_exists('curl_init')) fail('PHP ยังไม่ได้เปิด extension=curl',503);
  if (!isset($_FILES['image']) || $_FILES['image']['error']!==UPLOAD_ERR_OK) fail('กรุณาอัปโหลดรูปบิล');
  $f=$_FILES['image']; if ($f['size']<=0 || $f['size']>8*1024*1024) fail('รูปต้องมีขนาดไม่เกิน 8 MB',413);
  $mime=(new finfo(FILEINFO_MIME_TYPE))->file($f['tmp_name']);
  if (!in_array($mime,['image/png','image/jpeg','image/webp'],true)) fail('รองรับเฉพาะ JPEG, PNG หรือ WebP');
  $bin=file_get_contents($f['tmp_name']); $hash=hash('sha256',$bin);

  $messages=[
    ['role'=>'system','content'=>'You extract Thai/English payment receipts. Return ONLY a JSON object with merchant:string, date:string (YYYY-MM-DD or empty), total:number, category:string (one of อาหาร, เดินทาง, ช้อปปิ้ง, ที่พัก, บิลและบริการ, สมัครสมาชิก, อื่น ๆ), note:string, items:array of {name:string,amount:number}. Never guess an unreadable amount; return 0. Be precise about receipt total, not change or payment received.'],
    ['role'=>'user','content'=>[['type'=>'text','text'=>'อ่านบิลนี้แล้วคืน JSON ตามคำสั่ง'],['type'=>'image_url','image_url'=>['url'=>'data:'.$mime.';base64,'.base64_encode($bin)]]]],
  ];
  $payload=json_encode(['model'=>$config['ai']['model'],'messages'=>$messages,'temperature'=>0,'response_format'=>['type'=>'json_object']],JSON_UNESCAPED_UNICODE);
  $curl=curl_init($config['ai']['endpoint']);
  curl_setopt_array($curl,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>$payload,CURLOPT_HTTPHEADER=>['Authorization: Bearer '.$key,'Content-Type: application/json'],CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>50,CURLOPT_CONNECTTIMEOUT=>10]);
  $response=curl_exec($curl); $status=curl_getinfo($curl,CURLINFO_HTTP_CODE); $error=curl_error($curl); curl_close($curl);
  if ($response===false) fail('เชื่อมต่อ AI ไม่สำเร็จ: '.$error,502);
  $outer=json_decode($response,true);
  if ($status<200 || $status>=300) { error_log('AI upstream error: '.$status.' '.substr((string)$response,0,1000)); fail('AI API ไม่พร้อมใช้งาน (HTTP '.$status.') ตรวจสอบ API Key/Model',502); }
  $parsed=is_array($outer)?parse_receipt_ai_response($outer):null;
  if (!is_array($parsed)) fail('AI ตอบกลับไม่ใช่ข้อมูล JSON ที่ถูกต้อง',502);
  $total=(float)($parsed['total']??0);
  if (!is_finite($total) || round($total,2)<=0 || $total>9999999999.99) fail('AI อ่านยอดรวมไม่ได้ กรุณาบันทึกรายจ่ายด้วยตนเอง',422);
  $parsed['merchant']=mb_substr(trim((string)($parsed['merchant']??'รายการจากบิล')),0,150);
  $parsed['total']=round($total,2);
  $parsed['date']=preg_match('/^\d{4}-\d{2}-\d{2}$/',(string)($parsed['date']??'')) ? $parsed['date'] : date('Y-m-d');
  [$yy,$mm,$dd]=array_map('intval',explode('-',$parsed['date']));
  if(!checkdate($mm,$dd,$yy)) $parsed['date']=date('Y-m-d');
  $parsed['category']=mb_substr((string)($parsed['category']??'อื่น ๆ'),0,80);
  $parsed['note']=mb_substr((string)($parsed['note']??''),0,1000);
  $file=bin2hex(random_bytes(18)).match($mime){'image/jpeg'=>'.jpg','image/png'=>'.png',default=>'.webp'};
  $dest=dirname(__DIR__).'/storage/receipts/'.$file;
  if(file_put_contents($dest,$bin,LOCK_EX)===false) fail('ไม่สามารถบันทึกรูปได้',500);
  try { sql('INSERT INTO receipts(user_id,file_name,mime_type,sha256,extracted_json) VALUES(?,?,?,?,?)',[$uid,$file,$mime,$hash,json_encode($parsed,JSON_UNESCAPED_UNICODE)]); }
  catch(Throwable $e) { @unlink($dest); throw $e; }
  reply(['receipt_id'=>(int)db()->lastInsertId(),'data'=>$parsed,'message'=>'ตรวจสอบข้อมูลก่อนบันทึก'],201);
}
function handle_receipt_image(int $uid): never {
  method('GET'); $id=id_param();
  $r=sql('SELECT file_name,mime_type FROM receipts WHERE id=? AND user_id=?',[$id,$uid])->fetch();
  if(!$r) fail('ไม่พบรูปบิล',404);
  $file=dirname(__DIR__).'/storage/receipts/'.$r['file_name']; if(!is_file($file))fail('ไม่พบไฟล์',404);
  header('Content-Type: '.$r['mime_type']); header('Content-Length: '.filesize($file));
  readfile($file); exit;
}
