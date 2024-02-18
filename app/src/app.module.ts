import { PurchasesModule } from './purchase/purchase.module';
import { OrdersModule } from './order/order.module';
import { CartsModule } from './cart/cart.module';
import { MenuModule } from './menu/menu.module';
import { JwtStrategy } from './auth/strategies/jwt.strategy';
import { AuthModule } from './auth/auth.module';
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Users } from './user/user.module';
import { ConfigService } from '@nestjs/config';
import { ConfigModule } from '@nestjs/config';
import { config } from 'dotenv';
import { ServeStaticModule } from '@nestjs/serve-static';
import * as path from 'path';

config();

const configService = new ConfigService();

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: configService.get('MYSQL_HOST'),
      port: 3306,
      username: configService.get('MYSQL_USER_NAME'),
      password: configService.get('MYSQL_ROOT_PASSWORD'),
      database: configService.get('MYSQL_DATABASE'),
      entities: [__dirname + '/**/*.entity{.ts,.js}'],
      synchronize: false,
      autoLoadEntities: true,
    }),
    Users,
    MenuModule,
    AuthModule,
    CartsModule,
    OrdersModule,
    PurchasesModule,
    ConfigModule.forRoot(),
    ServeStaticModule.forRoot({
      rootPath: path.resolve(__dirname, '../../views'),
    }),
  ],
  controllers: [AppController],
  providers: [AppService, JwtStrategy],
})
export class AppModule {}
