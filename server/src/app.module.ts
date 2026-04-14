import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from './config/config.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { WechatModule } from './wechat/wechat.module';
import { HealthModule } from './health/health.module';
import { DatabaseConfig } from './config/database.config';
import { UploadModule } from './upload/upload.module';

@Module({
  imports: [
    // 配置模块（最先加载，其他模块依赖）
    ConfigModule,

    // 数据库连接（异步配置，从环境变量读取）
    TypeOrmModule.forRootAsync({
      useClass: DatabaseConfig,
    }),

    // 业务模块
    WechatModule,
    AuthModule,
    UsersModule,
    HealthModule,
    UploadModule,
  ],
})
export class AppModule {}
