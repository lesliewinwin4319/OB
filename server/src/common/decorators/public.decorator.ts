import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
/**
 * 标记路由跳过 JWT 鉴权（如登录接口）
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
