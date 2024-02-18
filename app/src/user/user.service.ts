import { LoginUserDto } from './dto/loginUser.dto';
import {
  Injectable,
  UnprocessableEntityException,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateUserDto } from './dto/createUser.dto';
import { User } from './user.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { config } from 'dotenv';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';

config();
const configService = new ConfigService();

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async create(body: CreateUserDto): Promise<User> {
    const ifExists = await this.usersRepository.findOneBy({
      email: body.email,
    });

    if (ifExists) {
      throw new UnprocessableEntityException('Already Exists');
    }

    const salt = configService.get('SALT');

    const hash = await bcrypt.hash(body.password, Number(salt));

    const user = new User();

    user.email = body.email;
    user.password = hash;
    user.name = body.name;
    return this.usersRepository.save(user);
  }

  @UseGuards(JwtAuthGuard)
  async findAll(): Promise<User[]> {
    return this.usersRepository.find();
  }

  async findOne(loginUserDto: LoginUserDto): Promise<User> {
    const { email, password } = loginUserDto;

    return this.usersRepository.findOneBy({ email: email });
  }

  async remove(id: string): Promise<void> {
    await this.usersRepository.delete(id);
  }
}
