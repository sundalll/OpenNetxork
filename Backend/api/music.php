<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();

// Список загруженных музыкальных треков из БД
$stmt = $pdo->prepare("SELECT id, title, artist, duration_seconds, cover_url, audio_url, explicit FROM tracks ORDER BY id DESC");
$stmt->execute();
$tracks = $stmt->fetchAll();

$result = array_map(function($track) {
    return [
        'id' => (int)$track['id'],
        'title' => $track['title'],
        'artist' => $track['artist'],
        'duration_seconds' => (int)$track['duration_seconds'],
        'cover_url' => $track['cover_url'],
        'audio_url' => $track['audio_url'],
        'is_liked' => false,
        'explicit' => (bool)$track['explicit']
    ];
}, $tracks);

Database::sendResponse(true, "Реальные треки загружены", $result);
