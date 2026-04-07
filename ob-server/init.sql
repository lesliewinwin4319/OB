-- OB App - 注册登录模块数据库初始化脚本
-- 执行命令: psql -U liyudong -d ob_dev -f init.sql

-- 用户状态枚举
CREATE TYPE user_status AS ENUM ('PENDING_PROFILE', 'ACTIVE');

-- 用户主表
CREATE TABLE IF NOT EXISTS users (
    id              BIGSERIAL    PRIMARY KEY,
    uid             VARCHAR(32)  NOT NULL UNIQUE,
    openid          VARCHAR(64)  NOT NULL UNIQUE,
    unionid         VARCHAR(64),
    nickname        VARCHAR(64),
    avatar_wx_url   TEXT,
    avatar_cdn_url  TEXT,
    status          user_status  NOT NULL DEFAULT 'PENDING_PROFILE',
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_openid ON users(openid);
CREATE INDEX IF NOT EXISTS idx_users_uid    ON users(uid);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- 头像异步处理任务表
CREATE TYPE avatar_job_status AS ENUM ('PENDING', 'PROCESSING', 'DONE', 'FAILED');

CREATE TABLE IF NOT EXISTS avatar_jobs (
    id          BIGSERIAL         PRIMARY KEY,
    uid         VARCHAR(32)       NOT NULL,
    wx_url      TEXT              NOT NULL,
    cdn_url     TEXT,
    status      avatar_job_status NOT NULL DEFAULT 'PENDING',
    retry_count INT               NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_avatar_jobs_uid FOREIGN KEY (uid) REFERENCES users(uid)
);

CREATE INDEX IF NOT EXISTS idx_avatar_jobs_uid    ON avatar_jobs(uid);
CREATE INDEX IF NOT EXISTS idx_avatar_jobs_status ON avatar_jobs(status);
