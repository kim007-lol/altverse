<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Instantiate controller directly to bypass middleware
$controller = new \App\Http\Controllers\Api\V1\Reader\TopUpController();
$response = $controller->packages();

echo $response->getContent();
