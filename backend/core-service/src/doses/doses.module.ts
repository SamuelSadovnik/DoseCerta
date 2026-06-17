import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Dose } from './dose.entity';
import { Medication } from '../medications/medication.entity';
import { Dependent } from '../dependents/dependent.entity';
import { DosesService } from './doses.service';
import { DosesController } from './doses.controller';
import { InternalDosesController } from './internal-doses.controller';
import { MessagingModule } from '../messaging/messaging.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Dose, Medication, Dependent]),
    MessagingModule,
  ],
  providers: [DosesService],
  controllers: [DosesController, InternalDosesController],
  exports: [DosesService],
})
export class DosesModule {}
