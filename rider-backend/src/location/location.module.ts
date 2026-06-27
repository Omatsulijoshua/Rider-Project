import { Module } from '@nestjs/common';
import { LocationGateway } from './location.gateway';
import { LocationService } from './location.service';

@Module({
  providers: [LocationGateway, LocationService]
})
export class LocationModule {}
