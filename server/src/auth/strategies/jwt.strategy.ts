import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { UsersService } from '../../users/users.service';

interface JwtPayload {
  sub: string; // uid
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private readonly usersService: UsersService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'fallback_secret_change_in_production',
    });
  }

  async validate(payload: JwtPayload) {
    const user = await this.usersService.findByUid(payload.sub);
    if (!user) {
      throw new UnauthorizedException({
        errorCode: 'USER_NOT_FOUND',
        message: 'User associated with this token no longer exists',
      });
    }
    return user; // 挂载到 request.user
  }
}
