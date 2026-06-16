import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { DependentsService } from './dependents.service';
import { CreateDependentDto } from './dto/create-dependent.dto';
import { LinkDependentDto } from './dto/link-dependent.dto';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

@Controller('dependents')
export class DependentsController {
  constructor(private readonly dependents: DependentsService) {}

  @Get()
  list(@CurrentUser() user: RequestUser) {
    return this.dependents.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateDependentDto) {
    return this.dependents.create(user, dto);
  }

  @Post('link')
  link(@CurrentUser() user: RequestUser, @Body() dto: LinkDependentDto) {
    return this.dependents.link(user.id, dto.code);
  }

  @Post('unlink')
  async unlink(@CurrentUser() user: RequestUser) {
    await this.dependents.unlink(user.id);
    return { ok: true };
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.dependents.remove(user.id, id);
    return { ok: true };
  }
}
