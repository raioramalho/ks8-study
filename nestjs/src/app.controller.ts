import { Controller, Get, Logger, Query } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(@Query() params: {cep: string}) {
    Logger.debug(`Buscando cep: ${params.cep}`);
    return this.appService.getHello(params);
  }
}
