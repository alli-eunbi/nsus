import { CreateMenuDto } from './menu.dto';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Menu } from './menu.entity';

@Injectable()
export class MenuService {
  constructor(
    @InjectRepository(Menu)
    private readonly menuRepository: Repository<Menu>,
  ) {}

  create(createMenuDto: CreateMenuDto): Promise<Menu> {
    const menu = new Menu();
    console.log(CreateMenuDto);
    menu.name = createMenuDto.name;
    menu.price = createMenuDto.price;

    return this.menuRepository.save(menu);
  }

  async findAll(): Promise<Menu[]> {
    return this.menuRepository.find();
  }

  findOne(id: number): Promise<Menu> {
    return this.menuRepository.findOneBy({ id: id });
  }

  async remove(id: string): Promise<void> {
    await this.menuRepository.delete(id);
  }
}
