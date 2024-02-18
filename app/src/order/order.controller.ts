import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  ParseIntPipe,
  Request,
} from '@nestjs/common';
import { Order } from './order.entity';
import { UseGuards, UnauthorizedException } from '@nestjs/common';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { OrdersService } from './order.service';
import * as path from 'path';

@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Request() req) {
    const user = req.user;
    if (!req.user) {
      throw new UnauthorizedException();
    }
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const order = require(path.resolve(
      __dirname,
      '../../../static/carts.json',
    ));
    return this.ordersService.create(order, user);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.ordersService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.ordersService.remove(id);
  }
}
