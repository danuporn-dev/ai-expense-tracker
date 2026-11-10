<?php
declare(strict_types=1);
require_once __DIR__.'/../src/common.php';
require_once __DIR__.'/../src/auth.php';
require_once __DIR__.'/../src/transactions.php';
require_once __DIR__.'/../src/budgets.php';
require_once __DIR__.'/../src/subscriptions.php';
require_once __DIR__.'/../src/installments.php';
require_once __DIR__.'/../src/dashboard.php';
require_once __DIR__.'/../src/ai.php';
try {
  $route=(string)($_GET['route']??'');
  if ($route==='health') reply(['status'=>'ok','app'=>'Finance Tracker API']);
  if (str_starts_with($route,'auth/')) handle_auth($route);
  $uid=auth();
  switch($route) {
    case 'categories': handle_categories($uid);
    case 'transactions': handle_transactions($uid);
    case 'budgets': handle_budgets($uid);
    case 'subscriptions': case 'subscriptions/pay': handle_subscriptions($uid,$route);
    case 'installments': case 'installments/pay': case 'installments/unpay': case 'installments/proof': handle_installments($uid,$route);
    case 'dashboard': handle_dashboard($uid);
    case 'ai/scan': handle_ai($uid);
    case 'receipts/image': handle_receipt_image($uid);
    default: fail('ไม่พบ API',404);
  }
} catch(Throwable $e) {
  $configDebug=(bool)($config['debug']??false);
  error_log('Finance Tracker API error: '.$e);
  fail($configDebug ? $e->getMessage() : 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์',500);
}
