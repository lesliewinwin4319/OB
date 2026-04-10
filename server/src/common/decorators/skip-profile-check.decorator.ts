import { SetMetadata } from '@nestjs/common';

export const SKIP_PROFILE_CHECK_KEY = 'skipProfileCheck';
/**
 * 标记路由跳过 ProfileCompleteGuard 检查
 * 用于：POST /users/me/profile、GET /users/me、POST /auth/wechat/login
 */
export const SkipProfileCheck = () => SetMetadata(SKIP_PROFILE_CHECK_KEY, true);
