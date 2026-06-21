import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { MedicationsService } from './medications.service';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { RefillMedicationDto } from './dto/refill-medication.dto';
import { UpdateStockDto } from './dto/update-stock.dto';
import { CurrentUser, RequestUser } from '../common/current-user.decorator';

@Controller('medications')
export class MedicationsController {
  constructor(private readonly medications: MedicationsService) {}

  @Get()
  list(
    @CurrentUser() user: RequestUser,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.medications.list(user.id, user.accountType, dependentId);
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

  @Patch(':id/stock')
  updateStock(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStockDto,
  ) {
    return this.medications.updateStock(user.id, id, dto.quantity);
  }

  @Patch(':id/end')
  endTreatment(
    @CurrentUser() user: RequestUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.medications.endTreatment(user.id, id);
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
