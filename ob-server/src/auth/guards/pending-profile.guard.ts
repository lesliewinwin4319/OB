import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { Request } from 'express';
import { UsersService } from '../../users/users.service';
import { UserStatus } from '../../users/entities/user.entity';

/**
 * PendingProfileGuard
 *
 * 确保只有 ACTIVE 用户才能访问受保护资源。
 * 以数据库实时状态为准，不信任 JWT payload 中的 status 字段，
 * 防止用户在 profile 完善前的 token 仍能访问 ACTIVE 专属接口。
 *
 * 白名单（即使 PENDING_PROFILE 也可访问）：
 * - POST /auth/wechat/login （Public 路由，JwtAuthGuard 已跳过，此 Guard 不会触发）
 * - POST /users/me/profile
 * - GET  /users/me
 *
 * 实现方式：在 Controller 方法上添加 @SkipPendingCheck() 装饰器即可加入白名单。
 */

export const SKIP_PENDING_CHECK_KEY = 'skipPendingCheck';

import { SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const SkipPendingCheck = () =>
  SetMetadata(SKIP_PENDING_CHECK_KEY, true);

@Injectable()
export class PendingProfileGuard implements CanActivate {
  private readonly logger = new Logger(PendingProfileGuard.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // 检查白名单标记
    const skip = this.reflector.getAllAndOverride<boolean>(
      SKIP_PENDING_CHECK_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (skip) return true;

    const request = context.switchToHttp().getRequest<Request & { user?: any }>();
    const uid: string | undefined = request.user?.uid;

    if (!uid) {
      // Public 路由，JwtAuthGuard 已跳过，无需检查 profile 状态
      return true;
    }

    // 以 DB 实时状态为准
    const user = await this.usersService.findByUid(uid);

    if (!user || user.status !== UserStatus.ACTIVE) {
      this.logger.warn(`PENDING user attempted to access protected route: uid=${uid}`);
      throw new ForbiddenException({ code: 'PROFILE_INCOMPLETE', message: '请先完善个人资料' });
    }

    return true;
  }
}
