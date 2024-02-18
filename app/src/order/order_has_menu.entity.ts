import { Order } from 'src/order/order.entity';
import { Menu } from 'src/menu/menu.entity';
import { Column, Entity, PrimaryGeneratedColumn, ManyToOne } from 'typeorm';

@Entity()
export class OrderHasMenu {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Menu, (menu) => menu.order_has_menu)
  menu: Menu;

  @Column()
  count: number;

  @ManyToOne(() => Order, (order) => order.order_has_menu)
  order: Order;
}
