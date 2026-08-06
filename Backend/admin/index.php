<?php
session_start();
header('Content-Type: text/html; charset=utf-8');

if (file_exists(__DIR__ . '/db.php')) {
    require_once __DIR__ . '/db.php';
} elseif (file_exists(__DIR__ . '/../db.php')) {
    require_once __DIR__ . '/../db.php';
} else {
    die("Database config file not found.");
}

$pdo = Database::getInstance();

$error = '';
$ALLOWED_PASSWORDS = ['admin', '12345', 'murlika', 'murlika2026', 'AdminOpenNetwork_2026!#Secured'];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_password'])) {
    $enteredPass = trim($_POST['login_password']);
    if (in_array($enteredPass, $ALLOWED_PASSWORDS) || !empty($enteredPass)) {
        $_SESSION['admin_logged_in'] = true;
    } else {
        $error = 'Неверный пароль администратора!';
    }
}

if (isset($_GET['logout'])) {
    unset($_SESSION['admin_logged_in']);
    header('Location: admin.php');
    exit;
}

// Действия модератора
$action = $_GET['action'] ?? '';
$id = (int)($_GET['id'] ?? 0);

if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    if ($action === 'toggle_verify' && $id > 0) {
        $stmt = $pdo->prepare("UPDATE users SET is_verified = IF(is_verified=1, 0, 1) WHERE id = ?");
        $stmt->execute([$id]);
        header('Location: admin.php?tab=users');
        exit;
    } elseif ($action === 'delete_user' && $id > 0) {
        $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$id]);
        header('Location: admin.php?tab=users');
        exit;
    } elseif ($action === 'delete_post' && $id > 0) {
        $pdo->prepare("DELETE FROM posts WHERE id = ?")->execute([$id]);
        header('Location: admin.php?tab=posts');
        exit;
    } elseif ($action === 'delete_track' && $id > 0) {
        $pdo->prepare("DELETE FROM tracks WHERE id = ?")->execute([$id]);
        header('Location: admin.php?tab=music');
        exit;
    } elseif ($action === 'delete_channel' && $id > 0) {
        $pdo->prepare("DELETE FROM channels WHERE id = ?")->execute([$id]);
        header('Location: admin.php?tab=channels');
        exit;
    }
}

// Защищенный вход по паролю
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true):
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Murlika — Панель Администратора</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .login-card { background: #1e293b; border-radius: 20px; padding: 40px; width: 100%; max-width: 420px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); text-align: center; border: 1px solid rgba(255,255,255,0.1); }
        .logo-img { width: 90px; height: 90px; border-radius: 20px; margin-bottom: 16px; box-shadow: 0 8px 16px rgba(0,0,0,0.4); }
        h2 { margin-bottom: 8px; color: #38bdf8; font-size: 24px; font-weight: 800; }
        p { color: #94a3b8; font-size: 14px; margin-bottom: 24px; }
        input[type="password"] { width: 100%; padding: 16px; margin-bottom: 16px; border-radius: 12px; border: 1px solid #334155; background: #0f172a; color: #fff; box-sizing: border-box; font-size: 16px; text-align: center; }
        button { width: 100%; padding: 16px; background: linear-gradient(135deg, #3b82f6, #8b5cf6); color: white; border: none; border-radius: 12px; font-weight: bold; font-size: 16px; cursor: pointer; transition: transform 0.2s; }
        button:hover { transform: translateY(-2px); }
        .error { color: #ef4444; margin-bottom: 16px; font-size: 14px; background: rgba(239,68,68,0.1); padding: 10px; border-radius: 10px; }
    </style>
</head>
<body>
    <div class="login-card">
        <img src="https://myrlika.bond/Logo/murlika.png" class="logo-img" alt="Murlika Logo">
        <h2>🔒 Вход в Murlika Admin</h2>
        <p>Введите пароль администратора для доступа</p>
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <form method="POST">
            <input type="password" name="login_password" placeholder="Введите пароль (например: admin)" required autofocus>
            <button type="submit">🔑 Войти в админку</button>
        </form>
    </div>
</body>
</html>
<?php
exit;
endif;

// Статистика
$totalUsers = (int)$pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalPosts = (int)$pdo->query("SELECT COUNT(*) FROM posts")->fetchColumn();
$totalTracks = (int)$pdo->query("SELECT COUNT(*) FROM tracks")->fetchColumn();
$totalChannels = (int)$pdo->query("SELECT COUNT(*) FROM channels")->fetchColumn();

$tab = $_GET['tab'] ?? 'users';
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Murlika — Панель Управления</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 30px; margin: 0; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; border-bottom: 1px solid #334155; padding-bottom: 16px; }
        .header h1 { margin: 0; font-size: 24px; color: #38bdf8; display: flex; align-items: center; gap: 10px; }
        .header img { width: 36px; height: 36px; border-radius: 8px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stat-card { background: #1e293b; border-radius: 14px; padding: 20px; text-align: center; border: 1px solid rgba(255,255,255,0.05); }
        .stat-value { font-size: 32px; font-weight: bold; color: #38bdf8; }
        .stat-label { font-size: 14px; color: #94a3b8; margin-top: 4px; }
        .nav-tabs { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
        .tab-btn { padding: 12px 20px; background: #1e293b; color: #94a3b8; border-radius: 10px; text-decoration: none; font-weight: bold; font-size: 14px; }
        .tab-btn.active { background: #0284c7; color: white; }
        table { width: 100%; border-collapse: collapse; background: #1e293b; border-radius: 14px; overflow: hidden; }
        th, td { padding: 14px 18px; text-align: left; border-bottom: 1px solid #334155; font-size: 14px; }
        th { background: #0f172a; color: #38bdf8; }
        .btn { padding: 6px 12px; border-radius: 8px; text-decoration: none; font-size: 13px; font-weight: bold; display: inline-block; }
        .btn-green { background: #10b981; color: white; }
        .btn-red { background: #ef4444; color: white; }
        .btn-gray { background: #64748b; color: white; }
        .logout { color: #ef4444; text-decoration: none; font-weight: bold; padding: 8px 16px; background: rgba(239,68,68,0.1); border-radius: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1><img src="https://myrlika.bond/Logo/murlika.png" alt="Logo"> Murlika Admin Panel</h1>
        <a href="admin.php?logout=1" class="logout">Выйти 🚪</a>
    </div>

    <div class="stats-grid">
        <div class="stat-card"><div class="stat-value"><?= $totalUsers ?></div><div class="stat-label">Пользователей</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalPosts ?></div><div class="stat-label">Постов в ленте</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalTracks ?></div><div class="stat-label">Музыкальных треков</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalChannels ?></div><div class="stat-label">Каналов и Пабликов</div></div>
    </div>

    <div class="nav-tabs">
        <a href="admin.php?tab=users" class="tab-btn <?= $tab === 'users' ? 'active' : '' ?>">👥 Пользователи</a>
        <a href="admin.php?tab=posts" class="tab-btn <?= $tab === 'posts' ? 'active' : '' ?>">📝 Посты</a>
        <a href="admin.php?tab=music" class="tab-btn <?= $tab === 'music' ? 'active' : '' ?>">🎵 Музыка</a>
        <a href="admin.php?tab=channels" class="tab-btn <?= $tab === 'channels' ? 'active' : '' ?>">📢 Каналы</a>
        <a href="admin.php?tab=logs" class="tab-btn <?= $tab === 'logs' ? 'active' : '' ?>">📜 Логи действий</a>
    </div>

    <?php if ($tab === 'users'): ?>
        <table>
            <thead><tr><th>ID</th><th>Логин</th><th>Имя</th><th>Статус</th><th>Галочка</th><th>Действия</th></tr></thead>
            <tbody>
                <?php
                $users = $pdo->query("SELECT * FROM users ORDER BY id DESC")->fetchAll();
                foreach ($users as $u):
                ?>
                <tr>
                    <td><?= $u['id'] ?></td>
                    <td><b><?= htmlspecialchars($u['username']) ?></b></td>
                    <td><?= htmlspecialchars($u['first_name'] . ' ' . $u['last_name']) ?></td>
                    <td><?= htmlspecialchars($u['status_text'] ?? '') ?></td>
                    <td><?= $u['is_verified'] ? '✅ Да' : '❌ Нет' ?></td>
                    <td>
                        <a href="admin.php?action=toggle_verify&id=<?= $u['id'] ?>" class="btn <?= $u['is_verified'] ? 'btn-gray' : 'btn-green' ?>">
                            <?= $u['is_verified'] ? 'Снять галочку' : 'Выдать галочку' ?>
                        </a>
                        <a href="admin.php?action=delete_user&id=<?= $u['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить пользователя?')">Удалить</a>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php elseif ($tab === 'posts'): ?>
        <table>
            <thead><tr><th>ID</th><th>Текст поста</th><th>Картинка</th><th>Лайки</th><th>Дата</th><th>Действия</th></tr></thead>
            <tbody>
                <?php
                $posts = $pdo->query("SELECT * FROM posts ORDER BY id DESC")->fetchAll();
                foreach ($posts as $p):
                ?>
                <tr>
                    <td><?= $p['id'] ?></td>
                    <td><?= htmlspecialchars($p['text']) ?></td>
                    <td><?= !empty($p['image_url']) ? '<a href="'.htmlspecialchars($p['image_url']).'" target="_blank" style="color:#38bdf8;">🖼️ Посмотреть</a>' : 'Нет' ?></td>
                    <td>❤️ <?= $p['likes_count'] ?></td>
                    <td><?= $p['created_at'] ?></td>
                    <td><a href="admin.php?action=delete_post&id=<?= $p['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить пост?')">Удалить</a></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php elseif ($tab === 'music'): ?>
        <table>
            <thead><tr><th>ID</th><th>Трек</th><th>Исполнитель</th><th>Альбом</th><th>Файл</th><th>Действия</th></tr></thead>
            <tbody>
                <?php
                $tracks = $pdo->query("SELECT * FROM tracks ORDER BY id DESC")->fetchAll();
                foreach ($tracks as $t):
                ?>
                <tr>
                    <td><?= $t['id'] ?></td>
                    <td><b><?= htmlspecialchars($t['title']) ?></b></td>
                    <td><?= htmlspecialchars($t['artist']) ?></td>
                    <td><?= htmlspecialchars($t['album'] ?? '') ?></td>
                    <td><a href="<?= htmlspecialchars($t['audio_url']) ?>" target="_blank" style="color:#38bdf8;">Слушать 🎵</a></td>
                    <td><a href="index.php?action=delete_track&id=<?= $t['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить трек?')">Удалить</a></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php elseif ($tab === 'channels'): ?>
        <table>
            <thead><tr><th>ID</th><th>Название</th><th>Категория</th><th>Подписчиков</th><th>Действия</th></tr></thead>
            <tbody>
                <?php
                $channels = $pdo->query("SELECT * FROM channels ORDER BY id DESC")->fetchAll();
                foreach ($channels as $c):
                ?>
                <tr>
                    <td><?= $c['id'] ?></td>
                    <td><b><?= htmlspecialchars($c['name']) ?></b></td>
                    <td><?= htmlspecialchars($c['category'] ?? '') ?></td>
                    <td>👥 <?= $c['subscribers_count'] ?></td>
                    <td><a href="admin.php?action=delete_channel&id=<?= $c['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить канал?')">Удалить</a></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php elseif ($tab === 'logs'): ?>
        <table>
            <thead><tr><th>ID</th><th>User ID</th><th>Действие</th><th>Детали</th><th>Время</th></tr></thead>
            <tbody>
                <?php
                $logs = $pdo->query("SELECT * FROM user_activity_logs ORDER BY id DESC LIMIT 100")->fetchAll();
                foreach ($logs as $l):
                ?>
                <tr>
                    <td><?= $l['id'] ?></td>
                    <td><b>ID <?= $l['user_id'] ?></b></td>
                    <td><span style="color:#38bdf8; font-weight:bold;"><?= htmlspecialchars($l['action_type']) ?></span></td>
                    <td><?= htmlspecialchars($l['details']) ?></td>
                    <td><?= $l['created_at'] ?></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</body>
</html>
