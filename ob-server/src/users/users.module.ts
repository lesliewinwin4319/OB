import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { SnowflakeService } from '../common/snowflake.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
  ],
  providers: [UsersService, SnowflakeService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
