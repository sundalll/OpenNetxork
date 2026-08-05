<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();

$stmt = $pdo->prepare("
    SELECT v.id, v.title, v.description, v.thumbnail_url, v.video_url, v.duration_seconds, v.views_count, v.likes_count, v.created_at,
           u.id as user_id, u.username, u.first_name, u.last_name, u.avatar_url, u.is_verified
    FROM videos v
    JOIN users u ON v.user_id = u.id
    ORDER BY v.id DESC
");
$stmt->execute();
$videos = $stmt->fetchAll();

$result = array_map(function($v) {
    return [
        'id' => (int)$v['id'],
        'title' => $v['title'],
        'description' => $v['description'],
        'thumbnail_url' => $v['thumbnail_url'],
        'video_url' => $v['video_url'],
        'duration_seconds' => (int)$v['duration_seconds'],
        'views_count' => (int)$v['views_count'],
        'likes_count' => (int)$v['likes_count'],
        'is_liked' => false,
        'created_at_formatted' => date('d.m.Y H:i', strtotime($v['created_at'])),
        'author' => [
            'id' => (int)$v['user_id'],
            'username' => $v['username'],
            'first_name' => $v['first_name'],
            'last_name' => $v['last_name'],
            'avatar_url' => $v['avatar_url'],
            'is_verified' => (bool)$v['is_verified']
        ]
    ];
}, $videos);

Database::sendResponse(true, "Видео загружены", $result);
