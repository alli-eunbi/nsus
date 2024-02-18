import { CartsController } from './cart.controller';
import { CartsService } from './cart.service';
import { Module } from '@nestjs/common';

@Module({
  imports: [],
  providers: [CartsService],
  controllers: [CartsController],
})
export class CartsModule {}
