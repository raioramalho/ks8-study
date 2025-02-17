import { Injectable } from '@nestjs/common';

let count = 0;

@Injectable()
export class AppService {
  private readonly ENV = process.env.ENV;  
  private readonly DATABASE_URL = process.env.DATABASE_URL;
  async getHello(params: {cep: string}) {
    
    try {
      const request = await fetch('https://cep.awesomeapi.com.br/json/'+params.cep);
      const data = await request.json();
      count = count + 1;
      return {
        env: this.ENV,
        database: this.DATABASE_URL,
        cep: params.cep,
        count,
        data,
      };
    } catch (error) {
      console.log(error)
      return 'error!';
    }
  }
}
