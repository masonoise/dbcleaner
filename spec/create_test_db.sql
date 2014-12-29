--
-- Run this to create the test database.
-- Example: mysql -h localhost -u root -D test_dbcleaner < spec/create_test_db.sql
--
DROP TABLE IF EXISTS students;
CREATE TABLE students (
  id int(11) NOT NULL AUTO_INCREMENT,
  first_name varchar(255) DEFAULT NULL,
  last_name varchar(255) DEFAULT NULL,
  created_at datetime DEFAULT NULL,
  active tinyint(1) DEFAULT 0,
  comments text DEFAULT NULL,
  tuition decimal DEFAULT NULL,
  stuff BLOB DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

