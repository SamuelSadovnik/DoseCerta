import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfigFactory } from './config/typeorm.config';
import { MedicationsModule } from './medications/medications.module';
import { DependentsModule } from './dependents/dependents.module';
import { AppointmentsModule } from './appointments/appointments.module';
import { DosesModule } from './doses/doses.module';
import { HistoryModule } from './history/history.module';
import { AdminModule } from './admin/admin.module';
import { HealthController } from './health/health.controller';
import { MessagingModule } from './messaging/messaging.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({ useFactory: typeOrmConfigFactory }),
    MedicationsModule,
    DependentsModule,
    AppointmentsModule,
    DosesModule,
    HistoryModule,
    AdminModule,
    MessagingModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
