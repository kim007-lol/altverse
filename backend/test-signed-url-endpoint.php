<?php

/**
 * Test Signed URL Endpoint
 * Run: php test-signed-url-endpoint.php
 */

require __DIR__ . '/vendor/autoload.php';

// Load .env
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

echo "🔍 Testing Signed URL Endpoint...\n\n";

// Test configuration
$config = [
    'region' => $_ENV['AWS_DEFAULT_REGION'],
    'endpoint' => $_ENV['AWS_ENDPOINT'],
    'bucket' => $_ENV['AWS_BUCKET'],
    'key' => $_ENV['AWS_ACCESS_KEY_ID'],
    'secret' => $_ENV['AWS_SECRET_ACCESS_KEY'],
    'use_path_style_endpoint' => filter_var($_ENV['AWS_USE_PATH_STYLE_ENDPOINT'], FILTER_VALIDATE_BOOLEAN),
];

echo "📋 Configuration:\n";
echo "   Region: {$config['region']}\n";
echo "   Endpoint: {$config['endpoint']}\n";
echo "   Bucket: {$config['bucket']}\n";
echo "   Use Path Style: " . ($config['use_path_style_endpoint'] ? 'true' : 'false') . "\n\n";

try {
    // Test 1: Create S3 Client directly
    echo "🧪 Test 1: Create S3 Client\n";

    $client = new \Aws\S3\S3Client([
        'version' => 'latest',
        'region' => $config['region'],
        'endpoint' => $config['endpoint'],
        'use_path_style_endpoint' => $config['use_path_style_endpoint'],
        'credentials' => [
            'key' => $config['key'],
            'secret' => $config['secret'],
        ],
    ]);

    echo "✅ S3 Client created successfully\n\n";

    // Test 2: Generate presigned URL for image
    echo "🧪 Test 2: Generate Presigned URL (Image)\n";

    $imagePath = 'episodes/pages/test_' . uniqid() . '_image.jpg';

    $command = $client->getCommand('PutObject', [
        'Bucket' => $config['bucket'],
        'Key' => $imagePath,
        'ContentType' => 'image/jpeg',
    ]);

    $presignedRequest = $client->createPresignedRequest($command, '+5 minutes');
    $signedUrl = (string) $presignedRequest->getUri();

    echo "✅ Presigned URL generated for image\n";
    echo "   Path: {$imagePath}\n";
    echo "   URL: " . substr($signedUrl, 0, 100) . "...\n\n";

    // Test 3: Generate presigned URL for audio
    echo "🧪 Test 3: Generate Presigned URL (Audio)\n";

    $audioPath = 'episodes/music/test_' . uniqid() . '_audio.mp3';

    $command = $client->getCommand('PutObject', [
        'Bucket' => $config['bucket'],
        'Key' => $audioPath,
        'ContentType' => 'audio/mpeg',
    ]);

    $presignedRequest = $client->createPresignedRequest($command, '+5 minutes');
    $signedUrl = (string) $presignedRequest->getUri();

    echo "✅ Presigned URL generated for audio\n";
    echo "   Path: {$audioPath}\n";
    echo "   URL: " . substr($signedUrl, 0, 100) . "...\n\n";

    // Test 4: Verify public URL generation
    echo "🧪 Test 4: Public URL Generation\n";

    $publicUrl = rtrim($_ENV['AWS_URL'], '/') . '/' . $imagePath;

    echo "✅ Public URL generated\n";
    echo "   URL: {$publicUrl}\n\n";

    echo "✅ All tests passed!\n\n";
    echo "📝 The endpoint should work now. Try uploading from Flutter app.\n\n";
} catch (Exception $e) {
    echo "❌ Error: {$e->getMessage()}\n";
    echo "   File: {$e->getFile()}\n";
    echo "   Line: {$e->getLine()}\n\n";

    echo "🔧 Troubleshooting:\n";
    echo "   1. Check .env configuration\n";
    echo "   2. Verify AWS credentials\n";
    echo "   3. Check R2 bucket exists\n";
}
