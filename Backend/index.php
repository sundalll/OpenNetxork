<?php
$uri = $_SERVER['REQUEST_URI'] ?? '/';

$isPlaylist = (strpos($uri, '/pl/') === 0);
$isPost = (strpos($uri, '/post/') === 0);

$title = "Murlika — Социальная сеть будущего";
$description = "Свобода общения, музыка, каналы и видео без ограничений. Скачать Murlika для iOS!";
$ogType = "website";

if ($isPlaylist) {
    $slug = substr($uri, 4);
    $title = "Плейлист в Murlika";
    $description = "Слушайте этот плейлист в приложении Murlika!";
} elseif ($isPost) {
    $slug = substr($uri, 6);
    $title = "Публикация в Murlika";
    $description = "Смотрите запись и комментарии в социальной сети Murlika!";
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($title); ?></title>
    
    <!-- Open Graph for Telegram, WhatsApp, iMessage -->
    <meta property="og:site_name" content="Murlika Social">
    <meta property="og:title" content="<?php echo htmlspecialchars($title); ?>">
    <meta property="og:description" content="<?php echo htmlspecialchars($description); ?>">
    <meta property="og:image" content="https://myrlika.bond/Logo/murlika.png">
    <meta property="og:type" content="<?php echo $ogType; ?>">
    <meta property="og:url" content="https://myrlika.bond<?php echo htmlspecialchars($uri); ?>">

    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
        body { background: #0d0f17; color: #ffffff; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
        .card { background: #161926; border: 1px solid rgba(255,255,255,0.1); border-radius: 24px; padding: 40px 30px; text-align: center; max-width: 440px; width: 100%; box-shadow: 0 20px 50px rgba(0,0,0,0.5); }
        .logo { width: 100px; height: auto; margin-bottom: 24px; border-radius: 20px; filter: drop-shadow(0 8px 16px rgba(0,0,0,0.4)); }
        h1 { font-size: 24px; font-weight: 800; margin-bottom: 12px; background: linear-gradient(135deg, #a855f7, #3b82f6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        p { font-size: 15px; color: #94a3b8; line-height: 1.6; margin-bottom: 28px; }
        .btn { display: inline-block; width: 100%; padding: 16px 20px; background: linear-gradient(135deg, #3b82f6, #8b5cf6); color: #fff; font-weight: 700; font-size: 16px; border-radius: 14px; text-decoration: none; transition: transform 0.2s, box-shadow 0.2s; box-shadow: 0 10px 25px rgba(59,130,246,0.4); }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 14px 30px rgba(59,130,246,0.6); }
        .footer { margin-top: 24px; font-size: 12px; color: #64748b; }
    </style>
</head>
<body>
    <div class="card">
        <img src="https://myrlika.bond/Logo/murlika.png" alt="Murlika Logo" class="logo">
        <h1><?php echo htmlspecialchars($title); ?></h1>
        <p><?php echo htmlspecialchars($description); ?></p>
        <a href="https://myrlika.bond/Murlika.ipa" class="btn">📱 Установить Murlika на iOS</a>
        <div class="footer">Murlika Network v2.0 • HTTPS Protected</div>
    </div>
</body>
</html>
