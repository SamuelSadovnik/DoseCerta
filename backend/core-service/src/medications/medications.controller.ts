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
import { MedicationsService } from './medications.service';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { RefillMedicationDto } from './dto/refill-medication.dto';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

@Controller('medications')
export class MedicationsController {
  constructor(private readonly medications: MedicationsService) {}

  @Get()
  list(
    @CurrentUser() user: RequestUser,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.medications.list(user.id, dependentId);
  }

  @Post()
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateMedicationDto) {
    return this.medications.create(user.id, dto);
  }

  @Post(':id/refill')
  refill(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RefillMedicationDto,
  ) {
    return this.medications.refill(user.id, id, dto.quantity);
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    await this.medications.remove(user.id, id);
    return { ok: true };
  }
}
