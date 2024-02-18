import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { jwtConstants } from '../constants';

const tokenHandler = (req: Request) => {
  const token = req.headers['authorization'];
  return token;
};
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: tokenHandler,
      secretOrKey: jwtConstants.secret,
      ignoreExpiration: false,
    });
  }

  async validate(payload) {
    return { uuid: payload.uuid, email: payload.email, name: payload.name };
  }
}
