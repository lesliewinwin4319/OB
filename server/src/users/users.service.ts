import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { generateSnowflakeId } from '../common/snowflake';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * 查找用户，若不存在则创建（幂等）
   *
   * 使用事务 + INSERT ... ON CONFLICT DO NOTHING 保证并发安全：
   * 即使两个请求同时到达，数据库唯一索引也只会创建一条记录，
   * 第二个请求会查询到已存在的记录并正常返回。
   */
  async findOrCreate(openId: string, unionId: string | null): Promise<User> {
    // 先查找（热路径：已注册用户直接命中）
    const existing = await this.userRepo.findOne({ where: { openId } });
    if (existing) {
      // 若 unionId 有更新（首次授权没有，后续获得），顺带更新
      if (unionId && !existing.unionId) {
        existing.unionId = unionId;
        await this.userRepo.save(existing);
      }
      return existing;
    }

    // 新用户：事务内创建，防并发重复
    return this.dataSource.transaction(async (manager) => {
      // 使用 INSERT ... ON CONFLICT DO NOTHING 处理并发创建
      const uid = generateSnowflakeId();
      await manager
        .createQueryBuilder()
        .insert()
        .into(User)
        .values({
          uid,
          openId,
          unionId: unionId || null,
          status: UserStatus.PENDING_PROFILE,
        })
        .orIgnore() // ON CONFLICT DO NOTHING
        .execute();

      // 无论是否实际插入，都查询最终记录
      const user = await manager.findOne(User, { where: { openId } });
      if (!user) {
        throw new Error(`Failed to find or create user for openId: ${openId}`);
      }
      this.logger.log(`User ${user.uid} loaded (status: ${user.status})`);
      return user;
    });
  }

  /**
   * 根据 uid 查询用户（JWT 验证使用）
   */
  async findByUid(uid: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { uid } });
  }

  /**
   * 完善用户资料，状态机转换：PENDING_PROFILE → ACTIVE
   *
   * ACTIVE 用户也可调用此接口更新资料（不回退状态）。
   */
  async updateProfile(user: User, dto: UpdateProfileDto): Promise<User> {
    return this.dataSource.transaction(async (manager) => {
      const target = await manager.findOne(User, {
        where: { uid: user.uid },
        lock: { mode: 'pessimistic_write' }, // 防并发覆盖
      });

      if (!target) {
        throw new NotFoundException({
          errorCode: 'USER_NOT_FOUND',
          message: 'User not found',
        });
      }

      target.nickname = dto.nickname;
      if (dto.avatarUrl !== undefined) {
        target.avatarUrl = dto.avatarUrl;
      }

      // 状态机：只允许从 PENDING_PROFILE 升级到 ACTIVE，不降级
      if (target.status === UserStatus.PENDING_PROFILE) {
        target.status = UserStatus.ACTIVE;
      }

      return manager.save(target);
    });
  }
}
