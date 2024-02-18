import { PurchaseHasMenu } from './purchase_has_menu.entity';
import { Purchase } from './purchase.entity';
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { User } from 'src/user/user.entity';
import { Order } from 'src/order/order.entity';

@Injectable()
export class PurchaseService {
  constructor(
    @InjectRepository(Purchase)
    private readonly purchaseRepository: Repository<Purchase>,
    @InjectRepository(PurchaseHasMenu)
    private readonly purchaseHasMenuRepository: Repository<PurchaseHasMenu>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
  ) {}

  async create(purchase, user: User) {
    if (!purchase) {
      throw new NotFoundException();
    }
    await this.orderRepository.update(purchase['order_id'], {
      if_purchased: true,
    });

    const new_purchase = new Purchase();
    new_purchase.total_price = purchase['total_price'];
    new_purchase.user = user;
    new_purchase.order = purchase['order_id'];
    await this.purchaseRepository.save(new_purchase);

    purchase['orders'].forEach(async (item) => {
      const new_purchaseHasMenu = new PurchaseHasMenu();
      new_purchaseHasMenu.count = item['count'];
      new_purchaseHasMenu.menu = item['menu_id'];
      new_purchaseHasMenu.purchase = new_purchase;
      await this.purchaseHasMenuRepository.save(new_purchaseHasMenu);
    });
    return new_purchase;
  }

  if_canceled(id: number) {
    this.purchaseRepository.update(id, { canceled_at: new Date() });
  }

  findOne(id: number) {
    return this.purchaseRepository.findOneBy({ id });
  }

  async remove(id: string) {
    await this.purchaseRepository.delete(id);
  }
}
