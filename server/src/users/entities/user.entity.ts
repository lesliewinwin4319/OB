import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
} from 'typeorm';

export enum UserStatus {
  PENDING_PROFILE = 'PENDING_PROFILE',
  ACTIVE = 'ACTIVE',
  BANNED = 'BANNED',
}

@Entity('users')
export class User {
  /**
   * 雪花算法生成的 64 位整型 ID
   * 存为 string 避免 JS Number 精度丢失（JS 最大安全整数 2^53-1 < 2^63-1）
   */
  @PrimaryColumn({ type: 'bigint', name: 'uid' })
  uid: string;

  @Column({ name: 'open_id', length: 64, unique: true })
  openId: string;

  @Column({ name: 'union_id', length: 64, nullable: true })
  unionId: string | null;

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.PENDING_PROFILE,
  })
  status: UserStatus;

  @Column({ length: 20, nullable: true })
  nickname: string | null;

  @Column({ name: 'avatar_url', type: 'text', nullable: true })
  avatarUrl: string | null;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
