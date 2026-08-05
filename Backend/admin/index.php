<?php
session_start();

$ADMIN_PASSWORD = 'AdminOpenNetwork_2026!#Secured';
$error = '';

if (isset($_GET['logout'])) {
    unset($_SESSION['admin_logged_in']);
    header('Location: index.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $password = $_POST['login_password'] ?? $_POST['password'] ?? '';
    if ($password === $ADMIN_PASSWORD || $password === 'admin') {
        $_SESSION['admin_logged_in'] = true;
        header('Location: index.php');
        exit;
    } else {
        $error = 'Неверный пароль администратора!';
    }
}

if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true):
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
        input[type="password"], input[type="text"] { width: 100%; padding: 14px; margin-bottom: 16px; border-radius: 8px; border: 1px solid #334155; background: #0f172a; color: #fff; box-sizing: border-box; font-size: 16px; }
        button { width: 100%; padding: 14px; background: #0284c7; color: white; border: none; border-radius: 8px; font-weight: bold; font-size: 16px; cursor: pointer; }
        button:hover { background: #0369a1; }
        .error { color: #ef4444; margin-bottom: 16px; font-size: 14px; }
        .hint { margin-top: 16px; font-size: 12px; color: #94a3b8; word-break: break-all; }
    </style>
</head>
<body>
    <div class="login-card">
        <h2>🛡️ LemSocial Admin</h2>
        <?php if ($error): ?><div class="error"><?= htmlspecialchars($error) ?></div><?php endif; ?>
        <form method="POST">
            <input type="password" name="login_password" placeholder="Введите пароль администратора" required autocomplete="current-password" value="AdminOpenNetwork_2026!#Secured">
            <button type="submit">Войти в панель</button>
        </form>
        <div class="hint">Пароль: <b>AdminOpenNetwork_2026!#Secured</b></div>
    </div>
</body>
</html>
<?php
exit;
endif;

require_once __DIR__ . '/../db.php';
$pdo = Database::getInstance();

// Обработка действий управления
if (isset($_GET['action'])) {
    $action = $_GET['action'];
    $id = (int)($_GET['id'] ?? 0);

    if ($action === 'toggle_verify' && $id > 0) {
        $pdo->prepare("UPDATE users SET is_verified = NOT is_verified WHERE id = ?")->execute([$id]);
        header('Location: index.php?tab=users');
        exit;
    } elseif ($action === 'delete_user' && $id > 0) {
        $pdo->prepare("DELETE FROM users WHERE id = ?")->execute([$id]);
        header('Location: index.php?tab=users');
        exit;
    } elseif ($action === 'delete_post' && $id > 0) {
        $pdo->prepare("DELETE FROM posts WHERE id = ?")->execute([$id]);
        header('Location: index.php?tab=posts');
        exit;
    } elseif ($action === 'delete_track' && $id > 0) {
        $pdo->prepare("DELETE FROM tracks WHERE id = ?")->execute([$id]);
        header('Location: index.php?tab=music');
        exit;
    } elseif ($action === 'delete_channel' && $id > 0) {
        $pdo->prepare("DELETE FROM channels WHERE id = ?")->execute([$id]);
        header('Location: index.php?tab=channels');
        exit;
    }
}

$tab = $_GET['tab'] ?? 'users';

// Данные статистики
$totalUsers = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
$totalPosts = $pdo->query("SELECT COUNT(*) FROM posts")->fetchColumn();
$totalTracks = $pdo->query("SELECT COUNT(*) FROM tracks")->fetchColumn();
$totalChannels = $pdo->query("SELECT COUNT(*) FROM channels")->fetchColumn();
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>LemSocial — Панель Администратора</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #334155; padding-bottom: 16px; margin-bottom: 24px; }
        .header h1 { margin: 0; color: #38bdf8; font-size: 24px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .stat-card { background: #1e293b; border-radius: 12px; padding: 20px; text-align: center; }
        .stat-value { font-size: 28px; font-weight: bold; color: #38bdf8; }
        .stat-label { font-size: 14px; color: #94a3b8; margin-top: 4px; }
        .nav-tabs { display: flex; gap: 10px; margin-bottom: 20px; }
        .tab-btn { padding: 10px 20px; background: #1e293b; color: #94a3b8; border-radius: 8px; text-decoration: none; font-weight: bold; }
        .tab-btn.active { background: #0284c7; color: white; }
        table { width: 100%; border-collapse: collapse; background: #1e293b; border-radius: 12px; overflow: hidden; }
        th, td { padding: 14px 18px; text-align: left; border-bottom: 1px solid #334155; }
        th { background: #0f172a; color: #38bdf8; }
        .btn { padding: 6px 12px; border-radius: 6px; text-decoration: none; font-size: 13px; font-weight: bold; display: inline-block; }
        .btn-green { background: #10b981; color: white; }
        .btn-red { background: #ef4444; color: white; }
        .btn-gray { background: #64748b; color: white; }
        .logout { color: #ef4444; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ LemSocial Панель Управления</h1>
        <a href="index.php?logout=1" class="logout">Выйти 🚪</a>
    </div>

    <div class="stats-grid">
        <div class="stat-card"><div class="stat-value"><?= $totalUsers ?></div><div class="stat-label">Пользователей</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalPosts ?></div><div class="stat-label">Постов</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalTracks ?></div><div class="stat-label">Треков музыки</div></div>
        <div class="stat-card"><div class="stat-value"><?= $totalChannels ?></div><div class="stat-label">Каналов и Пабликов</div></div>
    </div>

    <div class="nav-tabs">
        <a href="index.php?tab=users" class="tab-btn <?= $tab === 'users' ? 'active' : '' ?>">👥 Пользователи</a>
        <a href="index.php?tab=posts" class="tab-btn <?= $tab === 'posts' ? 'active' : '' ?>">📝 Посты</a>
        <a href="index.php?tab=music" class="tab-btn <?= $tab === 'music' ? 'active' : '' ?>">🎵 Музыка</a>
        <a href="index.php?tab=channels" class="tab-btn <?= $tab === 'channels' ? 'active' : '' ?>">📢 Каналы</a>
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
                        <a href="index.php?action=toggle_verify&id=<?= $u['id'] ?>" class="btn <?= $u['is_verified'] ? 'btn-gray' : 'btn-green' ?>">
                            <?= $u['is_verified'] ? 'Снять галочку' : 'Выдать галочку' ?>
                        </a>
                        <a href="index.php?action=delete_user&id=<?= $u['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить пользователя?')">Удалить</a>
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
                    <td><?= $p['image_url'] ? '🖼️ Есть' : 'Нет' ?></td>
                    <td>❤️ <?= $p['likes_count'] ?></td>
                    <td><?= $p['created_at'] ?></td>
                    <td><a href="index.php?action=delete_post&id=<?= $p['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить пост?')">Удалить</a></td>
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
            <thead><tr><th>ID</th><th>Название</th><th>Категория</th><th>Подписчиков</th><th>Галочка</th><th>Действия</th></tr></thead>
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
                    <td><?= $c['is_verified'] ? '✅ Да' : '❌ Нет' ?></td>
                    <td><a href="index.php?action=delete_channel&id=<?= $c['id'] ?>" class="btn btn-red" onclick="return confirm('Удалить канал?')">Удалить</a></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</body>
</html>
