-- ==========================================
-- Схема Базы Данных для Социальной Сети (VK Clone)
-- ==========================================

CREATE DATABASE IF NOT EXISTS `social_network` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `social_network`;

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    `avatar_url` TEXT NULL,
    `cover_url` TEXT NULL,
    `status_text` VARCHAR(255) NULL,
    `is_verified` TINYINT(1) DEFAULT 0,
    `bio` TEXT NULL,
    `followers_count` INT DEFAULT 0,
    `following_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица постов
CREATE TABLE IF NOT EXISTS `posts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `channel_id` INT NULL,
    `text` TEXT NOT NULL,
    `image_url` TEXT NULL,
    `audio_url` TEXT NULL,
    `video_url` TEXT NULL,
    `likes_count` INT DEFAULT 0,
    `reposts_count` INT DEFAULT 0,
    `comments_count` INT DEFAULT 0,
    `views_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица лайков
CREATE TABLE IF NOT EXISTS `likes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `post_id` INT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_user_post_like` (`user_id`, `post_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица комментариев
CREATE TABLE IF NOT EXISTS `comments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `post_id` INT NOT NULL,
    `text` TEXT NOT NULL,
    `likes_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица репостов
CREATE TABLE IF NOT EXISTS `reposts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `post_id` INT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица музыки (треков)
CREATE TABLE IF NOT EXISTS `tracks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(150) NOT NULL,
    `artist` VARCHAR(150) NOT NULL,
    `duration_seconds` INT NOT NULL,
    `cover_url` TEXT NULL,
    `audio_url` TEXT NOT NULL,
    `explicit` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица видеозаписей
CREATE TABLE IF NOT EXISTS `videos` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `thumbnail_url` TEXT NOT NULL,
    `video_url` TEXT NOT NULL,
    `duration_seconds` INT NOT NULL,
    `views_count` INT DEFAULT 0,
    `likes_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица каналов (пабликов)
CREATE TABLE IF NOT EXISTS `channels` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `avatar_url` TEXT NULL,
    `cover_url` TEXT NULL,
    `subscribers_count` INT DEFAULT 0,
    `category` VARCHAR(50) DEFAULT 'Паблик',
    `is_verified` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Подписки на каналы
CREATE TABLE IF NOT EXISTS `channel_subscribers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `channel_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_channel_sub` (`channel_id`, `user_id`),
    FOREIGN KEY (`channel_id`) REFERENCES `channels`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==========================================
-- Начальные данные для тестов
-- ==========================================

INSERT INTO `users` (`id`, `username`, `email`, `password_hash`, `first_name`, `last_name`, `avatar_url`, `status_text`, `is_verified`, `followers_count`, `following_count`) VALUES
(1, 'durov', 'durov@telegram.org', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHeFz2WdI8gX5Q2R7C1JvYJ8uYJ8uYJ8u', 'Павел', 'Дуров', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80', 'Верните стену! 🚀 Свобода общения.', 1, 1420500, 12);

INSERT INTO `tracks` (`id`, `title`, `artist`, `duration_seconds`, `cover_url`, `audio_url`, `explicit`) VALUES
(1, 'Midnight City', 'M83', 243, 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=400&q=80', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 0),
(2, 'Starboy (Feat. Daft Punk)', 'The Weeknd', 230, 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=400&q=80', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 1);

INSERT INTO `videos` (`id`, `user_id`, `title`, `description`, `thumbnail_url`, `video_url`, `duration_seconds`, `views_count`, `likes_count`) VALUES
(1, 1, 'Презентация iOS & SwiftUI: Будущее мобильных приложений', 'Полный обзор мобильной социальной сети.', 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=800&q=80', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 125, 42300, 3410);

INSERT INTO `channels` (`id`, `owner_id`, `name`, `description`, `avatar_url`, `subscribers_count`, `category`, `is_verified`) VALUES
(1, 1, 'Технологии будущего 🚀', 'Главные новости науки и разработки ПО.', 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=400&q=80', 84500, 'ИТ и Наука', 1);
