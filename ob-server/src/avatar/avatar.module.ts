import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AvatarJob } from './entities/avatar-job.entity';
import { AvatarJobService } from './avatar-job.service';

@Module({
  imports: [TypeOrmModule.forFeature([AvatarJob])],
  providers: [AvatarJobService],
  exports: [AvatarJobService],
})
export class AvatarModule {}
