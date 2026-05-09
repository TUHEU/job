-- ══════════════════════════════════════════════════════════════
--  Goinus — MySQL Database Schema
--  Run once before starting the Flask server:
--    mysql -u root -p < schema.sql
--
--  The Flask server also auto-creates tables on startup,
--  so this file is mainly for a clean first-time setup.
-- ══════════════════════════════════════════════════════════════

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS goinus_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE goinus_db;

-- ── Users ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            VARCHAR(36)                       PRIMARY KEY,
    name          VARCHAR(120)          NOT NULL,
    email         VARCHAR(180)          NOT NULL    UNIQUE,
    password_hash VARCHAR(255)          NOT NULL,
    user_type     ENUM('intern','company') NOT NULL,
    is_verified   TINYINT(1)            DEFAULT 0,
    created_at    DATETIME              DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email     (email),
    INDEX idx_user_type (user_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Intern profiles ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS intern_profiles (
    user_id           VARCHAR(36)  PRIMARY KEY,
    gpa               DECIMAL(4,2),
    skills            TEXT,           -- comma-separated
    major             VARCHAR(120),
    about_me          TEXT,
    education_history TEXT,
    cv_path           VARCHAR(255),
    photo_url         VARCHAR(255),
    updated_at        DATETIME DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Company profiles ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS company_profiles (
    user_id      VARCHAR(36)  PRIMARY KEY,
    company_name VARCHAR(180),
    industry     VARCHAR(120),
    location     VARCHAR(180),
    about        TEXT,
    logo_url     VARCHAR(255),
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP
                 ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Internship listings ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS internships (
    id           VARCHAR(36)  PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    description  TEXT,
    company_id   VARCHAR(36)  NOT NULL,
    location     VARCHAR(180),
    field        VARCHAR(120),
    requirements TEXT,           -- comma-separated
    deadline     DATE,
    is_active    TINYINT(1)   DEFAULT 1,
    views        INT          DEFAULT 0,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_company  (company_id),
    INDEX idx_active   (is_active),
    INDEX idx_deadline (deadline),
    FOREIGN KEY (company_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Applications ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS applications (
    id             VARCHAR(36) PRIMARY KEY,
    intern_id      VARCHAR(36) NOT NULL,
    internship_id  VARCHAR(36) NOT NULL,
    status         ENUM('pending','accepted','rejected') DEFAULT 'pending',
    gpa            DECIMAL(4,2),
    about_me       TEXT,
    documents      TEXT,           -- comma-separated filenames
    created_at     DATETIME    DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_application (intern_id, internship_id),
    INDEX idx_intern     (intern_id),
    INDEX idx_internship (internship_id),
    INDEX idx_status     (status),
    FOREIGN KEY (intern_id)     REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Optional seed data (uncomment to use) ─────────────────────
-- INSERT INTO users VALUES
--   ('c1','TechCorp CM','hr@techcorp.cm',
--    '$2b$12$placeholder','company',1,NOW()),
--   ('i1','Nicole Chou','nicole@student.cm',
--    '$2b$12$placeholder','intern',1,NOW());
--
-- INSERT INTO company_profiles VALUES
--   ('c1','TechCorp Cameroon','Technology','Yaoundé',NULL,NULL,NOW());
--
-- INSERT INTO intern_profiles VALUES
--   ('i1',3.68,'Python,SQL,React','Computer Science',NULL,NULL,NULL,NULL,NOW());
--
-- INSERT INTO internships VALUES
--   ('j1','Software Intern','Build amazing things.','c1',
--    'Yaoundé','Technology','Python,SQL',
--    DATE_ADD(CURDATE(), INTERVAL 60 DAY),1,0,NOW());
