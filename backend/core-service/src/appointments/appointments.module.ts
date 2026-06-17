import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from './appointment.entity';
import { Dependent } from '../dependents/dependent.entity';
import { AppointmentsService } from './appointments.service';
import { AppointmentsController } from './appointments.controller';
import { InternalAppointmentsController } from './internal-appointments.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment, Dependent])],
  providers: [AppointmentsService],
  controllers: [AppointmentsController, InternalAppointmentsController],
  exports: [AppointmentsService],
})
export class AppointmentsModule {}
