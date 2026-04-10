import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { DataSource } from 'typeorm';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // --- 全局前缀 ---
  app.setGlobalPrefix('api/v1');

  // --- 全局 Pipe：自动校验 DTO ---
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,       // 剔除 DTO 中未声明的字段
      forbidNonWhitelisted: false,
      transform: true,       // 自动转换类型
      stopAtFirstError: false,
    }),
  );

  // --- 全局异常过滤器 ---
  app.useGlobalFilters(new AllExceptionsFilter());

  // --- CORS（冷启动阶段放开，生产环境收紧） ---
  app.enableCors({
    origin: process.env.NODE_ENV === 'production' ? false : '*',
  });

  // --- TypeORM Migration 自动执行 ---
  const dataSource = app.get(DataSource);
  if (dataSource.isInitialized) {
    const pending = await dataSource.showMigrations();
    if (pending) {
      logger.log('Running pending database migrations...');
      await dataSource.runMigrations({ transaction: 'each' });
      logger.log('Migrations completed.');
    } else {
      logger.log('No pending migrations.');
    }
  }

  const port = parseInt(process.env.PORT || '3000', 10);
  await app.listen(port);
  logger.log(`OB Server running on port ${port}`);
}

bootstrap();
