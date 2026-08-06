<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = (int)($_GET['user_id'] ?? 1);

    $stmt = $pdo->prepare("SELECT id, username, first_name, last_name, avatar_url, cover_url, status_text, is_verified, followers_count, following_count, bio FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $row = $stmt->fetch();

    if (!$row) {
        Database::sendResponse(false, "Пользователь не найден", null, 404);
    }

    // Загрузка всех постов пользователя на его стену
    $postStmt = $pdo->prepare("
        SELECT p.id, p.user_id, p.text, p.image_url, p.audio_url, p.video_url,
               p.likes_count, p.reposts_count, p.comments_count, p.views_count, p.created_at
        FROM posts p
        WHERE p.user_id = ?
        ORDER BY p.created_at DESC
    ");
    $postStmt->execute([$userId]);
    $postRows = $postStmt->fetchAll();

    $userPosts = [];
    foreach ($postRows as $p) {
        $attachments = [];
        if (!empty($p['image_url'])) {
            $attachments[] = ['id' => 'img_' . $p['id'], 'type' => 'image', 'url' => $p['image_url']];
        }
        $userPosts[] = [
            'id' => (int)$p['id'],
            'author' => [
                'id' => (int)$row['id'],
                'username' => $row['username'],
                'first_name' => $row['first_name'],
                'last_name' => $row['last_name'],
                'avatar_url' => $row['avatar_url'],
                'is_verified' => (bool)$row['is_verified'],
                'followers_count' => (int)$row['followers_count'],
                'following_count' => (int)$row['following_count'],
                'is_online' => true
            ],
            'text' => $p['text'],
            'attachments' => $attachments,
            'likes_count' => (int)($p['likes_count'] ?? 0),
            'is_liked' => false,
            'reposts_count' => (int)($p['reposts_count'] ?? 0),
            'is_reposted' => false,
            'comments_count' => (int)($p['comments_count'] ?? 0),
            'views_count' => (int)($p['views_count'] ?? 0),
            'created_at_formatted' => date('d.m.Y в H:i', strtotime($p['created_at']))
        ];
    }

    $user = [
        'id' => (int)$row['id'],
        'username' => $row['username'],
        'first_name' => $row['first_name'],
        'last_name' => $row['last_name'],
        'avatar_url' => $row['avatar_url'],
        'cover_url' => $row['cover_url'],
        'status_text' => $row['status_text'],
        'is_verified' => (bool)$row['is_verified'],
        'followers_count' => (int)$row['followers_count'],
        'following_count' => (int)$row['following_count'],
        'bio' => $row['bio'],
        'is_online' => true,
        'posts' => $userPosts
    ];

    Database::sendResponse(true, "Профиль получен", $user);

} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($input['user_id'] ?? $_POST['user_id'] ?? 1);
    $statusText = $input['status_text'] ?? $_POST['status_text'] ?? null;
    $avatarUrl = $input['avatar_url'] ?? $_POST['avatar_url'] ?? null;
    $coverUrl = $input['cover_url'] ?? $_POST['cover_url'] ?? null;
    $bio = $input['bio'] ?? $_POST['bio'] ?? null;

    $fields = [];
    $params = [];

    if ($statusText !== null) { $fields[] = "status_text = ?"; $params[] = $statusText; }
    if ($avatarUrl !== null) { $fields[] = "avatar_url = ?"; $params[] = $avatarUrl; }
    if ($coverUrl !== null) { $fields[] = "cover_url = ?"; $params[] = $coverUrl; }
    if ($bio !== null) { $fields[] = "bio = ?"; $params[] = $bio; }

    if (!empty($fields)) {
        $params[] = $userId;
        $sql = "UPDATE users SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
    }

    Database::sendResponse(true, "Профиль успешно обновлен!", [
        'avatar_url' => $avatarUrl,
        'cover_url' => $coverUrl,
        'status_text' => $statusText,
        'bio' => $bio
    ]);
}
