<?php
/**
 * Image Upload API (Products, Avatars & Rider Documents)
 * POST /api/upload.php
 * Accepts: Multipart form data with file field "image" OR JSON with "image_base64" and "folder"
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../helpers/response.php';

// Enable CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

$uploadDir = ROOT_PATH . '/uploads';
$folder = 'general';

if (isset($_POST['folder']) && in_array($_POST['folder'], ['products', 'categories', 'profiles', 'riders'])) {
    $folder = $_POST['folder'];
}

$targetDir = $uploadDir . '/' . $folder;
if (!is_dir($targetDir)) {
    mkdir($targetDir, 0755, true);
}

// 1. Check Multipart File Upload
if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
    $fileTmp  = $_FILES['image']['tmp_name'];
    $fileName = $_FILES['image']['name'];
    $fileSize = $_FILES['image']['size'];

    if ($fileSize > 10 * 1024 * 1024) {
        sendError('Image size exceeds 10MB limit', 422);
    }

    $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
    if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'])) {
        $ext = 'jpg';
    }

    $newFileName = 'img_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $destPath = $targetDir . '/' . $newFileName;

    if (move_uploaded_file($fileTmp, $destPath)) {
        $relPath = 'uploads/' . $folder . '/' . $newFileName;
        $fullUrl = SITE_URL . '/' . $relPath;
        sendSuccess([
            'path'     => $relPath,
            'url'      => $fullUrl,
            'filename' => $newFileName,
        ], 'Image uploaded successfully');
    } else {
        sendError('Failed to move uploaded file', 500);
    }
}

// 2. Check JSON / Base64 Payload
$input = getRequestData();
if (!empty($input['image_base64'])) {
    $base64 = $input['image_base64'];
    if (isset($input['folder']) && in_array($input['folder'], ['products', 'categories', 'profiles', 'riders'])) {
        $folder = $input['folder'];
        $targetDir = $uploadDir . '/' . $folder;
        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }
    }

    // Strip header if present
    if (preg_match('/^data:image\/(\w+);base64,/', $base64, $type)) {
        $base64 = substr($base64, strpos($base64, ',') + 1);
        $ext = strtolower($type[1]);
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'])) {
            $ext = 'jpg';
        }
    } else {
        $ext = 'jpg';
    }

    $decoded = base64_decode($base64);
    if (!$decoded) {
        sendError('Invalid base64 image data', 422);
    }

    $newFileName = 'img_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
    $destPath = $targetDir . '/' . $newFileName;

    if (file_put_contents($destPath, $decoded)) {
        $relPath = 'uploads/' . $folder . '/' . $newFileName;
        $fullUrl = SITE_URL . '/' . $relPath;
        sendSuccess([
            'path'     => $relPath,
            'url'      => $fullUrl,
            'filename' => $newFileName,
        ], 'Base64 image saved successfully');
    } else {
        sendError('Failed to write image file', 500);
    }
}

sendError('No image provided in request', 400);

