<?php
require_once __DIR__ . '/../db.php';

$pdo = Database::getInstance();
$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    Database::sendResponse(false, "Метод не поддерживается", null, 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? $_POST['action'] ?? 'login';

if ($action === 'register') {
    $username = trim($input['username'] ?? $_POST['username'] ?? '');
    $email = trim($input['email'] ?? $_POST['email'] ?? '');
    $password = trim($input['password'] ?? $_POST['password'] ?? '');
    $firstName = trim($input['first_name'] ?? $_POST['first_name'] ?? '');
    $lastName = trim($input['last_name'] ?? $_POST['last_name'] ?? '');

    if (empty($username) || empty($email) || empty($password) || empty($firstName)) {
        Database::sendResponse(false, "Пожалуйста, заполните все обязательные поля (имя, username, email, пароль)", null, 400);
    }

    // Проверка существования username/email
    $checkStmt = $pdo->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
    $checkStmt->execute([$username, $email]);
    if ($checkStmt->fetch()) {
        Database::sendResponse(false, "Пользователь с таким логином или email уже существует", null, 400);
    }

    $passwordHash = password_hash($password, PASSWORD_BCRYPT);
    $avatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80";

    $stmt = $pdo->prepare("
        INSERT INTO users (username, email, password_hash, first_name, last_name, avatar_url, status_text)
        VALUES (?, ?, ?, ?, ?, ?, 'Добро пожаловать в сеть!')
    ");
    $stmt->execute([$username, $email, $passwordHash, $firstName, $lastName, $avatarUrl]);
    $userId = (int)$pdo->lastInsertId();

    $token = bin2hex(random_bytes(32));

    $user = [
        'id' => $userId,
        'username' => $username,
        'first_name' => $firstName,
        'last_name' => $lastName,
        'avatar_url' => $avatarUrl,
        'status_text' => 'Добро пожаловать в сеть!',
        'is_verified' => false,
        'followers_count' => 0,
        'following_count' => 0,
        'is_online' => true,
        'token' => $token
    ];

    Database::sendResponse(true, "Регистрация прошла успешно!", $user);

} elseif ($action === 'login') {
    $emailOrUsername = trim($input['email'] ?? $input['username'] ?? $_POST['email'] ?? '');
    $password = trim($input['password'] ?? $_POST['password'] ?? '');

    if (empty($emailOrUsername) || empty($password)) {
        Database::sendResponse(false, "Введите логин/email и пароль", null, 400);
    }

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ? OR username = ?");
    $stmt->execute([$emailOrUsername, $emailOrUsername]);
    $row = $stmt->fetch();

    if (!$row || !password_verify($password, $row['password_hash'])) {
        Database::sendResponse(false, "Неверный логин или пароль", null, 401);
    }

    $token = bin2hex(random_bytes(32));

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
        'token' => $token
    ];

    Database::sendResponse(true, "Успешный вход!", $user);
}
