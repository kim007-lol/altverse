<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Get a reader user
$user = \App\Models\User::where('role', 'reader')->first();

if (!$user) {
    echo "❌ No reader user found in database\n";
    exit(1);
}

echo "✅ Testing with user: {$user->name} (ID: {$user->id}, Role: {$user->role})\n\n";

// Test MissionService
$missionService = new \App\Services\MissionService();
$missions = $missionService->getUserMissions($user);

echo "📊 Missions Count: " . count($missions) . "\n\n";

if (empty($missions)) {
    echo "❌ No missions returned!\n";

    // Check if missions exist in database
    $dbMissions = \App\Models\Mission::active()->count();
    echo "Database has {$dbMissions} active missions\n";
} else {
    echo "✅ Missions loaded successfully!\n\n";

    // Show first 3 missions
    foreach (array_slice($missions, 0, 3) as $mission) {
        echo "- {$mission['name']} ({$mission['type']})\n";
        echo "  Progress: {$mission['progress']}/{$mission['target_count']}\n";
        echo "  Completed: " . ($mission['is_completed'] ? 'Yes' : 'No') . "\n";
        echo "  Claimed: " . ($mission['is_claimed'] ? 'Yes' : 'No') . "\n\n";
    }
}
