<?php
declare(strict_types=1);
// CLI only: applies the additive migration to the configured local database.
if (PHP_SAPI!=='cli') { http_response_code(404); exit; }
require (getenv('BACKEND_ROOT') ?: dirname(__DIR__)).'/src/common.php';
$migration=file_get_contents(__DIR__.'/migrations/002_installments.sql');
foreach (explode(';',$migration) as $statement) {
  if (trim($statement)!=='') db()->exec($statement);
}
echo "Installment schema ready.\n";
