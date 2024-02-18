import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { OrderHasMenu } from './order_has_menu.entity';
import { Order } from './order.entity';
import { User } from 'src/user/user.entity';
import * as fs from 'fs';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
    @InjectRepository(OrderHasMenu)
    private readonly orderHasMenuRepository: Repository<OrderHasMenu>,
  ) {}

  async create(order: Order, user: User) {
    if (!order) {
      throw new NotFoundException();
    }
    const newOrder = new Order();
    newOrder.total_price = order['total_price'];
    newOrder.user = user;
    await this.orderRepository.save(newOrder);

    order['orders'].forEach(async (item) => {
      const newOrderHasMenu = new OrderHasMenu();
      newOrderHasMenu.count = item['count'];
      newOrderHasMenu.menu = item['menu_id'];
      newOrderHasMenu.order = newOrder;
      await this.orderHasMenuRepository.save({ ...newOrderHasMenu });
    });

    try {
      //장바구니 지우기
      fs.writeFileSync('static/carts.json', '');
    } catch (e) {
      console.log(e);
    }
    return newOrder;
  }
  async findOne(id: number) {
    return await this.orderRepository.findOneBy({ id });
  }

  async remove(id: string): Promise<void> {
    await this.orderRepository.delete(id);
  }
}
