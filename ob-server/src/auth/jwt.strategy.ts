import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload } from './auth.service';

/**
 * JWT 策略
 * 从 Authorization: Bearer <token> 提取并验证 JWT。
 * validate() 返回值会被挂载到 request.user 上。
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET', 'fallback_secret'),
    });
  }

  validate(payload: JwtPayload) {
    // 注意：status 字段仅作参考，权限校验以 DB 实时状态为准（PendingProfileGuard）
    return {
      uid: payload.sub,
      status: payload.status,
    };
  }
}
