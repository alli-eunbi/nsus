import { Body, Controller, Delete, Get, Post, Put } from '@nestjs/common';
import { CartsService } from './cart.service';

@Controller('carts')
export class CartsController {
  constructor(private readonly cartsService: CartsService) {}

  @Post()
  create(@Body() carts: any): any {
    return this.cartsService.create(carts);
  }

  @Get()
  findOne(): { [key: string]: any } {
    return this.cartsService.findOne();
  }

  @Put()
  update(@Body() carts: any): { [key: string]: any } {
    return this.cartsService.update(carts);
  }

  @Delete()
  remove(): void {
    return this.cartsService.remove();
  }
}
