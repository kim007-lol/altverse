<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = \App\Models\User::where('role', 'reader')->first();
$request = \Illuminate\Http\Request::create('/api/v1/reader/topup/create', 'POST', ['package_id' => 'pkg_basic']);
$request->setUserResolver(function() use ($user) { return $user; });

// Instantiate controller directly to bypass middleware
$controller = new \App\Http\Controllers\Api\V1\Reader\TopUpController();
$response = $controller->create($request);

echo $response->getContent();
