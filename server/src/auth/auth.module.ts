import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { APP_GUARD } from '@nestjs/core';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ProfileCompleteGuard } from '../common/guards/profile-complete.guard';
import { UsersModule } from '../users/users.module';
import { WechatModule } from '../wechat/wechat.module';

@Module({
  imports: [
    UsersModule,
    WechatModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'fallback_secret_change_in_production',
      signOptions: {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    // 全局注册 JWT 守卫（所有路由默认需要鉴权，用 @Public() 豁免）
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    // 全局注册资料完善守卫
    {
      provide: APP_GUARD,
      useClass: ProfileCompleteGuard,
    },
  ],
  exports: [AuthService, JwtModule],
})
export class AuthModule {}
