import { LoginUserDto } from './../user/dto/loginUser.dto';
import { config } from 'dotenv';
import { ConfigService } from '@nestjs/config';
import {
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { UsersService } from '../user/user.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from 'src/user/user.entity';

config();
const configService = new ConfigService();

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(body: LoginUserDto) {
    const { email, password } = body;
    const user = await this.usersService.findOne({ email, password });
    if (!user) {
      throw new NotFoundException();
    }

    const salt = configService.get('SALT');
    const hash = bcrypt.hashSync(password, Number(salt));

    const comparePassword = await bcrypt.compare(password, hash);
    if (!comparePassword) {
      throw new UnauthorizedException();
    }
    if (user && comparePassword) {
      const access_token = this.getAccessToken(user);
      return access_token;
    }
  }

  getAccessToken(user: User) {
    delete user.password;

    try {
      return this.jwtService.sign(
        { ...user },
        {
          secret: configService.get('AUTH_KEY'),
        },
      );
    } catch (e) {
      throw new UnauthorizedException();
    }
  }

  logOut() {
    return `access_token=; HttpOnly; Path=/; Max-Age=0;`;
  }
}
