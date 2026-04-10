import { Injectable } from '@nestjs/common';
import { TypeOrmModuleOptions, TypeOrmOptionsFactory } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';

@Injectable()
export class DatabaseConfig implements TypeOrmOptionsFactory {
  createTypeOrmOptions(): TypeOrmModuleOptions {
    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) {
      throw new Error('DATABASE_URL environment variable is not set');
    }

    return {
      type: 'postgres',
      url: databaseUrl,
      entities: [User],
      // migrations 路径指向编译后的 dist 目录
      migrations: [__dirname + '/../database/migrations/*.js'],
      // 生产环境禁用 synchronize，使用 migration
      synchronize: false,
      // 连接池配置（冷启动阶段适度保守）
      extra: {
        max: 10,
        min: 2,
        connectionTimeoutMillis: 5000,
        idleTimeoutMillis: 30000,
      },
      // SSL 连接（Railway PostgreSQL 要求 SSL）
      ssl:
        process.env.NODE_ENV === 'production'
          ? { rejectUnauthorized: false }
          : false,
      logging: process.env.NODE_ENV !== 'production',
    };
  }
}
