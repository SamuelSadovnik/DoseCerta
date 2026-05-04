import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Dose } from './dose.entity';
import { Medication } from '../medications/medication.entity';
import { Dependent } from '../dependents/dependent.entity';
import { DosesService } from './doses.service';
import { DosesController } from './doses.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Dose, Medication, Dependent])],
  providers: [DosesService],
  controllers: [DosesController],
  exports: [DosesService],
})
export class DosesModule {}
