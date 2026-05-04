import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Medication } from './medication.entity';
import { MedicationsService } from './medications.service';
import { MedicationsController } from './medications.controller';
import { DosesModule } from '../doses/doses.module';
import { Dependent } from '../dependents/dependent.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Medication, Dependent]), DosesModule],
  providers: [MedicationsService],
  controllers: [MedicationsController],
  exports: [MedicationsService],
})
export class MedicationsModule {}
