<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = \App\Models\User::where('role', 'reader')->first();
$request = \Illuminate\Http\Request::create('/api/v1/reader/topup/packages', 'GET');
$request->setUserResolver(function() use ($user) { return $user; });
try {
    $response = app()->handle($request);
    echo $response->getContent();
} catch (\Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
