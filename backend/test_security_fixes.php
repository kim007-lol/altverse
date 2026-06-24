<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = \App\Models\User::where('role', 'reader')->first();
$request = \Illuminate\Http\Request::create('/api/v1/reader/topup/create', 'POST', ['package_id' => 'pkg_basic']);
$request->setUserResolver(function() use ($user) { return $user; });

$controller = new \App\Http\Controllers\Api\V1\Reader\TopUpController();
$response = $controller->create($request);

$body = json_decode($response->getContent(), true);
echo "=== CREATE RESPONSE ===\n";
echo json_encode($body, JSON_PRETTY_PRINT) . "\n\n";

// Verify no topup model leak
echo "Has 'topup' key (should be NO): " . (isset($body['topup']) ? 'YES ⚠️' : 'NO ✅') . "\n";
echo "Has 'order_id': " . (isset($body['order_id']) ? 'YES ✅' : 'NO ⚠️') . "\n";

// Check order_id randomness (should be 8 random chars, not 3 digits)
if (isset($body['order_id'])) {
    $parts = explode('-', $body['order_id']);
    $randomPart = end($parts);
    echo "Random suffix length (should be 8): " . strlen($randomPart) . " (" . (strlen($randomPart) === 8 ? '✅' : '⚠️') . ")\n";
}
