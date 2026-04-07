import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * 全局异常过滤器
 * 统一所有错误响应格式：
 * { "statusCode": 400, "errorCode": "BAD_REQUEST", "message": "..." }
 */
@Catch()
class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('GlobalExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = '服务器内部错误';
    let errorCode = 'INTERNAL_SERVER_ERROR';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'string') {
        message = res;
        errorCode = exception.constructor.name.replace('Exception', '').toUpperCase();
      } else {
        // 优先使用业务层显式传入的 code 字段（如 { code: 'PROFILE_INCOMPLETE', message: '...' }）
        // 若未提供，则降级为异常类名推断（如 ForbiddenException -> FORBIDDEN）
        errorCode = (res as any).code
          ?? exception.constructor.name.replace('Exception', '').toUpperCase();
        message = (res as any).message ?? exception.message;
      }
    } else {
      this.logger.error(
        `Unhandled exception on ${request.method} ${request.url}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json({
      statusCode: status,
      errorCode,
      message: Array.isArray(message) ? message.join('; ') : message,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 全局异常过滤器（统一错误格式）
  app.useGlobalFilters(new GlobalExceptionFilter());

  // CORS（iOS 开发阶段使用）
  app.enableCors();

  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  const logger = new Logger('Bootstrap');
  logger.log(`OB Server is running on: http://localhost:${port}`);
}

bootstrap();
