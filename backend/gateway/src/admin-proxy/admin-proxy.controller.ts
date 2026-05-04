import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { AdminProxyService, AdminUser } from './admin-proxy.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AdminGuard } from '../common/guards/admin.guard';

@UseGuards(JwtAuthGuard, AdminGuard)
@Controller('admin')
export class AdminProxyController {
  constructor(private readonly proxy: AdminProxyService) {}

  @Get('users')
  listUsers(@Req() req: Request) {
    return this.proxy.forwardToAuth('users', req.user as AdminUser);
  }

  @Get('medications')
  listMedications(@Req() req: Request) {
    return this.proxy.forwardToCore(
      'admin/medications',
      req.user as AdminUser,
    );
  }

  @Get('dependents')
  listDependents(@Req() req: Request) {
    return this.proxy.forwardToCore('admin/dependents', req.user as AdminUser);
  }

  @Get('appointments')
  listAppointments(@Req() req: Request) {
    return this.proxy.forwardToCore(
      'admin/appointments',
      req.user as AdminUser,
    );
  }
}
