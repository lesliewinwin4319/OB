import {
  Injectable,
  Logger,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';
import { SnowflakeService } from '../common/snowflake.service';

export interface UpsertUserParams {
  openid: string;
  unionid?: string;
}

export interface CompleteProfileParams {
  nickname: string;
}

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly snowflake: SnowflakeService,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * 幂等 upsert 用户
   *
   * 逻辑：
   * 1. 若 openid 已存在，直接返回现有用户（同一微信账号重复登录）
   * 2. 若不存在，在事务中生成 uid + 创建用户记录（原子性保证）
   *
   * 并发保护由上层 AuthService 的 Redis 分布式锁负责，
   * 这里依赖数据库 UNIQUE 约束作为最后一道防线。
   */
  async upsertByOpenid(params: UpsertUserParams): Promise<User> {
    const { openid, unionid } = params;

    // 先查再建，避免不必要的事务开销
    const existing = await this.userRepo.findOne({ where: { openid } });
    if (existing) {
      this.logger.log(`User login: uid=${existing.uid}`);
      return existing;
    }

    // 新用户：在事务中原子性创建
    return this.dataSource.transaction(async (manager) => {
      // 事务内再次检查，防止极端并发
      const doubleCheck = await manager.findOne(User, { where: { openid } });
      if (doubleCheck) return doubleCheck;

      const uid = this.snowflake.nextId();
      const user = manager.create(User, {
        uid,
        openid,
        unionid: unionid ?? null,
        status: UserStatus.PENDING_PROFILE,
      });

      const saved = await manager.save(User, user);
      this.logger.log(`New user registered: uid=${uid}`);
      return saved;
    });
  }

  /**
   * 完善用户资料：仅接受昵称
   * PENDING_PROFILE -> ACTIVE 状态转换
   *
   * 本期不接收客户端上传头像 URL（微信头像由 iOS 端不传入，头像以字母生成组件展示）。
   * avatar_wx_url / avatar_cdn_url 字段预留，后续头像功能迭代时使用。
   */
  async completeProfile(uid: string, params: CompleteProfileParams): Promise<User> {
    const { nickname } = params;

    const user = await this.userRepo.findOne({ where: { uid } });
    if (!user) {
      throw new NotFoundException('用户不存在');
    }

    if (user.status === UserStatus.ACTIVE) {
      throw new ConflictException('用户资料已完善，请勿重复提交');
    }

    if (!nickname || nickname.trim().length === 0) {
      throw new BadRequestException('昵称不能为空');
    }

    if ([...nickname.trim()].length > 20) {
      throw new BadRequestException('昵称不能超过 20 个字符');
    }

    user.nickname = nickname.trim();
    user.status = UserStatus.ACTIVE;

    const updated = await this.userRepo.save(user);
    this.logger.log(`Profile completed: uid=${uid}`);
    return updated;
  }

  /**
   * 根据 uid 查询用户（带实时状态，不信任 JWT 缓存）
   */
  async findByUid(uid: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { uid } });
  }

  /**
   * 根据 openid 查询用户
   * 用于并发登录场景：锁竞争失败时直接查库，避免抛 500
   */
  async findByOpenid(openid: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { openid } });
  }

  /**
   * 脱敏后的用户信息（对外暴露）
   */
  toPublicProfile(user: User) {
    return {
      uid: user.uid,
      nickname: user.nickname,
      avatarUrl: user.avatarCdnUrl ?? user.avatarWxUrl,
      status: user.status,
      createdAt: user.createdAt,
    };
  }
}
