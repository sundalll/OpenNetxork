<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../db.php';

$uploadDir = __DIR__ . '/../uploads/';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$baseUrl = "https://myrlika.bond/uploads/";

// 1. Из файлов ($_FILES)
if (!empty($_FILES['file'])) {
    $file = $_FILES['file'];
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (empty($ext)) $ext = 'jpg';

    $filename = uniqid('file_', true) . '.' . $ext;
    $targetPath = $uploadDir . $filename;

    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        Database::sendResponse(true, "Файл успешно загружен!", ['url' => $baseUrl . $filename]);
    } else {
        Database::sendResponse(false, "Не удалось сохранить файл на сервере", null, 500);
    }
}

// 2. Из base64 в JSON
$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);

if (!empty($input['base64_data'])) {
    $base64Str = $input['base64_data'];
    $ext = $input['extension'] ?? 'jpg';

    if (preg_match('/^data:image\/(\w+);base64,/', $base64Str, $type)) {
        $base64Str = substr($base64Str, strpos($base64Str, ',') + 1);
        $ext = strtolower($type[1]);
    }

    $data = base64_decode($base64Str);
    if ($data === false) {
        Database::sendResponse(false, "Некорректные данные base64", null, 400);
    }

    $filename = uniqid('img_', true) . '.' . $ext;
    $targetPath = $uploadDir . $filename;

    if (file_put_contents($targetPath, $data)) {
        Database::sendResponse(true, "Изображение успешно загружено!", ['url' => $baseUrl . $filename]);
    } else {
        Database::sendResponse(false, "Ошибка сохранения файла", null, 500);
    }
}

Database::sendResponse(false, "Файл не передан", null, 400);
