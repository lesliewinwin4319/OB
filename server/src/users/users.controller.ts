import {
  Controller,
  Get,
  Post,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { User } from './entities/user.entity';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SkipProfileCheck } from '../common/decorators/skip-profile-check.decorator';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * GET /api/v1/users/me
   *
   * 获取当前登录用户的基本信息。
   * PENDING_PROFILE 用户也可访问（用于判断是否需要跳转资料填写页）。
   *
   * Response 200:
   * {
   *   uid: string,
   *   status: 'PENDING_PROFILE' | 'ACTIVE' | 'BANNED',
   *   nickname: string | null,
   *   avatarUrl: string | null,
   *   createdAt: string (ISO 8601)
   * }
   */
  @SkipProfileCheck()
  @Get('me')
  getMe(@CurrentUser() user: User) {
    return {
      uid: user.uid,
      status: user.status,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
    };
  }

  /**
   * POST /api/v1/users/me/profile
   *
   * 首次完善或更新用户资料。
   * - PENDING_PROFILE 用户调用后状态升级为 ACTIVE
   * - ACTIVE 用户调用仅更新 nickname / avatarUrl，状态不变
   *
   * Request Body:
   * {
   *   nickname: string  (必填, 1-20 字符)
   *   avatarUrl?: string (可选, 合法 URL)
   * }
   *
   * Response 200:
   * {
   *   uid: string,
   *   status: 'ACTIVE',
   *   nickname: string,
   *   avatarUrl: string | null,
   *   updatedAt: string (ISO 8601)
   * }
   *
   * Error:
   * 400 VALIDATION_ERROR — 字段校验失败
   * 404 USER_NOT_FOUND   — 用户不存在（极端情况）
   */
  @SkipProfileCheck()
  @Post('me/profile')
  @HttpCode(HttpStatus.OK)
  async updateProfile(
    @CurrentUser() user: User,
    @Body() dto: UpdateProfileDto,
  ) {
    const updated = await this.usersService.updateProfile(user, dto);
    return {
      uid: updated.uid,
      status: updated.status,
      nickname: updated.nickname,
      avatarUrl: updated.avatarUrl,
      updatedAt: updated.updatedAt,
    };
  }

  /**
   * GET /api/v1/users/me/friend-requests
   *
   * 获取当前用户收到的好友请求列表（预留接口，好友体系尚未实现）。
   * 当前返回空列表，结构已定义供 Louis 提前对接。
   *
   * Response 200:
   * {
   *   items: [],
   *   total: 0
   * }
   */
  @Get('me/friend-requests')
  getFriendRequests() {
    // 好友体系 Sprint 2 实现，当前返回占位数据
    return {
      items: [],
      total: 0,
    };
  }
}
