import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUsers1744000000000 implements MigrationInterface {
  name = 'CreateUsers1744000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 用户状态枚举
    await queryRunner.query(`
      CREATE TYPE "user_status_enum" AS ENUM ('PENDING_PROFILE', 'ACTIVE', 'BANNED')
    `);

    // 主用户表
    await queryRunner.query(`
      CREATE TABLE "users" (
        -- 雪花算法生成的 64 位 ID，以字符串存储避免 JS 精度丢失
        "uid"           BIGINT              NOT NULL,
        -- 微信 OpenID（同一小程序唯一）
        "open_id"       VARCHAR(64)         NOT NULL,
        -- 微信 UnionID（跨小程序/公众号唯一，可为 null）
        "union_id"      VARCHAR(64),
        -- 用户状态
        "status"        "user_status_enum"  NOT NULL DEFAULT 'PENDING_PROFILE',
        -- 昵称（最大 20 字符）
        "nickname"      VARCHAR(20),
        -- 头像 URL
        "avatar_url"    TEXT,
        -- 软删除时间戳（NULL 表示正常）
        "deleted_at"    TIMESTAMPTZ,
        -- 记录创建时间
        "created_at"    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
        -- 记录更新时间
        "updated_at"    TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

        CONSTRAINT "PK_users_uid" PRIMARY KEY ("uid")
      )
    `);

    // 唯一索引：open_id 全局唯一（同一小程序下）
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_users_open_id" ON "users" ("open_id")
    `);

    // 唯一索引：union_id 去重（允许 NULL，NULL 不参与唯一约束）
    await queryRunner.query(`
      CREATE UNIQUE INDEX "UQ_users_union_id" ON "users" ("union_id")
      WHERE "union_id" IS NOT NULL
    `);

    // 普通索引：按状态查询（后续运营统计使用）
    await queryRunner.query(`
      CREATE INDEX "IDX_users_status" ON "users" ("status")
    `);

    // 自动更新 updated_at 的触发器
    await queryRunner.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);

    await queryRunner.query(`
      CREATE TRIGGER "TRG_users_updated_at"
      BEFORE UPDATE ON "users"
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column()
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TRIGGER IF EXISTS "TRG_users_updated_at" ON "users"`);
    await queryRunner.query(`DROP FUNCTION IF EXISTS update_updated_at_column`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_users_status"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_users_union_id"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "UQ_users_open_id"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "users"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "user_status_enum"`);
  }
}
