import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  async getHello() {
    try {
      const request = await fetch('https://cep.awesomeapi.com.br/json/20521100');
      const data = await request.json();
      return data;
    } catch (error) {
      console.log(error)
      return 'error!';
    }
  }
}
