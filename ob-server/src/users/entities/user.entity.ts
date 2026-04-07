import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export enum UserStatus {
  PENDING_PROFILE = 'PENDING_PROFILE',
  ACTIVE = 'ACTIVE',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('increment', { type: 'bigint' })
  id: string;

  @Index('idx_users_uid')
  @Column({ type: 'varchar', length: 32, unique: true })
  uid: string;

  @Index('idx_users_openid')
  @Column({ type: 'varchar', length: 64, unique: true })
  openid: string;

  @Column({ type: 'varchar', length: 64, nullable: true })
  unionid: string | null;

  @Column({ type: 'varchar', length: 64, nullable: true })
  nickname: string | null;

  @Column({ name: 'avatar_wx_url', type: 'text', nullable: true })
  avatarWxUrl: string | null;

  @Column({ name: 'avatar_cdn_url', type: 'text', nullable: true })
  avatarCdnUrl: string | null;

  @Index('idx_users_status')
  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.PENDING_PROFILE,
  })
  status: UserStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
