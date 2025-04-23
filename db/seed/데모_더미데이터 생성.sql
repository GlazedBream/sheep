USE sheepdiary;

-- 1. 사용자
INSERT INTO user (user_id, email, password, name, gender, age) VALUES
(1, 'gregory89@gmail.com', 'hashed_pw_1', 'Erik Dominguez', 'female', 22),
(2, 'alexanderjohnson@weaver.com', 'hashed_pw_2', 'Jordan Wright', 'female', 64),
(3, 'teresawilliams@gmail.com', 'hashed_pw_3', 'Samuel Mckee', 'male', 52),
(4, 'ortizdana@wright-hart.com', 'hashed_pw_4', 'Jessica Huffman', 'male', 64),
(5, 'zsalazar@yahoo.com', 'hashed_pw_5', 'Michael Pacheco', 'female', 32),
(6, 'jenniferschultz@randolph-hubbard.com', 'hashed_pw_6', 'Aaron Martinez', 'female', 31),
(7, 'amanda34@patterson-graham.com', 'hashed_pw_7', 'Jodi Reed', 'male', 25),
(8, 'catkins@hotmail.com', 'hashed_pw_8', 'Stephanie Barrera', 'male', 47),
(9, 'dakota81@campbell.com', 'hashed_pw_9', 'Nicholas Davis', 'female', 38),
(10, 'marysanchez@hotmail.com', 'hashed_pw_10', 'Hailey Anderson', 'female', 58);

-- 2. 감정
INSERT INTO emotion (emotion_id, emotion_label) VALUES
(1, 'Happy'),
(2, 'Sad'),
(3, 'Excited'),
(4, 'Angry'),
(5, 'Calm'),
(6, 'Happy'),
(7, 'Sad'),
(8, 'Calm'),
(9, 'Excited'),
(10, 'Angry');

-- 3. 테마
INSERT INTO theme (theme_id, theme_name, thumbnail_url, description, is_free, is_default) VALUES
(1, 'tax', 'https://placeimg.com/608/573/any', 'All relate law speak term daughter.', 1, 1),
(2, 'like', 'https://dummyimage.com/666x502', 'Pattern no laugh senior everything true appear.', 1, 0),
(3, 'finally', 'https://placeimg.com/869/982/any', 'Believe teacher theory prevent nothing poor hundred.', 0, 1),
(4, 'as', 'https://placeimg.com/614/853/any', 'Morning drop source one election vote recently help.', 1, 1),
(5, 'sense', 'https://www.lorempixel.com/60/883', 'Should writer TV operation pay process clear.', 0, 1),
(6, 'over', 'https://dummyimage.com/374x547', 'She rich member radio put three decision.', 0, 1),
(7, 'throughout', 'https://www.lorempixel.com/948/623', 'Even try reach.', 1, 0),
(8, 'risk', 'https://www.lorempixel.com/714/287', 'Staff hit region if interesting model.', 1, 1),
(9, 'all', 'https://www.lorempixel.com/473/885', 'Cost exactly particularly.', 0, 0),
(10, 'total', 'https://placeimg.com/167/727/any', 'Single street especially seek then.', 1, 1);

-- 4. 사용자-테마
INSERT INTO user_theme (user_id, theme_id, is_applied) VALUES
(2, 5, 1),
(5, 10, 1),
(4, 6, 1),
(1, 7, 0),
(3, 3, 0),
(6, 3, 1),
(4, 3, 0),
(7, 7, 1),
(10, 5, 1),
(6, 7, 1);

-- 5. 검색 로그
INSERT INTO search_log (user_id, search_type, search_query, search_date) VALUES
(2, 'keyword', 'station', '2025-03-20 03:01:27'),
(5, 'diary',   'thank',   '2025-04-01 11:34:46'),
(2, 'keyword', 'success', '2025-03-28 21:12:17'),
(10,'keyword', 'attorney','2025-04-13 09:54:59'),
(1, 'diary',   'control', '2025-03-24 21:54:18'),
(2, 'diary',   'camera',  '2025-03-28 01:01:00'),
(6, 'location','few',     '2025-03-25 21:26:09'),
(10,'diary',   'magazine','2025-03-24 12:00:31'),
(8, 'location','nation',  '2025-04-16 14:18:23'),
(3, 'location','treatment','2025-03-25 08:26:20');

-- 6. 동의
INSERT INTO agreement (user_id, gps_agreement, personal_info, terms) VALUES
(1,1,1,1),(2,0,0,0),(3,0,1,0),(4,1,0,0),(5,1,1,1),
(6,1,0,0),(7,1,1,1),(8,0,0,0),(9,0,1,1),(10,0,0,1);

-- 7. 프로필 사진
INSERT INTO user_profile_picture (user_id, profile_picture_url) VALUES
(1,'https://www.lorempixel.com/53/25'),
(2,'https://www.lorempixel.com/930/107'),
(3,'https://placekitten.com/467/822'),
(4,'https://www.lorempixel.com/968/620'),
(5,'https://placeimg.com/211/421/any'),
(6,'https://www.lorempixel.com/706/306'),
(7,'https://placekitten.com/394/912'),
(8,'https://www.lorempixel.com/129/749'),
(9,'https://placekitten.com/967/301'),
(10,'https://placeimg.com/664/444/any');

-- 8. 스토어 아이템
INSERT INTO store_item (item_id, item_name, description, writer, price, content, item_type) VALUES
(1,'born','Seat audience summer animal onto.',           'Heather Lindsey',258,'This billion similar movie.','paper'),
(2,'worry','Attorney person day.',                        'Linda Todd',    338,'Prevent knowledge data friend machine.','paper'),
(3,'day','Human challenge sort star available within.',    'Justin Sharp',  499,'First plant allow sell mean.','sticker'),
(4,'protect','Child task focus.',                         'Mrs. Tonya Walker MD',260,'Market sign car rather industry cold task clear.','sticker'),
(5,'population','Among effect new information play.',      'Martha Parrish',144,'Road around exactly event.','sticker'),
(6,'item','Up system throw.',                              'Joseph Castillo',168,'Leg loss culture.','paper'),
(7,'responsibility','Able range region eye.',              'Carol Bates',    339,'Hour most note other.','paper'),
(8,'success','Hit special future defense kid recent land.','Dana Rice',     468,'Loss couple type throw increase far community.','sticker'),
(9,'man','Minute share center. Go yard still hot.',       'Juan Stone',     284,'Here door language figure unit clear six.','paper'),
(10,'stay','Ago open serious order.',                     'Jessica Howard', 475,'Well pretty physical add stage throughout forget.','sticker');

-- 9. 구매 이력
INSERT INTO purchase_history (purchase_id, user_id, item_id, item_type, amount, purchased_at) VALUES
(1,5,10,'theme',2,'2025-03-22 22:01:53'),
(2,7,8, 'paper',2,'2025-04-03 02:06:34'),
(3,6,4, 'theme',3,'2025-04-09 06:30:32'),
(4,6,4, 'paper',3,'2025-04-13 16:01:16'),
(5,3,3, 'theme',1,'2025-03-25 03:37:01'),
(6,1,1, 'paper',3,'2025-04-02 12:20:48'),
(7,9,1, 'paper',3,'2025-04-01 02:15:50'),
(8,9,1, 'theme',2,'2025-04-04 18:39:27'),
(9,10,2,'theme',3,'2025-03-21 04:42:33'),
(10,5,4,'paper',1,'2025-04-15 22:47:56');

-- 10. 알람 설정
INSERT INTO user_alarm_setting (alarm_id, user_id, alarm_type, alarm_time, repeat_days, is_enabled) VALUES
(1,6,'writing_reminder','10:29:41','Sat,Mon,Tue',1),
(2,1,'custom',          '03:03:52','Thu,Tue,Sat',1),
(3,5,'custom',          '18:37:36','Wed,Sat,Fri',1),
(4,7,'custom',          '11:29:45','Mon,Wed,Sun',0),
(5,10,'writing_reminder','20:57:53','Mon,Thu,Sat',0),
(6,5,'writing_reminder','21:15:34','Tue,Sat,Mon',1),
(7,10,'custom',         '04:28:12','Thu,Fri,Mon',1),
(8,1,'daily_summary',   '14:12:12','Sat,Tue,Mon',1),
(9,1,'writing_reminder','13:54:33','Mon,Fri,Sat',1),
(10,9,'custom',         '17:33:13','Mon,Sat,Sun',1);

-- 11. 키워드
INSERT INTO keyword (keyword_id, content, source_type) VALUES
(1,'young','from_picture'),
(2,'that','user_input'),
(3,'wide','user_input'),
(4,'control','from_picture'),
(5,'movement','user_input'),
(6,'provide','user_input'),
(7,'finish','user_input'),
(8,'sure','user_input'),
(9,'boy','from_picture'),
(10,'field','user_input');

-- 12. 위치
INSERT INTO location (location_id, region_name, specific_name, longitude, latitude) VALUES
(1,'West Diana',   '051 Bruce Mountain',      -86.972947,  35.926958),
(2,'Lake James',   '396 Adam Hollow Apt. 197', 179.518286, -27.937540),
(3,'Lake Kenneth', '899 Tanner Island',       -64.946674, -31.150157),
(4,'Gabriellefurt','73949 Olivia Estates',     -168.404694, 39.392078),
(5,'New Ricky',    '48359 Williams Brooks Apt. 192', -120.123632, -49.148204),
(6,'Jeremyfurt',   '3506 Logan Motorway',      -88.794764, -21.872684),
(7,'Jenniferport','3681 Amanda Mountain',      -33.844564, -48.557732),
(8,'Courtneyborough','935 Gerald Islands Suite 584', -25.346729, -31.320290),
(9,'Lake Hayleyside','7881 Fuller Lodge',      -157.228981, -22.052160),
(10,'Woodardburgh','0170 Mills Loaf Apt. 851', 167.342239,  61.976260);

-- 13. 사진
INSERT INTO picture (picture_id, picture_content_url, timestamp, longitude, latitude) VALUES
(1,'https://dummyimage.com/743x810','2025-04-12 12:46:04', -153.397066, -71.127996),
(2,'https://www.lorempixel.com/302/211','2025-03-24 14:34:41', -27.205325,  19.157200),
(3,'https://dummyimage.com/42x88',  '2025-04-12 11:50:14', -175.069178,  47.014756),
(4,'https://dummyimage.com/681x329','2025-03-22 13:18:50', -140.136629, -11.584826),
(5,'https://www.lorempixel.com/298/315','2025-04-08 23:17:04', -94.048600,  53.926056),
(6,'https://placekitten.com/173/968','2025-04-13 15:00:47',  47.051909,  43.428840),
(7,'https://dummyimage.com/592x920','2025-04-04 14:42:19', -154.872394, -73.513990),
(8,'https://placeimg.com/123/293/any','2025-03-26 04:35:35',  -133.422772,   4.965243),
(9,'https://dummyimage.com/102x44','2025-04-10 01:48:01',  -147.009936, -45.459596),
(10,'https://dummyimage.com/129x551','2025-04-14 21:45:49',  -59.000166,  -19.193642);

-- 14. 다이어리
INSERT INTO diary (diary_id, user_id, emotion_id, date, final_text, created_at) VALUES
(1,10,2,'2025-04-03 21:47:05','Effect standard trade. Feel through pretty civil investment civil. Eye center foreign record nation part consider can.','2025-04-03 21:47:05'),
(2,2,10,'2025-03-29 17:15:36','Difference his probably develop hundred probably bag front.','2025-03-29 17:15:36'),
(3,6,7,'2025-04-01 20:35:52','Subject culture you. Plan enter first parent southern.','2025-04-01 20:35:52'),
(4,1,7,'2025-03-31 08:50:45','Shake outside drive show throw either. Firm information base machine. Best bad north study decision still.','2025-03-31 08:50:45'),
(5,8,1,'2025-04-08 08:51:39','Majority shake member enjoy detail arm. After tough administration his news business east radio. Coach under shoulder always by sure.','2025-04-08 08:51:39'),
(6,2,6,'2025-03-24 19:02:31','Majority take thank shake produce. Sort agree yard thought knowledge action.','2025-03-24 19:02:31'),
(7,4,3,'2025-03-18 22:30:36','Itself know coach pick seek tax. Visit single represent.','2025-03-18 22:30:36'),
(8,10,10,'2025-04-17 02:48:55','Just interest hope.','2025-04-17 02:48:55'),
(9,9,7,'2025-04-08 07:21:52','Claim blood west bad. Health city family see lose mind modern.','2025-04-08 07:21:52'),
(10,1,5,'2025-03-21 15:35:24','Get represent building dinner notice group speech. Study main before grow. More husband American.','2025-03-21 15:35:24');

-- 15. 다이어리-키워드
INSERT INTO diary_keyword (diary_id, keyword_id, is_selected, is_auto_generated) VALUES
(4,2,1,1),
(8,6,1,1),
(7,8,0,0),
(1,3,1,1),
(2,10,0,1),
(3,8,0,1),
(7,2,0,1),
(5,6,0,0),
(3,6,0,1),
(1,1,0,0);

-- 16. 이벤트
INSERT INTO event (event_id, user_id, diary_id, location_id, timestamp_st, timestamp_end, event_emotion, weather, is_selected_event) VALUES
(1,7,8,3,'2025-03-29 08:45:17','2025-03-29 09:45:17','Calm','Cloudy',0),
(2,6,1,3,'2025-04-13 21:39:11','2025-04-13 22:39:11','Calm','Rainy',1),
(3,2,4,6,'2025-04-06 15:22:58','2025-04-06 16:22:58','Sad','Sunny',0),
(4,1,4,3,'2025-03-28 13:59:01','2025-03-28 14:59:01','Sad','Rainy',1),
(5,5,8,3,'2025-04-09 00:17:18','2025-04-09 01:17:18','Calm','Rainy',0),
(6,4,2,7,'2025-03-23 13:25:46','2025-03-23 14:25:46','Calm','Sunny',0),
(7,7,3,5,'2025-03-30 16:29:53','2025-03-30 17:29:53','Happy','Rainy',1),
(8,6,5,8,'2025-04-06 04:27:06','2025-04-06 05:27:06','Calm','Cloudy',1),
(9,5,7,2,'2025-04-05 20:49:45','2025-04-05 21:49:45','Happy','Rainy',0),
(10,1,9,7,'2025-04-07 08:25:46','2025-04-07 09:25:46','Calm','Sunny',0);

-- 17. 이벤트-키워드
INSERT INTO event_keyword (event_id, keyword_id, is_selected_keyword) VALUES
(1,3,1),
(1,7,1),
(2,10,0),
(2,5,1),
(3,3,1),
(5,1,1),
(5,3,0),
(5,4,0),
(6,3,1),
(6,5,0);

-- 18. 이벤트-사진 / 사진-키워드 / 메모
INSERT INTO event_picture (event_id, picture_id, is_selected_picture) VALUES
(1,4,0),
(2,4,1),
(3,2,1),
(4,2,1),
(5,5,0),
(6,1,1),
(7,7,0),
(8,6,1),
(9,6,1),
(10,10,0);

INSERT INTO picture_keyword (keyword_id, picture_id, link_type) VALUES
  (3, 4, 'from_picture'),
  (10,2, 'from_picture'),
  (3, 2, 'from_keyword'),
  (5, 5, 'from_keyword'),
  (2, 1, 'from_keyword'),
  (1, 7, 'from_picture'),
  (1, 6, 'from_keyword'),
  (9,10, 'from_picture');

INSERT INTO memo (memo_id, event_id, memo_content) VALUES
(1,1,'Agent camera pressure school stuff program.'),
(2,2,'Yet still hear.'),
(3,3,'Into statement resource factor eat contain she.'),
(4,4,'Clear leave light bad other tree everyone.'),
(5,5,'Gas news minute she account side development.'),
(6,6,'Hundred seat stop adult line response yes.'),
(7,7,'Strategy gas establish officer fact beyond executive player.'),
(8,8,'Suffer exist answer experience.'),
(9,9,'Bill president top paper sport most nature.'),
(10,10,'Their election mention author story.');
