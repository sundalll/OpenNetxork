<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    // Поддержка обычного JSON ввода или Multipart Form Data
    $title = trim($_POST['title'] ?? '');
    $artist = trim($_POST['artist'] ?? '');
    $album = trim($_POST['album_name'] ?? '');
    $coverUrl = trim($_POST['cover_url'] ?? '');
    $audioUrl = trim($_POST['audio_url'] ?? '');

    // Если данные переданы как JSON
    if (empty($title) && empty($artist)) {
        $input = json_decode(file_get_contents('php://input'), true);
        $title = trim($input['title'] ?? '');
        $artist = trim($input['artist'] ?? '');
        $album = trim($input['album_name'] ?? '');
        $coverUrl = trim($input['cover_url'] ?? '');
        $audioUrl = trim($input['audio_url'] ?? '');
    }

    // Обработка загрузки музыкального файла (MP3 / WAV / FLAC)
    if (isset($_FILES['audio_file']) && $_FILES['audio_file']['error'] === UPLOAD_ERR_OK) {
        $fileTmp = $_FILES['audio_file']['tmp_name'];
        $fileName = $_FILES['audio_file']['name'];
        $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

        if (!in_array($ext, ['mp3', 'wav', 'flac'])) {
            Database::sendResponse(false, "Неподдерживаемый формат файла. Разрешены только MP3, WAV и FLAC.", null, 400);
        }

        $uploadDir = __DIR__ . '/../uploads/music/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $newFileName = 'track_' . time() . '_' . uniqid() . '.' . $ext;
        $destPath = $uploadDir . $newFileName;

        if (move_uploaded_file($fileTmp, $destPath)) {
            $audioUrl = 'http://46.53.128.120/uploads/music/' . $newFileName;
        }
    }

    // Обработка загрузки файла обложки
    if (isset($_FILES['cover_file']) && $_FILES['cover_file']['error'] === UPLOAD_ERR_OK) {
        $fileTmp = $_FILES['cover_file']['tmp_name'];
        $fileName = $_FILES['cover_file']['name'];
        $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

        $uploadDir = __DIR__ . '/../uploads/covers/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $newFileName = 'cover_' . time() . '_' . uniqid() . '.' . $ext;
        $destPath = $uploadDir . $newFileName;

        if (move_uploaded_file($fileTmp, $destPath)) {
            $coverUrl = 'http://46.53.128.120/uploads/covers/' . $newFileName;
        }
    }

    if (empty($title) || empty($artist) || empty($audioUrl)) {
        Database::sendResponse(false, "Укажите название трека, исполнителя и аудиофайл (MP3, WAV или FLAC)", null, 400);
    }

    $stmt = $pdo->prepare("
        INSERT INTO tracks (title, artist, duration_seconds, cover_url, audio_url, explicit)
        VALUES (?, ?, 180, ?, ?, 0)
    ");
    $stmt->execute([$title, $artist, $coverUrl, $audioUrl]);
    $trackId = $pdo->lastInsertId();

    $newTrack = [
        'id' => (int)$trackId,
        'title' => $title,
        'artist' => $artist,
        'duration_seconds' => 180,
        'cover_url' => $coverUrl,
        'audio_url' => $audioUrl,
        'album_name' => $album,
        'is_liked' => false,
        'explicit' => false
    ];

    Database::sendResponse(true, "Музыкальный трек успешно загружен!", $newTrack);
} else {
    Database::sendResponse(false, "Метод не поддерживается", null, 405);
}
