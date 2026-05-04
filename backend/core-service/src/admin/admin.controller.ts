import { Controller, ForbiddenException, Get } from '@nestjs/common';
import { MedicationsService } from '../medications/medications.service';
import { DependentsService } from '../dependents/dependents.service';
import { AppointmentsService } from '../appointments/appointments.service';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

/**
 * Aggregated read endpoints used by the admin web panel.
 * Bypasses ownership checks — only admins may reach these.
 */
@Controller('admin')
export class AdminController {
  constructor(
    private readonly medications: MedicationsService,
    private readonly dependents: DependentsService,
    private readonly appointments: AppointmentsService,
  ) {}

  @Get('medications')
  listMedications(@CurrentUser() user: RequestUser) {
    this.requireAdmin(user);
    return this.medications.listAll();
  }

  @Get('dependents')
  listDependents(@CurrentUser() user: RequestUser) {
    this.requireAdmin(user);
    return this.dependents.listAll();
  }

  @Get('appointments')
  listAppointments(@CurrentUser() user: RequestUser) {
    this.requireAdmin(user);
    return this.appointments.listAll();
  }

  private requireAdmin(user: RequestUser) {
    if (user.accountType !== 'admin') {
      throw new ForbiddenException('Acesso restrito a administradores');
    }
  }
}
