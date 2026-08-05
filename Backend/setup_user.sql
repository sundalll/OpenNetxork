CREATE USER IF NOT EXISTS 'social_user'@'127.0.0.1' IDENTIFIED BY 'social_pass_123';
CREATE USER IF NOT EXISTS 'social_user'@'localhost' IDENTIFIED BY 'social_pass_123';
GRANT ALL PRIVILEGES ON social_network.* TO 'social_user'@'127.0.0.1';
GRANT ALL PRIVILEGES ON social_network.* TO 'social_user'@'localhost';
FLUSH PRIVILEGES;
