import {
  Controller,
  Post,
  Get,
  Body,
  Request,
  HttpCode,
  HttpStatus,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { SkipPendingCheck } from '../auth/guards/pending-profile.guard';

class CompleteProfileDto {
  nickname!: string;
  avatarWxUrl?: string;
}

/**
 * Users Controller
 *
 * 所有路由均需 JWT 认证（全局 JwtAuthGuard）。
 * POST /users/me/profile 和 GET /users/me 标记 @SkipPendingCheck，
 * PENDING_PROFILE 状态用户可访问。
 *
 * ---
 * POST /users/me/profile
 *   完善用户资料（昵称 + 头像），触发 PENDING_PROFILE -> ACTIVE 状态转换。
 *
 *   Request Body:
 *     { "nickname": "张三", "avatarWxUrl": "https://wx.qlogo.cn/..." }
 *
 *   Response 200:
 *     { "uid": "ob_123", "nickname": "张三", "avatarUrl": "...", "status": "ACTIVE", "createdAt": "..." }
 *
 *   Error Codes:
 *     400 - 昵称为空 / 超长
 *     409 - 资料已完善（重复提交）
 *
 * ---
 * GET /users/me
 *   获取当前登录用户的个人信息。
 *
 *   Response 200:
 *     { "uid": "ob_123", "nickname": "张三", "avatarUrl": "...", "status": "ACTIVE", "createdAt": "..." }
 *
 * ---
 * GET /users/me/friend-requests
 *   预留接口，本期返回空列表。
 *
 *   Response 200:
 *     { "items": [], "total": 0 }
 */
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('me/profile')
  @HttpCode(HttpStatus.OK)
  @SkipPendingCheck()
  async completeProfile(
    @Request() req: { user: { uid: string } },
    @Body() body: CompleteProfileDto,
  ) {
    if (!body?.nickname || body.nickname.trim() === '') {
      throw new BadRequestException('nickname 不能为空');
    }

    const user = await this.usersService.completeProfile(req.user.uid, {
      nickname: body.nickname,
      avatarWxUrl: body.avatarWxUrl || null,
    });

    return this.usersService.toPublicProfile(user);
  }

  @Get('me')
  @SkipPendingCheck()
  async getMe(@Request() req: { user: { uid: string } }) {
    const user = await this.usersService.findByUid(req.user.uid);

    if (!user) {
      throw new NotFoundException('用户不存在');
    }

    return this.usersService.toPublicProfile(user);
  }

  @Get('me/friend-requests')
  async getFriendRequests() {
    // 预留接口，好友体系后续迭代实现
    return {
      items: [],
      total: 0,
    };
  }
}
