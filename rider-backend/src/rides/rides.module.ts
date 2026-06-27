import { Module } from '@nestjs/common';
import { RidesGateway } from './rides.gateway';
import { RidesService } from './rides.service';

@Module({
  providers: [RidesGateway, RidesService]
})
export class RidesModule {}
