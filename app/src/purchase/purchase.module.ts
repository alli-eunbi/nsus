import { Order } from 'src/order/order.entity';

import { PurchaseService } from './purchase.service';
import { PurchaseHasMenu } from './purchase_has_menu.entity';
import { Purchase } from './purchase.entity';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PurchasesController } from './purchase.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Purchase, PurchaseHasMenu, Order])],
  providers: [PurchaseService],
  controllers: [PurchasesController],
})
export class PurchasesModule {}
