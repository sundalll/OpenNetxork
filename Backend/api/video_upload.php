<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $userId = (int)($_POST['user_id'] ?? 1);
    $title = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $thumbnailUrl = trim($_POST['thumbnail_url'] ?? '');
    $videoUrl = trim($_POST['video_url'] ?? '');

    if (empty($title) && empty($description)) {
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = (int)($input['user_id'] ?? 1);
        $title = trim($input['title'] ?? '');
        $description = trim($input['description'] ?? '');
        $thumbnailUrl = trim($input['thumbnail_url'] ?? '');
        $videoUrl = trim($input['video_url'] ?? '');
    }

    // Загрузка видеофайла
    if (isset($_FILES['video_file']) && $_FILES['video_file']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = __DIR__ . '/../uploads/videos/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
        $ext = strtolower(pathinfo($_FILES['video_file']['name'], PATHINFO_EXTENSION));
        $fileName = 'video_' . time() . '_' . uniqid() . '.' . $ext;
        if (move_uploaded_file($_FILES['video_file']['tmp_name'], $uploadDir . $fileName)) {
            $videoUrl = 'http://46.53.128.120/uploads/videos/' . $fileName;
        }
    }

    if (empty($title) || empty($videoUrl)) {
        Database::sendResponse(false, "Укажите название видео и видеофайл / URL", null, 400);
    }

    if (empty($thumbnailUrl)) {
        $thumbnailUrl = "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=800&q=80";
    }

    $stmt = $pdo->prepare("
        INSERT INTO videos (user_id, title, description, thumbnail_url, video_url, duration_seconds)
        VALUES (?, ?, ?, ?, ?, 120)
    ");
    $stmt->execute([$userId, $title, $description, $thumbnailUrl, $videoUrl]);
    $videoId = $pdo->lastInsertId();

    Database::sendResponse(true, "Видео успешно загружено!", ['video_id' => (int)$videoId, 'video_url' => $videoUrl]);
}
