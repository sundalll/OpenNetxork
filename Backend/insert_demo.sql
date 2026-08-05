USE `social_network`;

INSERT INTO `posts` (`id`, `user_id`, `text`, `image_url`, `audio_url`, `likes_count`, `reposts_count`, `comments_count`, `views_count`) VALUES
(101, 1, 'Привет всем пользователям нашей новой социальной сети на Swift & SwiftUI! 🚀\n\nДизайн создан по всем стандартам iOS 13–18 с плавной анимацией, полной поддержкой музыки, видео, стенами и статусами.', 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1000&q=80', NULL, 1420, 312, 89, 15400),
(102, 1, '🎵 Премьера нового альбома в плеере приложения! Нажмите на трек ниже, чтобы включить фоновый аудиоплеер с обложкой.', NULL, 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 950, 140, 42, 8900)
ON DUPLICATE KEY UPDATE `text` = VALUES(`text`);
