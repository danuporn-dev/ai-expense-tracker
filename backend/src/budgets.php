<?php
declare(strict_types=1);
function handle_budgets(int $uid): never {
  $method=$_SERVER['REQUEST_METHOD'];
  if ($method==='GET') {
    $month=month_field($_GET['month']??date('Y-m')); [$from,$to]=starts($month);
    $rows=sql("SELECT b.id,b.category_id,b.budget_key,b.month_key,b.amount,c.name AS category_name,
      CASE WHEN b.category_id IS NULL THEN
        (SELECT COALESCE(SUM(t.amount),0) FROM transactions t WHERE t.user_id=b.user_id AND t.type='expense' AND t.transaction_date>=? AND t.transaction_date<?)
      ELSE
        (SELECT COALESCE(SUM(t.amount),0) FROM transactions t WHERE t.user_id=b.user_id AND t.type='expense' AND t.category_id=b.category_id AND t.transaction_date>=? AND t.transaction_date<?)
      END AS spent
      FROM budgets b LEFT JOIN categories c ON c.id=b.category_id WHERE b.user_id=? AND b.month_key=? ORDER BY b.category_id IS NOT NULL,b.id",[$from,$to,$from,$to,$uid,$month])->fetchAll();
    reply(['month'=>$month,'items'=>$rows]);
  }
  if ($method==='POST') {
    $b=body(); $month=month_field($b['month']??date('Y-m'));
    $cat=category_check($uid,$b['category_id']??null,'expense');
    $key=$cat===null?'total':'cat_'.$cat; $amount=amount_field($b['amount']??null);
    sql('INSERT INTO budgets(user_id,category_id,budget_key,month_key,amount) VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE amount=VALUES(amount)',[$uid,$cat,$key,$month,$amount]);
    reply(['message'=>'บันทึกงบประมาณแล้ว'],201);
  }
  if ($method==='DELETE') { $id=id_param(); sql('DELETE FROM budgets WHERE id=? AND user_id=?',[$id,$uid]); reply(['message'=>'ลบงบประมาณแล้ว']); }
  fail('Method ไม่รองรับ',405);
}
