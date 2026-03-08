<?php
require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\Storage;

try {
    $command = Storage::disk('s3')->getClient()->getCommand('PutObject', [
        'Bucket' => config('filesystems.disks.s3.bucket'),
        'Key'    => 'test_presigned.jpg',
        'ContentType' => 'image/jpeg',
    ]);

    $signedUrl = (string) Storage::disk('s3')
        ->getClient()
        ->createPresignedRequest($command, '+5 minutes')
        ->getUri();

    echo "URL: " . $signedUrl . "\n";
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
