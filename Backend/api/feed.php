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

if ($method === 'GET') {
    $currentUserId = (int)($_GET['user_id'] ?? 1);
    $feedType = $_GET['feed_type'] ?? 'all';

    // Запрос ленты публикаций
    $stmt = $pdo->prepare("
        SELECT 
            p.id, p.user_id, p.text, p.image_url, p.audio_url, p.video_url,
            p.likes_count, p.reposts_count, p.comments_count, p.views_count, p.created_at,
            u.id as author_id, u.username, u.first_name, u.last_name, u.avatar_url, u.is_verified, u.status_text
        FROM posts p
        JOIN users u ON p.user_id = u.id
        ORDER BY p.created_at DESC
        LIMIT 100
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
                'status_text' => $row['status_text'] ?? '',
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

    Database::sendResponse(true, "Лента успешно загружена", $posts);

} elseif ($method === 'POST') {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);

    if (!is_array($input) || empty($input)) {
        $input = $_POST;
    }

    $userId = (int)($input['user_id'] ?? 1);
    $text = trim($input['text'] ?? '');
    $imageUrl = trim($input['image_url'] ?? '');

    if (empty($text)) {
        Database::sendResponse(false, "Текст поста не может быть пустым", null, 400);
    }

    // Авто-подбор живого пользователя если ID не найден
    $userCheck = $pdo->prepare("SELECT id FROM users WHERE id = ?");
    $userCheck->execute([$userId]);
    if (!$userCheck->fetch()) {
        $firstUser = $pdo->query("SELECT id FROM users ORDER BY id ASC LIMIT 1")->fetch();
        if ($firstUser) {
            $userId = (int)$firstUser['id'];
        }
    }

    $stmt = $pdo->prepare("INSERT INTO posts (user_id, text, image_url) VALUES (?, ?, ?)");
    $stmt->execute([$userId, $text, $imageUrl]);
    $postId = (int)$pdo->lastInsertId();

    // Получаем созданный пост вместе с автором
    $userStmt = $pdo->prepare("SELECT id, username, first_name, last_name, avatar_url, status_text, is_verified FROM users WHERE id = ?");
    $userStmt->execute([$userId]);
    $author = $userStmt->fetch();

    $newPost = [
        'id' => $postId,
        'author' => [
            'id' => (int)$author['id'],
            'username' => $author['username'],
            'first_name' => $author['first_name'],
            'last_name' => $author['last_name'],
            'avatar_url' => $author['avatar_url'],
            'status_text' => $author['status_text'] ?? '',
            'is_verified' => (bool)$author['is_verified'],
            'is_online' => true
        ],
        'text' => $text,
        'attachments' => !empty($imageUrl) ? [['id' => 'img_' . $postId, 'type' => 'image', 'url' => $imageUrl]] : [],
        'likes_count' => 0,
        'is_liked' => false,
        'reposts_count' => 0,
        'is_reposted' => false,
        'comments_count' => 0,
        'views_count' => 1,
        'created_at_formatted' => 'Только что'
    ];

    Database::sendResponse(true, "Пост успешно опубликован", $newPost);
}
