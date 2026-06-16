import { Controller, DefaultValuePipe, Get, ParseIntPipe, Query, UseGuards } from '@nestjs/common';
import { InternalApiKeyGuard } from '../common/guards/internal-api-key.guard';
import { DosesService } from './doses.service';

@UseGuards(InternalApiKeyGuard)
@Controller('internal/doses')
export class InternalDosesController {
  constructor(private readonly doses: DosesService) {}

  @Get('pending')
  pending(
    @Query('lookAheadMinutes', new DefaultValuePipe(1440), ParseIntPipe)
    lookAheadMinutes: number,
  ) {
    return this.doses.pendingForScheduler(lookAheadMinutes);
  }
}
