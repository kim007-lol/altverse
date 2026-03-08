<?php
require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\Storage;
use Aws\S3\S3Client;

echo "Initializing S3 AWS Client to wipe R2 bucket...\n";

$client = Storage::disk('s3')->getClient();
$bucket = config('filesystems.disks.s3.bucket');

echo "Target Bucket: {$bucket}\n";

$isTruncated = true;
$marker = '';
$totalDeleted = 0;

try {
    while ($isTruncated) {
        $result = $client->listObjectsV2([
            'Bucket' => $bucket,
            'ContinuationToken' => $marker ?: null,
        ]);

        $contents = $result->get('Contents');

        if (empty($contents)) {
            echo "No more objects found.\n";
            break;
        }

        foreach ($contents as $object) {
            $key = $object['Key'];
            echo "Deleting: " . $key . " ... ";

            try {
                $client->deleteObject([
                    'Bucket' => $bucket,
                    'Key' => $key,
                ]);
                echo "OK\n";
                $totalDeleted++;
            } catch (\Exception $ex) {
                echo "Failed: " . $ex->getMessage() . "\n";
            }
        }

        $isTruncated = $result->get('IsTruncated');
        if ($isTruncated) {
            $marker = $result->get('NextContinuationToken');
        }
    }

    echo "Wipe complete! Total deleted: {$totalDeleted}.\n";
} catch (\Exception $e) {
    echo "An API Error occurred: " . $e->getMessage() . "\n";
}
