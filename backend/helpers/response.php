<?php
/**
 * Unified JSON Response & CORS Handler
 */

// Enable CORS for mobile apps and web admin panels
function handleCors() {
    $origin = isset($_SERVER['HTTP_ORIGIN']) ? $_SERVER['HTTP_ORIGIN'] : '*';
    header("Access-Control-Allow-Origin: {$origin}");
    header("Access-Control-Allow-Credentials: true");
    header("Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control");
    header("Content-Type: application/json; charset=UTF-8");

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        echo json_encode(['status' => 'ok', 'message' => 'CORS preflight allowed']);
        exit();
    }
}

// Auto-run CORS on include
handleCors();

/**
 * Send Standard JSON Response
 */
function sendResponse($success, $data = null, $message = '', $statusCode = 200) {
    http_response_code($statusCode);
    $response = [
        'success'   => (bool)$success,
        'message'   => $message,
        'timestamp' => date('c')
    ];

    if ($data !== null) {
        $response['data'] = $data;
    }

    echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * Send JSON Success
 */
function sendSuccess($data = null, $message = 'Success', $statusCode = 200) {
    sendResponse(true, $data, $message, $statusCode);
}

/**
 * Send JSON Error
 */
function sendError($message = 'An error occurred', $statusCode = 400, $data = null) {
    sendResponse(false, $data, $message, $statusCode);
}

/**
 * Read JSON / Form Input cleanly from POST / PUT / PATCH
 */
function getRequestData() {
    $contentType = isset($_SERVER['CONTENT_TYPE']) ? trim($_SERVER['CONTENT_TYPE']) : '';
    
    // Check if JSON body
    if (stripos($contentType, 'application/json') !== false || empty($_POST)) {
        $raw = file_get_contents('php://input');
        if (!empty($raw)) {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                return array_merge($_REQUEST, $decoded);
            }
        }
    }

    return $_REQUEST;
}
