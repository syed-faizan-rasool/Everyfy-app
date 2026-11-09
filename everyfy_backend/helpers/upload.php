<?php
/**
 * File Upload Helper
 */

require_once __DIR__ . '/../config/config.php';

class UploadHelper {
    private static $allowedMimeTypes = [
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/webp' => 'webp',
        'image/gif'  => 'gif'
    ];
    private static $maxFileSize = 5 * 1024 * 1024; // 5 MB

    /**
     * Upload an image file from $_FILES
     * @param string $field Form input field name
     * @param string $subDir Subdirectory under uploads/ (e.g. 'products', 'profiles')
     * @return array [success => bool, url => string, path => string, error => string]
     */
    public static function uploadImage($field, $subDir = 'products') {
        if (!isset($_FILES[$field]) || $_FILES[$field]['error'] !== UPLOAD_ERR_OK) {
            return ['success' => false, 'error' => 'No file uploaded or upload error code: ' . ($_FILES[$field]['error'] ?? 'empty')];
        }

        $file = $_FILES[$field];

        // Check file size
        if ($file['size'] > self::$maxFileSize) {
            return ['success' => false, 'error' => 'File size exceeds limit of 5MB'];
        }

        // Validate MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        if (!array_key_exists($mimeType, self::$allowedMimeTypes)) {
            return ['success' => false, 'error' => 'Only JPG, PNG, WEBP, and GIF images are supported'];
        }

        $ext = self::$allowedMimeTypes[$mimeType];
        $targetDir = UPLOAD_PATH . '/' . trim($subDir, '/');

        if (!is_dir($targetDir)) {
            mkdir($targetDir, 0755, true);
        }

        $filename = uniqid('img_', true) . '.' . $ext;
        $destination = $targetDir . '/' . $filename;

        if (move_uploaded_file($file['tmp_name'], $destination)) {
            $url = UPLOAD_URL . '/' . trim($subDir, '/') . '/' . $filename;
            return [
                'success'  => true,
                'filename' => $filename,
                'path'     => $destination,
                'url'      => $url
            ];
        }

        return ['success' => false, 'error' => 'Failed to save uploaded file to destination directory'];
    }
}
