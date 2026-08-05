<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

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
    $userId = (int)($_GET['user_id'] ?? 1);
    $channelId = (int)($_GET['channel_id'] ?? 0);

    if ($channelId > 0) {
        $stmt = $pdo->prepare("SELECT * FROM channels WHERE id = ?");
        $stmt->execute([$channelId]);
        $channel = $stmt->fetch();

        if (!$channel) {
            Database::sendResponse(false, "Канал не найден", null, 404);
        }

        $subStmt = $pdo->prepare("SELECT 1 FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
        $subStmt->execute([$channelId, $userId]);
        $isSubscribed = (bool)$subStmt->fetch();

        $postsStmt = $pdo->prepare("SELECT * FROM channel_posts WHERE channel_id = ? ORDER BY id DESC");
        $postsStmt->execute([$channelId]);
        $posts = $postsStmt->fetchAll();

        $formattedPosts = array_map(function($p) {
            return [
                'id' => (int)$p['id'],
                'channel_id' => (int)$p['channel_id'],
                'text' => $p['text'],
                'image_url' => $p['image_url'],
                'likes_count' => (int)$p['likes_count'],
                'views_count' => (int)$p['views_count'],
                'created_at_formatted' => date('d.m.Y H:i', strtotime($p['created_at']))
            ];
        }, $posts);

        $result = [
            'id' => (int)$channel['id'],
            'user_id' => (int)($channel['owner_id'] ?? 1),
            'name' => $channel['name'],
            'description' => $channel['description'] ?? '',
            'avatar_url' => $channel['avatar_url'],
            'cover_url' => $channel['cover_url'],
            'category' => $channel['category'] ?? 'Паблик',
            'subscribers_count' => (int)$channel['subscribers_count'],
            'is_verified' => (bool)$channel['is_verified'],
            'is_subscribed' => $isSubscribed,
            'posts' => $formattedPosts
        ];

        Database::sendResponse(true, "Данные канала получены", $result);
    } else {
        $stmt = $pdo->prepare("
            SELECT c.*,
                   IF(cs.user_id IS NOT NULL, 1, 0) as is_subscribed
            FROM channels c
            LEFT JOIN channel_subscribers cs ON c.id = cs.channel_id AND cs.user_id = ?
            ORDER BY c.subscribers_count DESC, c.id DESC
        ");
        $stmt->execute([$userId]);
        $channels = $stmt->fetchAll();

        $result = array_map(function($c) {
            return [
                'id' => (int)$c['id'],
                'user_id' => (int)($c['owner_id'] ?? 1),
                'name' => $c['name'],
                'description' => $c['description'] ?? '',
                'avatar_url' => $c['avatar_url'],
                'cover_url' => $c['cover_url'],
                'category' => $c['category'] ?? 'Паблик',
                'subscribers_count' => (int)$c['subscribers_count'],
                'is_verified' => (bool)$c['is_verified'],
                'is_subscribed' => (bool)$c['is_subscribed']
            ];
        }, $channels);

        Database::sendResponse(true, "Список каналов получен", $result);
    }

} else {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);

    if (!is_array($input) || empty($input)) {
        $input = $_POST;
    }

    $action = $input['action'] ?? $_GET['action'] ?? 'create';
    $userId = (int)($input['user_id'] ?? $_GET['user_id'] ?? 1);
    $channelId = (int)($input['channel_id'] ?? $_GET['channel_id'] ?? 0);

    // Валидация подбора действующего пользователя
    $userCheck = $pdo->prepare("SELECT id FROM users WHERE id = ?");
    $userCheck->execute([$userId]);
    if (!$userCheck->fetch()) {
        $firstUser = $pdo->query("SELECT id FROM users ORDER BY id ASC LIMIT 1")->fetch();
        if ($firstUser) {
            $userId = (int)$firstUser['id'];
        }
    }

    if ($action === 'create') {
        $name = trim($input['name'] ?? $_GET['name'] ?? '');
        $description = trim($input['description'] ?? $_GET['description'] ?? '');
        $category = trim($input['category'] ?? $_GET['category'] ?? 'Паблик');
        $avatarUrl = trim($input['avatar_url'] ?? $_GET['avatar_url'] ?? '');
        $coverUrl = trim($input['cover_url'] ?? $_GET['cover_url'] ?? '');

        if (empty($name)) {
            Database::sendResponse(false, "Укажите название канала", null, 400);
        }

        if (empty($avatarUrl)) {
            $avatarUrl = "http://46.53.128.120/Logo/murlika.png";
        }

        $stmt = $pdo->prepare("
            INSERT INTO channels (owner_id, name, description, category, avatar_url, cover_url, subscribers_count)
            VALUES (?, ?, ?, ?, ?, ?, 1)
        ");
        $stmt->execute([$userId, $name, $description, $category, $avatarUrl, $coverUrl]);
        $newChannelId = (int)$pdo->lastInsertId();

        $subStmt = $pdo->prepare("INSERT IGNORE INTO channel_subscribers (channel_id, user_id) VALUES (?, ?)");
        $subStmt->execute([$newChannelId, $userId]);

        $newChannel = [
            'id' => $newChannelId,
            'user_id' => $userId,
            'name' => $name,
            'description' => $description,
            'category' => $category,
            'avatar_url' => $avatarUrl,
            'cover_url' => $coverUrl,
            'subscribers_count' => 1,
            'is_verified' => false,
            'is_subscribed' => true
        ];

        Database::sendResponse(true, "Канал успешно создан!", $newChannel);

    } elseif ($action === 'toggle_subscribe') {
        if ($channelId <= 0) {
            Database::sendResponse(false, "Некорректный ID канала", null, 400);
        }

        $check = $pdo->prepare("SELECT 1 FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
        $check->execute([$channelId, $userId]);
        $exists = $check->fetch();

        if ($exists) {
            $unsub = $pdo->prepare("DELETE FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
            $unsub->execute([$channelId, $userId]);

            $dec = $pdo->prepare("UPDATE channels SET subscribers_count = GREATEST(0, subscribers_count - 1) WHERE id = ?");
            $dec->execute([$channelId]);

            Database::sendResponse(true, "Вы отписались от канала", ['is_subscribed' => false]);
        } else {
            $sub = $pdo->prepare("INSERT INTO channel_subscribers (channel_id, user_id) VALUES (?, ?)");
            $sub->execute([$channelId, $userId]);

            $inc = $pdo->prepare("UPDATE channels SET subscribers_count = subscribers_count + 1 WHERE id = ?");
            $inc->execute([$channelId]);

            Database::sendResponse(true, "Вы успешно подписались на канал!", ['is_subscribed' => true]);
        }

    } elseif ($action === 'create_post') {
        $text = trim($input['text'] ?? '');
        $imageUrl = trim($input['image_url'] ?? '');

        if ($channelId <= 0 || empty($text)) {
            Database::sendResponse(false, "Укажите ID канала и текст записи", null, 400);
        }

        $stmt = $pdo->prepare("INSERT INTO channel_posts (channel_id, text, image_url) VALUES (?, ?, ?)");
        $stmt->execute([$channelId, $text, $imageUrl]);
        $postId = (int)$pdo->lastInsertId();

        $postData = [
            'id' => $postId,
            'channel_id' => $channelId,
            'text' => $text,
            'image_url' => $imageUrl,
            'likes_count' => 0,
            'views_count' => 1,
            'created_at_formatted' => 'Только что'
        ];

        Database::sendResponse(true, "Запись опубликована в канале!", $postData);
    }
}

Database::sendResponse(false, "Неизвестное действие", null, 400);
