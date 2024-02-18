import {
  Column,
  Entity,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  OneToMany,
  OneToOne,
  JoinColumn,
  DeleteDateColumn,
} from 'typeorm';
import { PurchaseHasMenu } from './purchase_has_menu.entity';
import { Order } from 'src/order/order.entity';
import { User } from 'src/user/user.entity';

@Entity()
export class Purchase {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  total_price: number;

  @ManyToOne(() => User, (user) => user.purchases)
  user: User;

  @OneToOne(() => Order)
  @JoinColumn()
  order: Order;

  @OneToMany(
    () => PurchaseHasMenu,
    (purchaseHasMenu) => purchaseHasMenu.purchase,
  )
  purchase_has_menu: PurchaseHasMenu[];

  @CreateDateColumn({
    type: 'timestamp',
    default: () => 'CURRENT_TIMESTAMP(6)',
  })
  public created_at: Date;

  @DeleteDateColumn({
    type: 'timestamp',
    default: null,
    onUpdate: 'CURRENT_TIMESTAMP(6)',
  })
  public canceled_at: Date;
}
