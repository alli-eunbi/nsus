import { PurchaseService } from './purchase.service';
import { Purchase } from './purchase.entity';
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
import { UseGuards, UnauthorizedException } from '@nestjs/common';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';

@Controller('purchases')
export class PurchasesController {
  constructor(private readonly purchaseService: PurchaseService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() purchase, @Request() req): Promise<Purchase> {
    const user = req.user;
    if (!req.user) {
      throw new UnauthorizedException();
    }
    return this.purchaseService.create(purchase, user);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<Purchase> {
    return this.purchaseService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string): Promise<void> {
    return this.purchaseService.remove(id);
  }
}
