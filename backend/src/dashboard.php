<?php
declare(strict_types=1);
function handle_dashboard(int $uid): never {
  method('GET');
  $p=(string)($_GET['period']??'month'); if(!in_array($p,['day','month','year'],true)) fail('ช่วงเวลาไม่ถูกต้อง');
  $d=new DateTimeImmutable(date_field($_GET['date']??date('Y-m-d')));
  if($p==='day') { $from=$d->format('Y-m-d'); $to=$d->modify('+1 day')->format('Y-m-d'); $chartFrom=$d->modify('-6 days')->format('Y-m-d'); $chartTo=$to; $fmt='%Y-%m-%d'; }
  elseif($p==='month') { $from=$d->format('Y-m-01'); $to=$d->modify('first day of next month')->format('Y-m-d'); $chartFrom=$from; $chartTo=$to; $fmt='%Y-%m-%d'; }
  else { $from=$d->format('Y-01-01'); $to=$d->modify('+1 year')->format('Y-01-01'); $chartFrom=$from; $chartTo=$to; $fmt='%Y-%m'; }
  $totals=['income'=>0,'expense'=>0];
  foreach(sql('SELECT type,SUM(amount) total FROM transactions WHERE user_id=? AND transaction_date>=? AND transaction_date<? GROUP BY type',[$uid,$from,$to])->fetchAll() as $r) $totals[$r['type']]=(float)$r['total'];
  $groups=sql("SELECT COALESCE(c.name,'ไม่ระบุ') name,SUM(t.amount) amount FROM transactions t LEFT JOIN categories c ON c.id=t.category_id WHERE t.user_id=? AND t.type='expense' AND t.transaction_date>=? AND t.transaction_date<? GROUP BY t.category_id,c.name ORDER BY amount DESC LIMIT 6",[$uid,$from,$to])->fetchAll();
  $recent=sql('SELECT t.id,t.type,t.title,t.amount,t.transaction_date,c.name category_name FROM transactions t LEFT JOIN categories c ON c.id=t.category_id WHERE t.user_id=? ORDER BY t.transaction_date DESC,t.id DESC LIMIT 5',[$uid])->fetchAll();
  $raw=sql("SELECT DATE_FORMAT(transaction_date,'{$fmt}') bucket,type,SUM(amount) total FROM transactions WHERE user_id=? AND transaction_date>=? AND transaction_date<? GROUP BY bucket,type",[$uid,$chartFrom,$chartTo])->fetchAll();
  $buckets=[]; foreach($raw as $r) $buckets[$r['bucket']][$r['type']]=(float)$r['total'];
  $chart=[];
  $cursor=new DateTimeImmutable($chartFrom); $until=new DateTimeImmutable($chartTo);
  while ($cursor<$until) { $key=$cursor->format($p==='year'?'Y-m':'Y-m-d'); $chart[]=['label'=>$p==='year'?$cursor->format('m'):$cursor->format('d'),'income'=>$buckets[$key]['income']??0,'expense'=>$buckets[$key]['expense']??0]; $cursor=$cursor->modify($p==='year'?'+1 month':'+1 day'); }
  $budget=sql("SELECT b.amount, (SELECT COALESCE(SUM(t.amount),0) FROM transactions t WHERE t.user_id=? AND t.type='expense' AND t.transaction_date>=? AND t.transaction_date<?) spent FROM budgets b WHERE b.user_id=? AND b.month_key=? AND b.budget_key='total' LIMIT 1",[$uid,...starts($d->format('Y-m')),$uid,$d->format('Y-m')])->fetch();
  reply(['period'=>$p,'from'=>$from,'to'=>$to,'income'=>$totals['income'],'expense'=>$totals['expense'],'balance'=>$totals['income']-$totals['expense'],'categories'=>$groups,'recent'=>$recent,'chart'=>$chart,'budget'=>$budget?:null]);
}
