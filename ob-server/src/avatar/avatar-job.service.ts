import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AvatarJob, AvatarJobStatus } from './entities/avatar-job.entity';

/**
 * 头像异步处理服务
 *
 * 本期仅实现任务创建（入库）。
 * BullMQ Worker（从微信 URL 下载并上传至 CDN）留待后续迭代实现。
 */
@Injectable()
export class AvatarJobService {
  private readonly logger = new Logger(AvatarJobService.name);

  constructor(
    @InjectRepository(AvatarJob)
    private readonly avatarJobRepo: Repository<AvatarJob>,
  ) {}

  /**
   * 创建头像处理任务
   * 在用户完善资料时调用，将微信头像 URL 入库等待后台处理
   */
  async createJob(uid: string, wxUrl: string): Promise<AvatarJob> {
    const job = this.avatarJobRepo.create({
      uid,
      wxUrl,
      status: AvatarJobStatus.PENDING,
      retryCount: 0,
    });

    const saved = await this.avatarJobRepo.save(job);
    this.logger.log(`Avatar job created: jobId=${saved.id}, uid=${uid}`);
    return saved;
  }

  /**
   * 查询用户最新的已完成头像任务（用于获取 CDN URL）
   */
  async getLatestDoneJob(uid: string): Promise<AvatarJob | null> {
    return this.avatarJobRepo.findOne({
      where: { uid, status: AvatarJobStatus.DONE },
      order: { createdAt: 'DESC' },
    });
  }
}
