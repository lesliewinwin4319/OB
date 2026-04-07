import {
  Injectable,
  Logger,
  InternalServerErrorException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRedis } from '../common/redis.decorator';
import Redis from 'ioredis';
import { WechatService } from './wechat.service';
import { UsersService } from '../users/users.service';
import { User } from '../users/entities/user.entity';

export interface JwtPayload {
  sub: string;   // uid
  status: string;
  iat?: number;
  exp?: number;
}

export interface LoginResult {
  accessToken: string;
  user: ReturnType<UsersService['toPublicProfile']>;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  // Redis 锁 TTL（秒）
  private readonly LOCK_TTL = 5;

  constructor(
    private readonly wechatService: WechatService,
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  /**
   * 微信登录主流程
   *
   * 1. 调用微信接口换取 openid（WechatService 负责 mock/真实切换）
   * 2. Redis 分布式锁防止同一 openid 并发注册竞争
   * 3. 幂等 upsert 用户
   * 4. 签发 JWT
   */
  async wechatLogin(code: string): Promise<LoginResult> {
    // Step 1: 微信 code 换 openid
    const { openid, unionid } = await this.wechatService.code2Session(code);

    const lockKey = `lock:register:${openid}`;
    const lockValue = `${Date.now()}_${Math.random()}`;

    // Step 2: 获取分布式锁（SET NX EX）
    const acquired = await this.redis.set(lockKey, lockValue, 'EX', this.LOCK_TTL, 'NX');

    if (!acquired) {
      // 锁已被持有，说明另一个并发请求正在处理同一 openid 的注册流程。
      // 由于 openid 有 UNIQUE 约束，upsertByOpenid 本身已保证幂等性，
      // 此处等待 100ms 让先行请求完成写库，再直接查库返回，避免抛 500。
      this.logger.warn(`Concurrent login detected for openid hash (lock held), falling back to DB lookup`);
      await new Promise((resolve) => setTimeout(resolve, 100));
      const existingUser = await this.usersService.findByOpenid(openid);
      if (existingUser) {
        return {
          accessToken: this.signToken(existingUser),
          user: this.usersService.toPublicProfile(existingUser),
        };
      }
      // 极端情况：等待后仍未找到用户（先行请求也在创建中），再等一次
      await new Promise((resolve) => setTimeout(resolve, 200));
      const retryUser = await this.usersService.findByOpenid(openid);
      if (retryUser) {
        return {
          accessToken: this.signToken(retryUser),
          user: this.usersService.toPublicProfile(retryUser),
        };
      }
      // 若两次重试后仍无结果，才降级为错误（理论上不会触发）
      throw new InternalServerErrorException('登录请求过于频繁，请稍后重试');
    }

    try {
      // Step 3: 幂等 upsert 用户
      const user = await this.usersService.upsertByOpenid({ openid, unionid });

      // Step 4: 签发 JWT
      const token = this.signToken(user);

      return {
        accessToken: token,
        user: this.usersService.toPublicProfile(user),
      };
    } finally {
      // 释放锁时校验 value，确保只释放自己持有的锁（防止误释放）
      const script = `
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
        else
          return 0
        end
      `;
      await this.redis.eval(script, 1, lockKey, lockValue);
    }
  }

  signToken(user: User): string {
    const payload: JwtPayload = {
      sub: user.uid,
      status: user.status,
    };
    return this.jwtService.sign(payload);
  }
}
