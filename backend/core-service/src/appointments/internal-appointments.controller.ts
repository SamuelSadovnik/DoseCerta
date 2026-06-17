import {
  Controller,
  DefaultValuePipe,
  Get,
  ParseIntPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { InternalApiKeyGuard } from '../common/guards/internal-api-key.guard';
import { AppointmentsService } from './appointments.service';

@UseGuards(InternalApiKeyGuard)
@Controller('internal/appointments')
export class InternalAppointmentsController {
  constructor(private readonly appointments: AppointmentsService) {}

  @Get('pending')
  pending(
    @Query('lookAheadMinutes', new DefaultValuePipe(1440), ParseIntPipe)
    lookAheadMinutes: number,
  ) {
    return this.appointments.pendingForScheduler(lookAheadMinutes);
  }
}
