import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { DosesService } from './doses.service';
import { PostponeDoseDto } from './dto/postpone-dose.dto';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

@Controller('doses')
export class DosesController {
  constructor(private readonly doses: DosesService) {}

  @Get()
  schedule(
    @CurrentUser() user: RequestUser,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.doses.schedule(user.id, user.accountType, dependentId);
  }

  @Get('today')
  today(
    @CurrentUser() user: RequestUser,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.doses.today(user.id, user.accountType, dependentId);
  }

  @Post(':id/take')
  take(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.doses.take(user.id, id);
  }

  @Post(':id/postpone')
  postpone(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PostponeDoseDto,
  ) {
    return this.doses.postpone(user.id, id, dto.minutes);
  }
}
