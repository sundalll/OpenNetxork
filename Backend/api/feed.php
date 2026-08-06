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

// Логирование любого действия в базу данных MariaDB
function logUserAction($pdo, $userId, $actionType, $details = '') {
    try {
        $stmt = $pdo->prepare("INSERT INTO user_activity_logs (user_id, action_type, details) VALUES (?, ?, ?)");
        $stmt->execute([$userId, $actionType, is_array($details) ? json_encode($details, JSON_UNESCAPED_UNICODE) : $details]);
    } catch (Exception $e) {}
}

if ($method === 'GET') {
    $action = $_GET['action'] ?? 'feed';
    $postId = (int)($_GET['post_id'] ?? 0);

    if ($action === 'comments' && $postId > 0) {
        try {
            $stmt = $pdo->prepare("
                SELECT c.id, c.post_id, c.text, c.created_at,
                       u.id as author_id, u.username, u.first_name, u.last_name, u.avatar_url, u.is_verified
                FROM post_comments c
                LEFT JOIN users u ON c.user_id = u.id
                WHERE c.post_id = ?
                ORDER BY c.id ASC
            ");
            $stmt->execute([$postId]);
            $comments = $stmt->fetchAll();
        } catch (Exception $e) {
            $comments = [];
        }

        $result = array_map(function($c) {
            return [
                'id' => (int)$c['id'],
                'post_id' => (int)$c['post_id'],
                'author' => [
                    'id' => (int)($c['author_id'] ?? 1),
                    'username' => $c['username'] ?? 'user',
                    'first_name' => $c['first_name'] ?? 'Пользователь',
                    'last_name' => $c['last_name'] ?? '',
                    'avatar_url' => !empty($c['avatar_url']) ? $c['avatar_url'] : 'https://myrlika.bond/Logo/murlika.png',
                    'is_verified' => (bool)($c['is_verified'] ?? false),
                    'followers_count' => 0,
                    'following_count' => 0,
                    'is_online' => true
                ],
                'text' => $c['text'],
                'created_at_formatted' => date('d.m.Y в H:i', strtotime($c['created_at']))
            ];
        }, $comments);

        Database::sendResponse(true, "Комментарии загружены", $result);
    }

    // Запрос ленты новостей из базы данных MariaDB с отказоустойчивым try-catch
    $rows = [];
    try {
        $stmt = $pdo->prepare("
            SELECT 
                p.id, p.user_id, p.text, p.image_url, p.audio_url, p.video_url,
                p.likes_count, p.reposts_count, p.comments_count, p.views_count, p.created_at,
                u.id as author_id, u.username, u.first_name, u.last_name, u.avatar_url, u.is_verified, u.status_text
            FROM posts p
            LEFT JOIN users u ON p.user_id = u.id
            ORDER BY p.created_at DESC
            LIMIT 100
        ");
        $stmt->execute();
        $rows = $stmt->fetchAll();
    } catch (Exception $e) {
        try {
            $stmt = $pdo->prepare("SELECT * FROM posts ORDER BY id DESC LIMIT 100");
            $stmt->execute();
            $rows = $stmt->fetchAll();
        } catch (Exception $e2) {
            $rows = [];
        }
    }

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

        $authorId = (int)($row['author_id'] ?? $row['user_id'] ?? 1);
        $username = !empty($row['username']) ? $row['username'] : 'user_' . $authorId;
        $firstName = !empty($row['first_name']) ? $row['first_name'] : 'Пользователь';
        $lastName = $row['last_name'] ?? '';
        $avatarUrl = !empty($row['avatar_url']) ? $row['avatar_url'] : 'https://myrlika.bond/Logo/murlika.png';

        $posts[] = [
            'id' => (int)$row['id'],
            'author' => [
                'id' => $authorId,
                'username' => $username,
                'first_name' => $firstName,
                'last_name' => $lastName,
                'avatar_url' => $avatarUrl,
                'status_text' => $row['status_text'] ?? '',
                'is_verified' => (bool)($row['is_verified'] ?? false),
                'followers_count' => 0,
                'following_count' => 0,
                'is_online' => true
            ],
            'text' => $row['text'],
            'attachments' => $attachments,
            'likes_count' => (int)($row['likes_count'] ?? 0),
            'is_liked' => false,
            'reposts_count' => (int)($row['reposts_count'] ?? 0),
            'is_reposted' => false,
            'comments_count' => (int)($row['comments_count'] ?? 0),
            'views_count' => (int)($row['views_count'] ?? 0),
            'created_at_formatted' => !empty($row['created_at']) ? date('d.m.Y в H:i', strtotime($row['created_at'])) : 'Только что'
        ];
    }

    Database::sendResponse(true, "Лента успешно загружена из MariaDB", $posts);

} elseif ($method === 'POST') {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);

    if (!is_array($input) || empty($input)) {
        $input = $_POST;
    }

    $action = $input['action'] ?? 'create_post';
    $userId = (int)($input['user_id'] ?? 1);
    $text = trim($input['text'] ?? '');
    $imageUrl = trim($input['image_url'] ?? '');
    $postId = (int)($input['post_id'] ?? 0);

    $userCheck = $pdo->prepare("SELECT id FROM users WHERE id = ?");
    $userCheck->execute([$userId]);
    if (!$userCheck->fetch()) {
        $firstUser = $pdo->query("SELECT id FROM users ORDER BY id ASC LIMIT 1")->fetch();
        if ($firstUser) {
            $userId = (int)$firstUser['id'];
        }
    }

    if ($action === 'create_comment' || $action === 'comment') {
        if ($postId <= 0 || empty($text)) {
            Database::sendResponse(false, "Укажите ID поста и текст комментария", null, 400);
        }

        $stmt = $pdo->prepare("INSERT INTO post_comments (post_id, user_id, text) VALUES (?, ?, ?)");
        $stmt->execute([$postId, $userId, $text]);
        $commentId = (int)$pdo->lastInsertId();

        $inc = $pdo->prepare("UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?");
        $inc->execute([$postId]);

        logUserAction($pdo, $userId, 'create_comment', ['post_id' => $postId, 'comment_id' => $commentId, 'text' => $text]);

        $uStmt = $pdo->prepare("SELECT id, username, first_name, last_name, avatar_url, is_verified FROM users WHERE id = ?");
        $uStmt->execute([$userId]);
        $u = $uStmt->fetch();

        $newComment = [
            'id' => $commentId,
            'post_id' => $postId,
            'author' => [
                'id' => (int)($u['id'] ?? $userId),
                'username' => $u['username'] ?? 'user',
                'first_name' => $u['first_name'] ?? 'Пользователь',
                'last_name' => $u['last_name'] ?? '',
                'avatar_url' => !empty($u['avatar_url']) ? $u['avatar_url'] : 'https://myrlika.bond/Logo/murlika.png',
                'is_verified' => (bool)($u['is_verified'] ?? false),
                'followers_count' => 0,
                'following_count' => 0,
                'is_online' => true
            ],
            'text' => $text,
            'created_at_formatted' => 'Только что'
        ];

        Database::sendResponse(true, "Комментарий успешно добавлен", $newComment);

    } elseif ($action === 'repost') {
        if ($postId <= 0) {
            Database::sendResponse(false, "Укажите ID поста", null, 400);
        }

        $stmt = $pdo->prepare("INSERT INTO post_reposts (post_id, user_id) VALUES (?, ?)");
        $stmt->execute([$postId, $userId]);

        $inc = $pdo->prepare("UPDATE posts SET reposts_count = reposts_count + 1 WHERE id = ?");
        $inc->execute([$postId]);

        logUserAction($pdo, $userId, 'repost', ['post_id' => $postId]);

        Database::sendResponse(true, "Пост опубликован на вашей странице", ['is_reposted' => true]);

    } else {
        if (empty($text) && empty($imageUrl)) {
            Database::sendResponse(false, "Текст поста или изображение не могут быть пустыми", null, 400);
        }

        $stmt = $pdo->prepare("INSERT INTO posts (user_id, text, image_url) VALUES (?, ?, ?)");
        $stmt->execute([$userId, $text, $imageUrl]);
        $newPostId = (int)$pdo->lastInsertId();

        logUserAction($pdo, $userId, 'create_post', ['post_id' => $newPostId, 'text' => $text, 'image_url' => $imageUrl]);

        $userStmt = $pdo->prepare("SELECT id, username, first_name, last_name, avatar_url, status_text, is_verified FROM users WHERE id = ?");
        $userStmt->execute([$userId]);
        $author = $userStmt->fetch();

        $newPost = [
            'id' => $newPostId,
            'author' => [
                'id' => (int)($author['id'] ?? $userId),
                'username' => $author['username'] ?? 'user',
                'first_name' => $author['first_name'] ?? 'Пользователь',
                'last_name' => $author['last_name'] ?? '',
                'avatar_url' => !empty($author['avatar_url']) ? $author['avatar_url'] : 'https://myrlika.bond/Logo/murlika.png',
                'status_text' => $author['status_text'] ?? '',
                'is_verified' => (bool)($author['is_verified'] ?? false),
                'followers_count' => 0,
                'following_count' => 0,
                'is_online' => true
            ],
            'text' => $text,
            'attachments' => !empty($imageUrl) ? [['id' => 'img_' . $newPostId, 'type' => 'image', 'url' => $imageUrl]] : [],
            'likes_count' => 0,
            'is_liked' => false,
            'reposts_count' => 0,
            'is_reposted' => false,
            'comments_count' => 0,
            'views_count' => 1,
            'created_at_formatted' => 'Только что'
        ];

        Database::sendResponse(true, "Пост успешно опубликован и сохранен в БД!", $newPost);
    }
}
