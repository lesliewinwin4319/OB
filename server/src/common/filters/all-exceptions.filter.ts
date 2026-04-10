import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

interface ErrorResponse {
  errorCode: string;
  message: string;
  statusCode: number;
  timestamp: string;
  path: string;
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let errorCode = 'INTERNAL_SERVER_ERROR';
    let message = 'An unexpected error occurred';

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const resp = exceptionResponse as Record<string, unknown>;
        errorCode = (resp['errorCode'] as string) || this.httpStatusToErrorCode(statusCode);
        // NestJS ValidationPipe 产生的错误格式
        if (Array.isArray(resp['message'])) {
          message = (resp['message'] as string[]).join('; ');
          errorCode = 'VALIDATION_ERROR';
        } else {
          message = (resp['message'] as string) || message;
        }
      } else if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
        errorCode = this.httpStatusToErrorCode(statusCode);
      }
    } else if (exception instanceof Error) {
      // 数据库唯一约束冲突等底层错误
      const dbErr = exception as unknown as Record<string, unknown>;
      if (dbErr['code'] === '23505') {
        statusCode = HttpStatus.CONFLICT;
        errorCode = 'CONFLICT';
        message = 'Resource already exists';
      } else {
        this.logger.error(`Unhandled exception: ${exception.message}`, exception.stack);
      }
    }

    const errorBody: ErrorResponse = {
      errorCode,
      message,
      statusCode,
      timestamp: new Date().toISOString(),
      path: request.url,
    };

    response.status(statusCode).json(errorBody);
  }

  private httpStatusToErrorCode(status: number): string {
    const map: Record<number, string> = {
      400: 'BAD_REQUEST',
      401: 'UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      422: 'UNPROCESSABLE_ENTITY',
      429: 'TOO_MANY_REQUESTS',
      500: 'INTERNAL_SERVER_ERROR',
    };
    return map[status] || 'HTTP_ERROR';
  }
}
