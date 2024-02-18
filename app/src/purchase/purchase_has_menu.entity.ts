import { Purchase } from './purchase.entity';
import { Menu } from 'src/menu/menu.entity';
import { Column, Entity, PrimaryGeneratedColumn, ManyToOne } from 'typeorm';
@Entity()
export class PurchaseHasMenu {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Menu, (menu) => menu.order_has_menu)
  menu: Menu;

  @Column()
  count: number;

  @ManyToOne(() => Purchase, (purchase) => purchase.purchase_has_menu)
  purchase: Purchase;
}
