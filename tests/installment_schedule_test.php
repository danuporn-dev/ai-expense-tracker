<?php
require __DIR__.'/../backend/src/installment_schedule.php';
function check_schedule(bool $ok,string $message): void {
  if (!$ok) throw new RuntimeException($message);
  echo 'PASS: '.$message.PHP_EOL;
}
$rows=installment_schedule(2000000,10,'2026-10-20');
check_schedule(count($rows)===10 && $rows[0]['amount_cents']===200000,'phone contract has 10 x 2000');
check_schedule(array_sum(array_column($rows,'amount_cents'))===2000000,'principal preserved');
$rows=installment_schedule(10000,3,'2028-01-31');
check_schedule(array_column($rows,'due_date')===['2028-01-31','2028-02-29','2028-03-31'],'leap February clamps without shifting March');
check_schedule(array_column($rows,'amount_cents')===[3333,3333,3334],'final payment absorbs satang');
$rows=installment_schedule(10000,3,'2027-01-31',3500);
check_schedule(array_column($rows,'due_date')===['2027-01-31','2027-02-28','2027-03-31'],'non-leap February clamps');
check_schedule(array_sum(array_column($rows,'amount_cents'))===10500,'contract installments include charges');
foreach ([[100,0,'2026-01-01',null],[100,361,'2026-01-01',null],[2,3,'2026-01-01',null],[10000,3,'2026-01-01',3000],[100,1,'2026-02-30',null],[100,2,'2100-12-31',null]] as $args) {
  try { installment_schedule(...$args); throw new RuntimeException('invalid schedule accepted'); }
  catch (InvalidArgumentException $e) { check_schedule(true,'invalid schedule rejected'); }
}
