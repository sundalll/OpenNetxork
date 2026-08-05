<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = (int)($_GET['user_id'] ?? 1);
    $channelId = (int)($_GET['channel_id'] ?? 0);

    if ($channelId > 0) {
        // Детали одного канала
        $stmt = $pdo->prepare("SELECT * FROM channels WHERE id = ?");
        $stmt->execute([$channelId]);
        $channel = $stmt->fetch();

        if (!$channel) {
            Database::sendResponse(false, "Канал не найден", null, 404);
        }

        // Подписка текущего пользователя
        $subStmt = $pdo->prepare("SELECT 1 FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
        $subStmt->execute([$channelId, $userId]);
        $isSubscribed = (bool)$subStmt->fetch();

        // Посты канала
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
            'user_id' => (int)$channel['user_id'],
            'name' => $channel['name'],
            'description' => $channel['description'],
            'avatar_url' => $channel['avatar_url'],
            'cover_url' => $channel['cover_url'],
            'category' => $channel['category'],
            'subscribers_count' => (int)$channel['subscribers_count'],
            'is_verified' => (bool)$channel['is_verified'],
            'is_subscribed' => $isSubscribed,
            'posts' => $formattedPosts
        ];

        Database::sendResponse(true, "Данные канала получены", $result);
    } else {
        // Список всех каналов
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
                'user_id' => (int)$c['user_id'],
                'name' => $c['name'],
                'description' => $c['description'],
                'avatar_url' => $c['avatar_url'],
                'cover_url' => $c['cover_url'],
                'category' => $c['category'],
                'subscribers_count' => (int)$c['subscribers_count'],
                'is_verified' => (bool)$c['is_verified'],
                'is_subscribed' => (bool)$c['is_subscribed']
            ];
        }, $channels);

        Database::sendResponse(true, "Список каналов получен", $result);
    }

} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $input['action'] ?? $_POST['action'] ?? 'subscribe';
    $userId = (int)($input['user_id'] ?? $_POST['user_id'] ?? 1);
    $channelId = (int)($input['channel_id'] ?? $_POST['channel_id'] ?? 0);

    if ($action === 'create') {
        $name = trim($input['name'] ?? $_POST['name'] ?? '');
        $description = trim($input['description'] ?? $_POST['description'] ?? '');
        $category = trim($input['category'] ?? $_POST['category'] ?? 'Паблик');
        $avatarUrl = trim($input['avatar_url'] ?? $_POST['avatar_url'] ?? '');
        $coverUrl = trim($input['cover_url'] ?? $_POST['cover_url'] ?? '');

        if (empty($name)) {
            Database::sendResponse(false, "Укажите название канала", null, 400);
        }

        if (empty($avatarUrl)) {
            $avatarUrl = "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=400&q=80";
        }

        $stmt = $pdo->prepare("
            INSERT INTO channels (user_id, name, description, category, avatar_url, cover_url, subscribers_count)
            VALUES (?, ?, ?, ?, ?, ?, 1)
        ");
        $stmt->execute([$userId, $name, $description, $category, $avatarUrl, $coverUrl]);
        $newChannelId = (int)$pdo->lastInsertId();

        // Автор сразу становится подписчиком своего канала
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

        // Проверка подписки
        $check = $pdo->prepare("SELECT 1 FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
        $check->execute([$channelId, $userId]);
        $exists = $check->fetch();

        if ($exists) {
            // Отписка
            $unsub = $pdo->prepare("DELETE FROM channel_subscribers WHERE channel_id = ? AND user_id = ?");
            $unsub->execute([$channelId, $userId]);

            $dec = $pdo->prepare("UPDATE channels SET subscribers_count = GREATEST(0, subscribers_count - 1) WHERE id = ?");
            $dec->execute([$channelId]);

            Database::sendResponse(true, "Вы отписались от канала", ['is_subscribed' => false]);
        } else {
            // Подписка
            $sub = $pdo->prepare("INSERT INTO channel_subscribers (channel_id, user_id) VALUES (?, ?)");
            $sub->execute([$channelId, $userId]);

            $inc = $pdo->prepare("UPDATE channels SET subscribers_count = subscribers_count + 1 WHERE id = ?");
            $inc->execute([$channelId]);

            Database::sendResponse(true, "Вы успешно подписались на канал!", ['is_subscribed' => true]);
        }

    } elseif ($action === 'create_post') {
        $text = trim($input['text'] ?? $_POST['text'] ?? '');
        $imageUrl = trim($input['image_url'] ?? $_POST['image_url'] ?? '');

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
