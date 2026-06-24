<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$users = \App\Models\User::select('id','name','username','pen_name')->get();
foreach ($users as $u) {
    echo "ID:{$u->id} | name: {$u->name} | username: {$u->username} | pen_name: {$u->pen_name}\n";
}
