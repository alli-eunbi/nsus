import { User } from '../user/user.entity';
import { OrdersController } from './order.controller';
import { OrdersService } from './order.service';
import { OrderHasMenu } from './order_has_menu.entity';
import { Order } from 'src/order/order.entity';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [TypeOrmModule.forFeature([Order, OrderHasMenu, User])],
  providers: [OrdersService],
  controllers: [OrdersController],
  exports: [OrdersModule],
})
export class OrdersModule {}
