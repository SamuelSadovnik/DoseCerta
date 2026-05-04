import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Medication } from '../medications/medication.entity';
import { Dependent } from '../dependents/dependent.entity';
import { Appointment } from '../appointments/appointment.entity';
import { Dose } from '../doses/dose.entity';

export const typeOrmConfigFactory = (): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: Number(process.env.DATABASE_PORT) || 5432,
  username: process.env.DATABASE_USER || 'dosecerta',
  password: process.env.DATABASE_PASSWORD || 'dosecerta',
  database: process.env.DATABASE_NAME || 'dosecerta',
  schema: process.env.DATABASE_SCHEMA || 'core_db',
  entities: [Medication, Dependent, Appointment, Dose],
  synchronize: true,
  logging: process.env.NODE_ENV !== 'production',
});
