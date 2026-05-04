import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { User } from '../users/user.entity';

/**
 * Factory provider for TypeORM config.
 * Reads env at runtime so the service can be deployed independently.
 */
export const typeOrmConfigFactory = (): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: Number(process.env.DATABASE_PORT) || 5432,
  username: process.env.DATABASE_USER || 'dosecerta',
  password: process.env.DATABASE_PASSWORD || 'dosecerta',
  database: process.env.DATABASE_NAME || 'dosecerta',
  schema: process.env.DATABASE_SCHEMA || 'auth_db',
  entities: [User],
  synchronize: true,
  logging: process.env.NODE_ENV !== 'production',
});
