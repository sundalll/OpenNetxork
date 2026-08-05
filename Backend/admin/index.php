<?php
session_start();
require_once __DIR__ . '/../db.php';

$ADMIN_PASSWORD = 'AdminOpenNetwork_2026!#Secured';
$pdo = Database::getInstance();

// Выход из админ панели
if (isset($_GET['logout'])) {
    unset($_SESSION['admin_logged_in']);
    header('Location: index.php');
    exit;
}

// Авторизация в админ панели
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_password'])) {
    if ($_POST['login_password'] === $ADMIN_PASSWORD) {
        $_SESSION['admin_logged_in'] = true;
        header('Location: index.php');
        exit;
    } else {
        $error = 'Неверный пароль администратора!';
    }
}

// Проверка сессии
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LemSocial — Админ Панель</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .login-card { background: #1e293b; border-radius: 16px; padding: 40px; width: 100%; max-width: 400px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.5); text-align: center; }
        h2 { margin-bottom: 24px; color: #38bdf8; }
        input[type="password"] { width: 100%; padding: 14px; margin-bottom: 20px; border-radius: 8px; border: 1px solid #334155; background: #0f172a; color: #fff; box-sizing: border-box; font-size: 16px; }
        button { width: 100%; padding: 14px; background: #0284c7; color: white; border: none; border-radius: 8px; font-weight: bold; font-size: 16px; cursor: pointer; }
        button:hover { background: #0369a1; }
        .error { color: #ef4444; margin-bottom: 16px; font-size: 14px; }
    </style>
</head>
<body>
    <div class="login-card">
        <h2>🛡️ LemSocial Admin</h2>
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <form method="POST">
            <input type="password" name="login_password" placeholder="Введите пароль администратора" required autocomplete="current-password">
            <button type="submit">Войти в админ-панель</button>
        </form>
    </div>
</body>
</html>
<?php
    exit;
}

// Действия администратора (Удаление пользователя, выдача галочки, удаление постов)
if (isset($_GET['action'])) {
    $action = $_GET['action'];
    $id = (int)($_GET['id'] ?? 0);

    if ($action === 'verify_user' && $id > 0) {
        $stmt = $pdo->prepare("UPDATE users SET is_verified = 1 - is_verified WHERE id = ?");
        $stmt->execute([$id]);
    } elseif ($action === 'delete_user' && $id > 0) {
        $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$id]);
    } elseif ($action === 'delete_post' && $id > 0) {
        $stmt = $pdo->prepare("DELETE FROM posts WHERE id = ?");
        $stmt->execute([$id]);
    } elseif ($action === 'delete_track' && $id > 0) {
        $stmt = $pdo->prepare("DELETE FROM tracks WHERE id = ?");
        $stmt->execute([$id]);
    } elseif ($action === 'delete_video' && $id > 0) {
        $stmt = $pdo->prepare("DELETE FROM videos WHERE id = ?");
        $stmt->execute([$id]);
    }
    header('Location: index.php');
    exit;
}

// Загрузка статистики
$usersCount = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$postsCount = $pdo->query("SELECT COUNT(*) FROM posts")->fetchColumn();
$tracksCount = $pdo->query("SELECT COUNT(*) FROM tracks")->fetchColumn();
$videosCount = $pdo->query("SELECT COUNT(*) FROM videos")->fetchColumn();

$users = $pdo->query("SELECT * FROM users ORDER BY id DESC")->fetchAll();
$posts = $pdo->query("SELECT p.*, u.username FROM posts p JOIN users u ON p.user_id = u.id ORDER BY p.id DESC")->fetchAll();
$tracks = $pdo->query("SELECT * FROM tracks ORDER BY id DESC")->fetchAll();
$videos = $pdo->query("SELECT * FROM videos ORDER BY id DESC")->fetchAll();
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Панель Администратора — OpenNetwork</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 24px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #334155; padding-bottom: 16px; margin-bottom: 24px; }
        .header h1 { color: #38bdf8; margin: 0; }
        .logout-btn { background: #ef4444; color: white; padding: 10px 18px; border-radius: 8px; text-decoration: none; font-weight: bold; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 32px; }
        .stat-card { background: #1e293b; padding: 20px; border-radius: 12px; border: 1px solid #334155; }
        .stat-card h3 { margin: 0 0 8px 0; color: #94a3b8; font-size: 14px; }
        .stat-card .val { font-size: 28px; font-weight: bold; color: #38bdf8; }
        section { background: #1e293b; border-radius: 12px; padding: 20px; margin-bottom: 32px; border: 1px solid #334155; }
        section h2 { margin-top: 0; color: #f8fafc; border-bottom: 1px solid #334155; padding-bottom: 12px; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #334155; font-size: 14px; }
        th { color: #94a3b8; }
        .btn { padding: 6px 12px; border-radius: 6px; text-decoration: none; font-size: 12px; font-weight: bold; margin-right: 6px; display: inline-block; }
        .btn-verify { background: #0284c7; color: white; }
        .btn-delete { background: #ef4444; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Панель Управления OpenNetwork</h1>
        <a href="?logout=1" class="logout-btn">Выйти из панели</a>
    </div>

    <div class="stats-grid">
        <div class="stat-card"><h3>Пользователей</h3><div class="val"><?= $usersCount ?></div></div>
        <div class="stat-card"><h3>Постов в ленте</h3><div class="val"><?= $postsCount ?></div></div>
        <div class="stat-card"><h3>Треков музыки</h3><div class="val"><?= $tracksCount ?></div></div>
        <div class="stat-card"><h3>Загружено видео</h3><div class="val"><?= $videosCount ?></div></div>
    </div>

    <section>
        <h2>Управление Пользователями</h2>
        <table>
            <thead>
                <tr><th>ID</th><th>Логин</th><th>Имя</th><th>Статус</th><th>Галочка</th><th>Действия</th></tr>
            </thead>
            <tbody>
                <?php foreach ($users as $u): ?>
                <tr>
                    <td><?= $u['id'] ?></td>
                    <td>@<?= htmlspecialchars($u['username']) ?></td>
                    <td><?= htmlspecialchars($u['first_name'] . ' ' . $u['last_name']) ?></td>
                    <td><?= htmlspecialchars($u['status_text'] ?? '') ?></td>
                    <td><?= $u['is_verified'] ? '✅ Верифицирован' : '❌ Нет' ?></td>
                    <td>
                        <a href="?action=verify_user&id=<?= $u['id'] ?>" class="btn btn-verify">Галочка</a>
                        <a href="?action=delete_user&id=<?= $u['id'] ?>" class="btn btn-delete" onclick="return confirm('Удалить пользователя?')">Удалить</a>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </section>

    <section>
        <h2>Управление Музыкой</h2>
        <table>
            <thead>
                <tr><th>ID</th><th>Название</th><th>Автор</th><th>URL Файла</th><th>Действия</th></tr>
            </thead>
            <tbody>
                <?php foreach ($tracks as $t): ?>
                <tr>
                    <td><?= $t['id'] ?></td>
                    <td><?= htmlspecialchars($t['title']) ?></td>
                    <td><?= htmlspecialchars($t['artist']) ?></td>
                    <td><a href="<?= htmlspecialchars($t['audio_url']) ?>" target="_blank" style="color:#38bdf8;">Слушать</a></td>
                    <td>
                        <a href="?action=delete_track&id=<?= $t['id'] ?>" class="btn btn-delete" onclick="return confirm('Удалить трек?')">Удалить</a>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </section>
</body>
</html>
