import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { SetMetadata } from '@nestjs/common';
import { IS_PUBLIC_KEY } from './guards/jwt-auth.guard';

class WechatLoginDto {
  code: string;
}

/**
 * POST /auth/wechat/login
 *
 * 微信登录 / 自动注册接口。
 * 标记为 Public，跳过 JwtAuthGuard。
 *
 * Request Body:
 *   { "code": "微信授权码" }
 *
 * Response 200:
 *   {
 *     "accessToken": "eyJ...",
 *     "user": {
 *       "uid": "ob_123456",
 *       "nickname": null,
 *       "avatarUrl": null,
 *       "status": "PENDING_PROFILE",
 *       "createdAt": "2026-04-05T00:00:00.000Z"
 *     }
 *   }
 *
 * Error Codes:
 *   400 - code 为空
 *   401 - 微信 code 无效或过期
 *   500 - 微信服务不可用 / 并发锁占用
 */
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('wechat/login')
  @HttpCode(HttpStatus.OK)
  @SetMetadata(IS_PUBLIC_KEY, true)
  async wechatLogin(@Body() body: WechatLoginDto) {
    if (!body?.code || body.code.trim() === '') {
      throw new BadRequestException('code 不能为空');
    }

    const result = await this.authService.wechatLogin(body.code.trim());

    return {
      accessToken: result.accessToken,
      user: result.user,
    };
  }
}
