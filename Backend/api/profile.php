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
        'is_online' => true
    ];

    Database::sendResponse(true, "Профиль получен", $user);

} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($input['user_id'] ?? $_POST['user_id'] ?? 1);
    $statusText = $input['status_text'] ?? $_POST['status_text'] ?? null;
    $avatarUrl = $input['avatar_url'] ?? $_POST['avatar_url'] ?? null;
    $coverUrl = $input['cover_url'] ?? $_POST['cover_url'] ?? null;
    $bio = $input['bio'] ?? $_POST['bio'] ?? null;

    // Обработка загрузки нового аватара файлом
    if (isset($_FILES['avatar_file']) && $_FILES['avatar_file']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = __DIR__ . '/../uploads/avatars/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
        $fileName = 'avatar_' . $userId . '_' . time() . '.jpg';
        if (move_uploaded_file($_FILES['avatar_file']['tmp_name'], $uploadDir . $fileName)) {
            $avatarUrl = 'http://46.53.128.120/uploads/avatars/' . $fileName;
        }
    }

    // Обработка загрузки новой обложки файлом
    if (isset($_FILES['cover_file']) && $_FILES['cover_file']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = __DIR__ . '/../uploads/covers/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
        $fileName = 'cover_' . $userId . '_' . time() . '.jpg';
        if (move_uploaded_file($_FILES['cover_file']['tmp_name'], $uploadDir . $fileName)) {
            $coverUrl = 'http://46.53.128.120/uploads/covers/' . $fileName;
        }
    }

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
