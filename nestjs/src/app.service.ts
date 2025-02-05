import { Injectable } from '@nestjs/common';

let count = 0;

@Injectable()
export class AppService {
  async getHello() {
    
    try {
      const request = await fetch('https://cep.awesomeapi.com.br/json/70070080');
      const data = await request.json();
      count = count + 1;
      return {
        count,
        data,
      };
    } catch (error) {
      console.log(error)
      return 'error!';
    }
  }
}
