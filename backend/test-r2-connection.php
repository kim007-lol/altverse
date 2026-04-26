<?php

/**
 * Test R2 Connection Script
 * Run: php test-r2-connection.php
 */

require __DIR__ . '/vendor/autoload.php';

use Aws\S3\S3Client;
use Aws\Exception\AwsException;

// Load .env
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

echo "🔍 Testing R2 Connection...\n\n";

// Configuration
$config = [
    'version' => 'latest',
    'region' => $_ENV['AWS_DEFAULT_REGION'],
    'endpoint' => $_ENV['AWS_ENDPOINT'],
    'use_path_style_endpoint' => filter_var($_ENV['AWS_USE_PATH_STYLE_ENDPOINT'], FILTER_VALIDATE_BOOLEAN),
    'credentials' => [
        'key' => $_ENV['AWS_ACCESS_KEY_ID'],
        'secret' => $_ENV['AWS_SECRET_ACCESS_KEY'],
    ],
];

echo "📋 Configuration:\n";
echo "   Region: {$config['region']}\n";
echo "   Endpoint: {$config['endpoint']}\n";
echo "   Bucket: {$_ENV['AWS_BUCKET']}\n";
echo "   Use Path Style: " . ($config['use_path_style_endpoint'] ? 'true' : 'false') . "\n\n";

try {
    // Create S3 client
    $client = new S3Client($config);

    echo "✅ S3 Client created successfully\n\n";

    // Test 1: List buckets
    echo "🧪 Test 1: List Buckets\n";
    try {
        $result = $client->listBuckets();
        echo "✅ Can list buckets\n";
        foreach ($result['Buckets'] as $bucket) {
            echo "   - {$bucket['Name']}\n";
        }
    } catch (AwsException $e) {
        echo "❌ Cannot list buckets: {$e->getMessage()}\n";
    }

    echo "\n";

    // Test 2: Check if bucket exists
    echo "🧪 Test 2: Check Bucket Exists\n";
    try {
        $exists = $client->doesBucketExist($_ENV['AWS_BUCKET']);
        if ($exists) {
            echo "✅ Bucket '{$_ENV['AWS_BUCKET']}' exists\n";
        } else {
            echo "❌ Bucket '{$_ENV['AWS_BUCKET']}' does not exist\n";
        }
    } catch (AwsException $e) {
        echo "❌ Error checking bucket: {$e->getMessage()}\n";
    }

    echo "\n";

    // Test 3: Generate presigned URL
    echo "🧪 Test 3: Generate Presigned URL\n";
    try {
        $testPath = 'test/test-' . uniqid() . '.txt';

        $command = $client->getCommand('PutObject', [
            'Bucket' => $_ENV['AWS_BUCKET'],
            'Key' => $testPath,
            'ContentType' => 'text/plain',
        ]);

        $request = $client->createPresignedRequest($command, '+5 minutes');
        $presignedUrl = (string) $request->getUri();

        echo "✅ Presigned URL generated successfully\n";
        echo "   Path: {$testPath}\n";
        echo "   URL: " . substr($presignedUrl, 0, 100) . "...\n";
    } catch (AwsException $e) {
        echo "❌ Cannot generate presigned URL: {$e->getMessage()}\n";
    }

    echo "\n";

    // Test 4: Upload test file
    echo "🧪 Test 4: Upload Test File\n";
    try {
        $testContent = "Test upload at " . date('Y-m-d H:i:s');
        $testKey = 'test/upload-test-' . uniqid() . '.txt';

        $result = $client->putObject([
            'Bucket' => $_ENV['AWS_BUCKET'],
            'Key' => $testKey,
            'Body' => $testContent,
            'ContentType' => 'text/plain',
            'ACL' => 'public-read',
        ]);

        echo "✅ File uploaded successfully\n";
        echo "   Key: {$testKey}\n";
        echo "   ETag: {$result['ETag']}\n";

        // Generate public URL
        $publicUrl = $_ENV['AWS_URL'] . '/' . $testKey;
        echo "   Public URL: {$publicUrl}\n";

        // Test if file is accessible
        echo "\n   Testing public access...\n";
        $ch = curl_init($publicUrl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_NOBODY, true);
        curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200) {
            echo "   ✅ File is publicly accessible (HTTP {$httpCode})\n";
        } else {
            echo "   ⚠️  File returned HTTP {$httpCode}\n";
        }

        // Clean up
        echo "\n   Cleaning up test file...\n";
        $client->deleteObject([
            'Bucket' => $_ENV['AWS_BUCKET'],
            'Key' => $testKey,
        ]);
        echo "   ✅ Test file deleted\n";
    } catch (AwsException $e) {
        echo "❌ Upload failed: {$e->getMessage()}\n";
    }

    echo "\n";
    echo "✅ All tests completed!\n\n";

    // CORS Check
    echo "📋 CORS Configuration Check:\n";
    echo "   Make sure your R2 bucket has CORS configured:\n";
    echo "   {\n";
    echo "     \"AllowedOrigins\": [\"*\"],\n";
    echo "     \"AllowedMethods\": [\"GET\", \"PUT\", \"POST\", \"DELETE\", \"HEAD\"],\n";
    echo "     \"AllowedHeaders\": [\"*\"],\n";
    echo "     \"ExposeHeaders\": [\"ETag\"],\n";
    echo "     \"MaxAgeSeconds\": 3600\n";
    echo "   }\n\n";
} catch (Exception $e) {
    echo "❌ Fatal error: {$e->getMessage()}\n";
    echo "   File: {$e->getFile()}\n";
    echo "   Line: {$e->getLine()}\n";
}
