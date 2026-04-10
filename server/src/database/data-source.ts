/**
 * TypeORM CLI 专用 DataSource
 * 用于本地执行 migration:generate / migration:run 命令
 * 与运行时的 DatabaseConfig 保持一致
 */
import 'reflect-metadata';
import * as dotenv from 'dotenv';
import { DataSource } from 'typeorm';
import { User } from '../users/entities/user.entity';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL || 'postgresql://ob_user:password@localhost:5432/ob_db',
  entities: [User],
  migrations: [__dirname + '/migrations/*.ts'],
  synchronize: false,
  logging: true,
});
