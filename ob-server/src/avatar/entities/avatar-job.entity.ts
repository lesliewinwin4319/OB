import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export enum AvatarJobStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  DONE = 'DONE',
  FAILED = 'FAILED',
}

@Entity('avatar_jobs')
export class AvatarJob {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @Index('idx_avatar_jobs_uid')
  @Column({ type: 'varchar', length: 32 })
  uid: string;

  @Column({ name: 'wx_url', type: 'text' })
  wxUrl: string;

  @Column({ name: 'cdn_url', type: 'text', nullable: true })
  cdnUrl: string | null;

  @Index('idx_avatar_jobs_status')
  @Column({
    type: 'enum',
    enum: AvatarJobStatus,
    default: AvatarJobStatus.PENDING,
  })
  status: AvatarJobStatus;

  @Column({ name: 'retry_count', type: 'int', default: 0 })
  retryCount: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
