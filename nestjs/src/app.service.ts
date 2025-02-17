import { Injectable } from '@nestjs/common';

let count = 0;

@Injectable()
export class AppService {
  async getHello(params: {cep: string}) {
    
    try {
      const request = await fetch('https://cep.awesomeapi.com.br/json/'+params.cep);
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
