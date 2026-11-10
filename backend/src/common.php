<?php
declare(strict_types=1);
date_default_timezone_set('Asia/Bangkok');
$configFile = dirname(__DIR__) . '/config/app-config.php';
if (!is_file($configFile)) { http_response_code(503); header('Content-Type: application/json; charset=utf-8'); echo json_encode(['error'=>'โปรดคัดลอก config/app-config.example.php เป็น config/app-config.php']); exit; }
$config = require $configFile;
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (preg_match('~^https?://(localhost|127\.0\.0\.1)(:\d+)?$~', $origin)) {
  header('Access-Control-Allow-Origin: ' . $origin);
  header('Vary: Origin');
}
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') { http_response_code(204); exit; }
header('Content-Type: application/json; charset=utf-8');
function db(): PDO {
  global $config;
  static $pdo = null;
  if ($pdo) return $pdo;
  $db = $config['database'];
  $pdo = new PDO("mysql:host={$db['host']};port={$db['port']};dbname={$db['name']};charset=utf8mb4", $db['user'], $db['password'], [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES=>false]);
  return $pdo;
}
function reply(array $data, int $code=200): never { http_response_code($code); echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE); exit; }
function fail(string $message, int $code=400): never { reply(['error'=>$message], $code); }
function body(): array {
  if ((int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 131072) fail('ข้อมูลเกินขนาดที่กำหนด',413);
  $obj = json_decode(file_get_contents('php://input'), true);
  if (!is_array($obj)) fail('JSON ไม่ถูกต้อง');
  return $obj;
}
function sql(string $query, array $params=[]): PDOStatement { $stmt=db()->prepare($query); $stmt->execute($params); return $stmt; }
function auth(): int {
  $h=$_SERVER['HTTP_AUTHORIZATION'] ?? '';
  if (!$h && function_exists('getallheaders')) { $headers=getallheaders(); $h=$headers['Authorization'] ?? $headers['authorization'] ?? ''; }
  if (!preg_match('/^Bearer ([a-f0-9]{64})$/i',$h,$m)) fail('กรุณาเข้าสู่ระบบ',401);
  $row=sql('SELECT user_id FROM auth_tokens WHERE token_hash=? AND expires_at > NOW()', [hash('sha256',$m[1])])->fetch();
  if (!$row) fail('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',401);
  return (int)$row['user_id'];
}
function method(string ...$allowed): void { if (!in_array($_SERVER['REQUEST_METHOD'] ?? '',$allowed,true)) fail('Method ไม่รองรับ',405); }
function text_field($raw, string $label, int $max=150): string {
  $v=trim((string)($raw ?? ''));
  if ($v==='' || mb_strlen($v)>$max) fail("กรอก{$label} ให้ถูกต้อง");
  return $v;
}
function money_cents_field($raw, bool $allowZero=false): int {
  if (!is_string($raw) && !is_int($raw) && !is_float($raw)) fail('กรอกจำนวนเงินเป็นตัวเลขไม่เกิน 2 ตำแหน่งทศนิยม');
  $value=trim((string)$raw);
  if (!preg_match('/^\d{1,10}(\.\d{1,2})?$/',$value)) fail('กรอกจำนวนเงินเป็นตัวเลขไม่เกิน 2 ตำแหน่งทศนิยม');
  $parts=explode('.',$value);
  $cents=(int)$parts[0]*100+(int)str_pad($parts[1]??'',2,'0');
  if ($cents<($allowZero ? 0 : 1) || $cents>999999999999) fail('จำนวนเงินต้องอยู่ระหว่าง '.($allowZero ? '0' : '0.01').' และ 9,999,999,999.99 บาท');
  return $cents;
}
function amount_field($raw): float {
  return money_cents_field($raw)/100;
}
function date_field($date): string {
  $v=(string)$date;
  if (!preg_match('/^\d{4}-\d{2}-\d{2}$/',$v)) fail('วันที่ไม่ถูกต้อง');
  [$y,$m,$d]=array_map('intval',explode('-',$v));
  if (!checkdate($m,$d,$y)) fail('วันที่ไม่ถูกต้อง');
  return $v;
}
function month_field($v): string {
  $v=(string)$v;
  if (!preg_match('/^\d{4}-(0[1-9]|1[0-2])$/',$v)) fail('เดือนต้องเป็น YYYY-MM');
  return $v;
}
function id_param(string $name='id'): int { $id=filter_var($_GET[$name] ?? null,FILTER_VALIDATE_INT); if (!$id || $id<1) fail("ต้องระบุ {$name}"); return $id; }
function category_check(int $userId, $categoryId, string $type): ?int {
  if ($categoryId === null || $categoryId === '' || $categoryId === 0) return null;
  $id=(int)$categoryId;
  if (!$id || !sql('SELECT id FROM categories WHERE id=? AND user_id=? AND type=?',[$id,$userId,$type])->fetch()) fail('หมวดหมู่ไม่ถูกต้อง');
  return $id;
}
function scalar_id($id): int { if (!is_numeric($id) || (int)$id<1) fail('ID ไม่ถูกต้อง'); return (int)$id; }
function starts(string $month): array { return [$month.'-01',(new DateTimeImmutable($month.'-01'))->modify('+1 month')->format('Y-m-d')]; }
