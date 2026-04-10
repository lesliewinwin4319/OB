import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { WechatLoginDto } from './dto/wechat-login.dto';
import { Public } from '../common/decorators/public.decorator';
import { SkipProfileCheck } from '../common/decorators/skip-profile-check.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /api/v1/auth/wechat/login
   *
   * 微信登录 / 注册入口
   * - 新用户：返回 201，status = PENDING_PROFILE
   * - 老用户：返回 200，status 为当前值
   */
  @Public()
  @SkipProfileCheck()
  @Post('wechat/login')
  async wechatLogin(@Body() dto: WechatLoginDto) {
    return this.authService.wechatLogin(dto.code);
  }
}
