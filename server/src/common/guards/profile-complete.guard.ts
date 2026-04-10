import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserStatus } from '../../users/entities/user.entity';
import { SKIP_PROFILE_CHECK_KEY } from '../decorators/skip-profile-check.decorator';

/**
 * 状态机守卫：PENDING_PROFILE 用户只能访问白名单路由。
 * 白名单路由使用 @SkipProfileCheck() 装饰器标记。
 */
@Injectable()
export class ProfileCompleteGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // 白名单路由豁免检查
    const skip = this.reflector.getAllAndOverride<boolean>(SKIP_PROFILE_CHECK_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (skip) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (user && user.status === UserStatus.PENDING_PROFILE) {
      throw new ForbiddenException({
        errorCode: 'PROFILE_INCOMPLETE',
        message: 'Please complete your profile first',
      });
    }

    return true;
  }
}
