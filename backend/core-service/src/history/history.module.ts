import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Dose } from '../doses/dose.entity';
import { Dependent } from '../dependents/dependent.entity';
import { HistoryController } from './history.controller';
import { HistoryService } from './history.service';

@Module({
  imports: [TypeOrmModule.forFeature([Dose, Dependent])],
  providers: [HistoryService],
  controllers: [HistoryController],
})
export class HistoryModule {}
