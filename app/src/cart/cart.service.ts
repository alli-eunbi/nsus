import { Injectable, NotFoundException } from '@nestjs/common';
import * as fs from 'fs';

@Injectable()
export class CartsService {
  create(cart: { [key: string]: any }): { [key: string]: any } {
    try {
      const new_cart = JSON.stringify(cart);
      fs.writeFileSync('static/carts.json', new_cart);
      return cart;
    } catch (e) {
      console.log(e);
    }
  }

  findOne(): any {
    try {
      const carts = fs.readFileSync('static/carts.json', 'utf-8');
      if (!carts) {
        throw new NotFoundException();
      }
      const cart_object = JSON.parse(carts);
      return cart_object;
    } catch (e) {
      console.log(e);
    }
  }

  update(cart: { [key: string]: any }): { [key: string]: any } {
    try {
      const new_cart = JSON.stringify(cart);
      fs.writeFileSync('static/carts.json', new_cart);
      return cart;
    } catch (e) {
      console.log(e);
    }
  }

  remove(): void {
    try {
      fs.writeFileSync('static/carts.json', '');
    } catch (e) {
      console.log(e);
    }
  }
}
