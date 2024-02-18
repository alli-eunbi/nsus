import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { OrderHasMenu } from '../order/order_has_menu.entity';

@Entity()
export class Menu {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 30 })
  name: string;

  @Column()
  price: number;

  @OneToMany(() => OrderHasMenu, (OrderHasMenu) => OrderHasMenu.menu)
  order_has_menu: OrderHasMenu[];
}
