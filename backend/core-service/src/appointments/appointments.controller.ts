import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointments: AppointmentsService) {}

  @Get()
  list(
    @CurrentUser() user: RequestUser,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.appointments.list(user.id, user.accountType, dependentId);
  }

  @Post()
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateAppointmentDto) {
    return this.appointments.create(user.id, dto);
  }

  @Post(':id/confirm')
  confirm(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.appointments.confirm(user.id, id);
  }

  @Post(':id/complete')
  complete(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.appointments.complete(user.id, id);
  }

  @Post(':id/cancel')
  cancel(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.appointments.cancel(user.id, id);
  }

  @Post(':id/reschedule')
  reschedule(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointments.reschedule(user.id, id, dto);
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.appointments.remove(user.id, id);
    return { ok: true };
  }
}
