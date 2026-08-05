<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Получение ленты новостей
    $stmt = $pdo->prepare("
        SELECT 
            p.id, p.text, p.image_url, p.audio_url, p.video_url,
            p.likes_count, p.reposts_count, p.comments_count, p.views_count, p.created_at,
            u.id as author_id, u.username, u.first_name, u.last_name, u.avatar_url, u.is_verified, u.status_text
        FROM posts p
        JOIN users u ON p.user_id = u.id
        ORDER BY p.created_at DESC
        LIMIT 50
    ");
    $stmt->execute();
    $rows = $stmt->fetchAll();

    $posts = [];
    foreach ($rows as $row) {
        $attachments = [];
        if (!empty($row['image_url'])) {
            $attachments[] = [
                'id' => 'img_' . $row['id'],
                'type' => 'image',
                'url' => $row['image_url']
            ];
        }
        if (!empty($row['audio_url'])) {
            $attachments[] = [
                'id' => 'aud_' . $row['id'],
                'type' => 'audio',
                'url' => $row['audio_url'],
                'title' => 'Аудиозапись',
                'subtitle' => 'Исполнитель'
            ];
        }

        $posts[] = [
            'id' => (int)$row['id'],
            'author' => [
                'id' => (int)$row['author_id'],
                'username' => $row['username'],
                'first_name' => $row['first_name'],
                'last_name' => $row['last_name'],
                'avatar_url' => $row['avatar_url'],
                'status_text' => $row['status_text'],
                'is_verified' => (bool)$row['is_verified'],
                'is_online' => true
            ],
            'text' => $row['text'],
            'attachments' => $attachments,
            'likes_count' => (int)$row['likes_count'],
            'is_liked' => false,
            'reposts_count' => (int)$row['reposts_count'],
            'is_reposted' => false,
            'comments_count' => (int)$row['comments_count'],
            'views_count' => (int)$row['views_count'],
            'created_at_formatted' => date('d.m.Y в H:i', strtotime($row['created_at']))
        ];
    }

    Database::sendResponse(true, "Feed loaded successfully", $posts);
} elseif ($method === 'POST') {
    // Создание нового поста
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = $input['user_id'] ?? 1;
    $text = trim($input['text'] ?? '');
    $imageUrl = $input['image_url'] ?? null;

    if (empty($text)) {
        Database::sendResponse(false, "Текст поста не может быть пустым", null, 400);
    }

    $stmt = $pdo->prepare("INSERT INTO posts (user_id, text, image_url) VALUES (?, ?, ?)");
    $stmt->execute([$userId, $text, $imageUrl]);
    $postId = $pdo->lastInsertId();

    Database::sendResponse(true, "Пост успешно опубликован", ['post_id' => (int)$postId]);
}
