<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if (isset($_SERVER['REQUEST_METHOD']) && strtoupper($_SERVER['REQUEST_METHOD']) === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

if ($method === 'POST') {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);

    if (!is_array($input) || empty($input)) {
        $input = $_POST;
    }

    $title = trim($input['title'] ?? '');
    $artist = trim($input['artist'] ?? '');
    $album = trim($input['album_name'] ?? '');
    $coverUrl = trim($input['cover_url'] ?? '');
    $audioUrl = trim($input['audio_url'] ?? '');

    if (empty($title) || empty($artist) || empty($audioUrl)) {
        Database::sendResponse(false, "Укажите название трека, исполнителя и аудиофайл", null, 400);
    }

    $stmt = $pdo->prepare("
        INSERT INTO tracks (title, artist, duration_seconds, cover_url, audio_url, explicit)
        VALUES (?, ?, 180, ?, ?, 0)
    ");
    $stmt->execute([$title, $artist, $coverUrl, $audioUrl]);
    $trackId = (int)$pdo->lastInsertId();

    $newTrack = [
        'id' => $trackId,
        'title' => $title,
        'artist' => $artist,
        'duration_seconds' => 180,
        'duration_formatted' => '3:00',
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
