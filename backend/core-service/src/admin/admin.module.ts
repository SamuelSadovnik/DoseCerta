import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { MedicationsModule } from '../medications/medications.module';
import { DependentsModule } from '../dependents/dependents.module';
import { AppointmentsModule } from '../appointments/appointments.module';

@Module({
  imports: [MedicationsModule, DependentsModule, AppointmentsModule],
  controllers: [AdminController],
})
export class AdminModule {}
