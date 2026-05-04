import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HttpModule } from '@nestjs/axios';
import { JwtModule } from '@nestjs/jwt';
import { AuthProxyController } from './auth-proxy/auth-proxy.controller';
import { AuthProxyService } from './auth-proxy/auth-proxy.service';
import { CoreProxyController } from './core-proxy/core-proxy.controller';
import { CoreProxyService } from './core-proxy/core-proxy.service';
import { AdminProxyController } from './admin-proxy/admin-proxy.controller';
import { AdminProxyService } from './admin-proxy/admin-proxy.service';
import { JwtStrategy } from './common/strategies/jwt.strategy';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    HttpModule.registerAsync({
      useFactory: () => ({
        timeout: 8000,
        maxRedirects: 3,
      }),
    }),
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: process.env.JWT_SECRET || 'change-me',
      }),
    }),
  ],
  controllers: [
    AuthProxyController,
    CoreProxyController,
    AdminProxyController,
    HealthController,
  ],
  providers: [AuthProxyService, CoreProxyService, AdminProxyService, JwtStrategy],
})
export class AppModule {}
