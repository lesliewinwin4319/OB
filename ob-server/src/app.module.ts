import { Module, Global } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { APP_GUARD } from '@nestjs/core';
import Redis from 'ioredis';

import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { AvatarModule } from './avatar/avatar.module';

import { User } from './users/entities/user.entity';
import { AvatarJob } from './avatar/entities/avatar-job.entity';

import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { PendingProfileGuard } from './auth/guards/pending-profile.guard';
import { REDIS_CLIENT } from './common/redis.decorator';

/**
 * Redis 工厂 Provider
 * 统一管理连接，全局注入，所有模块通过 @InjectRedis() 使用
 */
const redisProvider = {
  provide: REDIS_CLIENT,
  inject: [ConfigService],
  useFactory: (configService: ConfigService): Redis => {
    const client = new Redis({
      host: configService.get<string>('REDIS_HOST', 'localhost'),
      port: configService.get<number>('REDIS_PORT', 6379),
      lazyConnect: false,
    });

    client.on('connect', () => console.log('[Redis] Connected'));
    client.on('error', (err) => console.error('[Redis] Error:', err.message));

    return client;
  },
};

@Global()
@Module({
  imports: [
    // 环境变量加载（支持 .env 文件，在所有模块前加载）
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // TypeORM 数据库连接
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        url: configService.get<string>('DATABASE_URL'),
        entities: [User, AvatarJob],
        // 生产环境禁止 synchronize，使用迁移文件管理 schema
        synchronize: false,
        logging: process.env.NODE_ENV !== 'production',
        ssl: false,
      }),
    }),

    AuthModule,
    UsersModule,
    AvatarModule,
  ],
  providers: [
    // Redis 全局 Provider
    redisProvider,

    // 全局 Guards（执行顺序：JwtAuthGuard -> PendingProfileGuard）
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: PendingProfileGuard,
    },
  ],
  exports: [REDIS_CLIENT],
})
export class AppModule {}
