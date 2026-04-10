import { Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { WechatService } from '../wechat/wechat.service';
import { UsersService } from '../users/users.service';
import { User } from '../users/entities/user.entity';

export interface AuthResult {
  token: string;
  user: {
    uid: string;
    status: string;
    nickname: string | null;
    avatarUrl: string | null;
  };
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly wechatService: WechatService,
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * 微信登录核心流程：
   * 1. 用 code 换取 openId/unionId
   * 2. 查询用户是否存在
   * 3. 不存在则创建新用户（原子操作，唯一索引防并发重复）
   * 4. 签发 JWT
   */
  async wechatLogin(code: string): Promise<AuthResult> {
    // Step 1: 换取微信会话
    const session = await this.wechatService.code2Session(code);
    this.logger.log(`WeChat session acquired for openId: ${session.openId.substring(0, 8)}***`);

    // Step 2 + 3: 查找或创建用户（幂等）
    const user = await this.usersService.findOrCreate(session.openId, session.unionId);

    // Step 4: 签发 JWT
    const token = this.signToken(user);

    return {
      token,
      user: this.serializeUser(user),
    };
  }

  signToken(user: User): string {
    return this.jwtService.sign({ sub: user.uid });
  }

  private serializeUser(user: User) {
    return {
      uid: user.uid,
      status: user.status,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
    };
  }
}
