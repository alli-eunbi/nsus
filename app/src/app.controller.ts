import {
  Controller,
  Get,
  Request,
  UseGuards,
  Post,
  Res,
  Body,
  Delete,
} from '@nestjs/common';
import { AppService } from './app.service';
import { AuthService } from './auth/auth.service';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { LoginUserDto } from './user/dto/loginUser.dto';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly authService: AuthService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Post('auth/login')
  async login(@Body() body: LoginUserDto, @Res({ passthrough: true }) res) {
    const access_token = await this.authService.validateUser({ ...body });
    res.cookie('access_token', access_token, { HttpOnly: true });
    return access_token;
  }

  @UseGuards(JwtAuthGuard)
  @Get('/auth/profile')
  getProfile(@Request() req) {
    return req.user;
  }

  @UseGuards(JwtAuthGuard)
  @Delete('/auth/logout')
  async logOut(@Res() response) {
    response.setHeader('Set-Cookie', this.authService.logOut());
    return response.sendStatus(204);
  }
}
