<?php
// Copy as app-config.php. Never commit actual secrets.
return [
    'database' => [
        'host' => '127.0.0.1', 'port' => '3306', 'name' => 'finance_tracker',
        'user' => 'root', 'password' => '',
    ],
    'ai' => [
        'api_key' => getenv('OPENAI_API_KEY') ?: '',
        'endpoint' => getenv('AI_API_ENDPOINT') ?: 'https://api.openai.com/v1/chat/completions',
        'model' => getenv('AI_MODEL') ?: 'gpt-4.1-mini',
    ],
    'debug' => false,
];
