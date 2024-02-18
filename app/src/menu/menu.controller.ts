import { CreateMenuDto } from './menu.dto';
import { Menu } from './menu.entity';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  ParseIntPipe,
} from '@nestjs/common';
import { MenuService } from './menu.service';

@Controller('menu')
export class MenuController {
  constructor(private readonly menuService: MenuService) {}

  @Post()
  create(@Body() createMenuDto: CreateMenuDto): Promise<Menu> {
    console.log(createMenuDto);
    return this.menuService.create(createMenuDto);
  }

  @Get()
  findAll(): Promise<Menu[]> {
    return this.menuService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<Menu> {
    return this.menuService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string): Promise<void> {
    return this.menuService.remove(id);
  }
}
