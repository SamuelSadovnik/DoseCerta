import { Controller, Get, Query } from '@nestjs/common';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';
import { HistoryService } from './history.service';

@Controller('history')
export class HistoryController {
  constructor(private readonly history: HistoryService) {}

  @Get()
  list(
    @CurrentUser() user: RequestUser,
    @Query('month') month?: string,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.history.month(user.id, user.accountType, month, dependentId);
  }
}
