CREATE DATABASE IF NOT EXISTS sheepdiary
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE sheepdiary;

CREATE TABLE user (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(128) NOT NULL,
    user_name VARCHAR(150),
    gender ENUM('male', 'female'),
    age INT,
    joined_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE search_log (
    search_log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    search_type VARCHAR(50),
    search_query TEXT,
    search_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE agreement (
    agreement_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE,
    gps_agreement BOOLEAN DEFAULT FALSE,
    personal_info BOOLEAN DEFAULT FALSE,
    terms BOOLEAN DEFAULT FALSE,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);

CREATE TABLE user_profile_picture (
    user_id INT PRIMARY KEY,
    profile_picture_url VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);
CREATE TABLE theme (
    theme_id INT PRIMARY KEY AUTO_INCREMENT,
    theme_name VARCHAR(50) NOT NULL,
    thumbnail_url VARCHAR(255),
    description TEXT,
    is_free BOOLEAN DEFAULT TRUE NOT NULL,
    is_default BOOLEAN DEFAULT FALSE NOT NULL
);
CREATE TABLE user_theme (
    user_id INT,
    theme_id INT,
    is_applied BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (theme_id) REFERENCES theme(theme_id),
    PRIMARY KEY(user_id, theme_id)
);
CREATE TABLE store_item (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    item_name VARCHAR(50) NOT NULL,
    description TEXT,
    writer VARCHAR(50),
    price INT DEFAULT 0,
    content TEXT,
    item_type ENUM('paper', 'sticker') NOT NULL
);
CREATE TABLE purchase_history (
    purchase_id INT PRIMARY KEY AUTO_INCREMENT,
	user_id INT,
    item_id INT,
    item_type ENUM('theme', 'sticker', 'paper'),
    amount INT,
    purchased_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (item_id) REFERENCES store_item(item_id)
);

CREATE TABLE user_alarm_setting (
    alarm_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    alarm_type ENUM('daily_summary', 'writing_reminder', 'custom'),
    alarm_time TIME,
    repeat_days VARCHAR(27),  -- 예: 'Mon,Wed,Fri'
    is_enabled BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES user(user_id)
);



CREATE TABLE keyword (
    keyword_id INT PRIMARY KEY AUTO_INCREMENT,
    content VARCHAR(50),
    source_type ENUM('user_input', 'from_picture')
);

CREATE TABLE picture (
    picture_id INT PRIMARY KEY AUTO_INCREMENT,
    picture_content_url VARCHAR(255) NOT NULL,
    timestamp DATETIME,
    longitude DECIMAL(10,6),
    latitude DECIMAL(10,6)
);

CREATE TABLE location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    region_name VARCHAR(50),
    specific_name VARCHAR(100),
    longitude DECIMAL(10,6),
    latitude DECIMAL(10,6)
);


CREATE TABLE emotion (
    emotion_id INT PRIMARY KEY AUTO_INCREMENT,
    emotion_label VARCHAR(50)
);

CREATE TABLE diary (
    diary_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    emotion_id INT,
    diary_date DATETIME,
    final_text LONGTEXT,
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (emotion_id) REFERENCES emotion(emotion_id)
);



CREATE TABLE diary_keyword (
    diary_id INT,
    keyword_id INT,
    is_selected BOOLEAN NOT NULL,
    is_auto_generated BOOLEAN NOT NULL,
    PRIMARY KEY (diary_id, keyword_id),
    FOREIGN KEY (diary_id) REFERENCES diary(diary_id),
    FOREIGN KEY (keyword_id) REFERENCES keyword(keyword_id)
);

CREATE TABLE event (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    diary_id INT,
    location_id INT,
    start_time DATETIME,
    end_time DATETIME,
    event_emotion VARCHAR(50),
    weather VARCHAR(50),
    is_selected_event BOOLEAN,
    FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (diary_id) REFERENCES diary(diary_id),
    FOREIGN KEY (location_id) REFERENCES location(location_id)
);

CREATE TABLE event_keyword (
    event_id INT,
    keyword_id INT,
    is_selected_keyword BOOLEAN NOT NULL,
    PRIMARY KEY (event_id, keyword_id),
    FOREIGN KEY (event_id) REFERENCES event(event_id),
    FOREIGN KEY (keyword_id) REFERENCES keyword(keyword_id)
);

CREATE TABLE event_picture (
    event_id INT,
    picture_id INT,
    is_selected_picture BOOLEAN NOT NULL,
    PRIMARY KEY (event_id, picture_id),
    FOREIGN KEY (event_id) REFERENCES event(event_id),
    FOREIGN KEY (picture_id) REFERENCES picture(picture_id)
);

CREATE TABLE picture_keyword (
    keyword_id INT,
    picture_id INT,
    link_type ENUM('from_picture', 'from_keyword') NOT NULL,
    PRIMARY KEY (picture_id, keyword_id),
    FOREIGN KEY (keyword_id) REFERENCES keyword(keyword_id),
    FOREIGN KEY (picture_id) REFERENCES picture(picture_id)
);

CREATE TABLE memo (
    memo_id INT PRIMARY KEY AUTO_INCREMENT,
    event_id INT,
    memo_content TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES event(event_id)
);


