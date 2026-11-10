<?php
declare(strict_types=1);

// Calculate in satang; distribute rounding to the final payment only.
function installment_schedule(int $principal, int $count, string $firstDue, ?int $contractAmount=null): array {
  if ($principal<1 || $count<1 || $count>360 || $principal<$count) throw new InvalidArgumentException('ยอดผ่อนต้องไม่น้อยกว่า 0.01 บาทต่องวด และจำนวนงวดต้องเป็น 1–360');
  $first=DateTimeImmutable::createFromFormat('!Y-m-d',$firstDue);
  if (!$first || $first->format('Y-m-d')!==$firstDue || (int)$first->format('Y')<1900) throw new InvalidArgumentException('วันที่งวดแรกไม่ถูกต้อง');
  $regular=$contractAmount ?? intdiv($principal,$count);
  $total=$contractAmount!==null ? $contractAmount*$count : $principal;
  if ($regular<1 || $total<$principal || $total>999999999999) throw new InvalidArgumentException('ยอดตามสัญญาต้องไม่น้อยกว่ายอดสินค้าที่ผ่อน และยอดรวมต้องไม่เกิน 9,999,999,999.99 บาท');
  $anchor=$first->modify('first day of this month');
  $day=(int)$first->format('d');
  $rows=[];
  for ($i=0;$i<$count;$i++) {
    $month=$anchor->modify('+'.$i.' months');
    if ((int)$month->format('Y')>2100) throw new InvalidArgumentException('วันครบกำหนดต้องไม่เกินปี 2100');
    $due=$month->setDate((int)$month->format('Y'),(int)$month->format('m'),min($day,(int)$month->format('t')));
    $rows[]=['installment_number'=>$i+1,'due_date'=>$due->format('Y-m-d'),'amount_cents'=>$i===$count-1 ? $total-$regular*($count-1) : $regular];
  }
  return $rows;
}
