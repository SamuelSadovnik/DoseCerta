import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { CoreProxyService, ForwardUser } from './core-proxy.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

/**
 * Forwards every authenticated /api/* call to core-service,
 * stripping the JWT and re-injecting validated user info as headers.
 *
 * Routes mirror the contracts in docs/api_contracts.md.
 */
@UseGuards(JwtAuthGuard)
@Controller()
export class CoreProxyController {
  constructor(private readonly proxy: CoreProxyService) {}

  // ----- Medications -----
  @Get('medications')
  listMedications(
    @Req() req: Request,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'medications',
      user: req.user as ForwardUser,
      query: dependentId ? { dependentId } : undefined,
    });
  }

  @Post('medications')
  createMedication(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forward({
      method: 'POST',
      path: 'medications',
      user: req.user as ForwardUser,
      body,
    });
  }

  @Post('medications/:id/refill')
  refillMedication(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forward({
      method: 'POST',
      path: `medications/${id}/refill`,
      user: req.user as ForwardUser,
      body,
    });
  }

  @Patch('medications/:id/stock')
  updateMedicationStock(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forward({
      method: 'PATCH',
      path: `medications/${id}/stock`,
      user: req.user as ForwardUser,
      body,
    });
  }

  @Patch('medications/:id/end')
  endMedicationTreatment(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'PATCH',
      path: `medications/${id}/end`,
      user: req.user as ForwardUser,
    });
  }

  @Delete('medications/:id')
  deleteMedication(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'DELETE',
      path: `medications/${id}`,
      user: req.user as ForwardUser,
    });
  }

  // ----- Dependents -----
  @Get('dependents')
  async listDependents(@Req() req: Request) {
    const dependents = await this.proxy.forward({
      method: 'GET',
      path: 'dependents',
      user: req.user as ForwardUser,
    });
    return this.proxy.enrichDependentsWithCaregivers(dependents);
  }

  @Post('dependents')
  createDependent(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forward({
      method: 'POST',
      path: 'dependents',
      user: req.user as ForwardUser,
      body,
    });
  }

  @Post('dependents/link')
  linkDependent(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forward({
      method: 'POST',
      path: 'dependents/link',
      user: req.user as ForwardUser,
      body,
    });
  }

  @Post('dependents/unlink')
  unlinkDependent(@Req() req: Request) {
    return this.proxy.forward({
      method: 'POST',
      path: 'dependents/unlink',
      user: req.user as ForwardUser,
    });
  }

  @Post('dependents/:id/code')
  regenerateDependentActivationCode(
    @Req() req: Request,
    @Param('id') id: string,
  ) {
    return this.proxy.forward({
      method: 'POST',
      path: `dependents/${id}/code`,
      user: req.user as ForwardUser,
    });
  }

  @Patch('dependents/:id/care-profile')
  updateDependentCareProfile(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forward({
      method: 'PATCH',
      path: `dependents/${id}/care-profile`,
      user: req.user as ForwardUser,
      body,
    });
  }

  @Delete('dependents/:id')
  deleteDependent(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'DELETE',
      path: `dependents/${id}`,
      user: req.user as ForwardUser,
    });
  }

  // ----- Appointments -----
  @Get('appointments')
  listAppointments(
    @Req() req: Request,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'appointments',
      user: req.user as ForwardUser,
      query: dependentId ? { dependentId } : undefined,
    });
  }

  @Post('appointments')
  createAppointment(@Req() req: Request, @Body() body: unknown) {
    return this.proxy.forward({
      method: 'POST',
      path: 'appointments',
      user: req.user as ForwardUser,
      body,
    });
  }

  @Post('appointments/:id/confirm')
  confirmAppointment(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'POST',
      path: `appointments/${id}/confirm`,
      user: req.user as ForwardUser,
    });
  }

  @Post('appointments/:id/complete')
  completeAppointment(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'POST',
      path: `appointments/${id}/complete`,
      user: req.user as ForwardUser,
    });
  }

  @Post('appointments/:id/cancel')
  cancelAppointment(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'POST',
      path: `appointments/${id}/cancel`,
      user: req.user as ForwardUser,
    });
  }

  @Post('appointments/:id/reschedule')
  rescheduleAppointment(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forward({
      method: 'POST',
      path: `appointments/${id}/reschedule`,
      user: req.user as ForwardUser,
      body,
    });
  }

  @Delete('appointments/:id')
  deleteAppointment(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'DELETE',
      path: `appointments/${id}`,
      user: req.user as ForwardUser,
    });
  }

  // ----- Doses -----
  @Get('doses')
  dosesSchedule(
    @Req() req: Request,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'doses',
      user: req.user as ForwardUser,
      query: dependentId ? { dependentId } : undefined,
    });
  }

  @Get('doses/today')
  dosesToday(
    @Req() req: Request,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'doses/today',
      user: req.user as ForwardUser,
      query: dependentId ? { dependentId } : undefined,
    });
  }

  @Post('doses/:id/take')
  takeDose(@Req() req: Request, @Param('id') id: string) {
    return this.proxy.forward({
      method: 'POST',
      path: `doses/${id}/take`,
      user: req.user as ForwardUser,
    });
  }

  @Post('doses/:id/postpone')
  postponeDose(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() body: unknown,
  ) {
    return this.proxy.forward({
      method: 'POST',
      path: `doses/${id}/postpone`,
      user: req.user as ForwardUser,
      body,
    });
  }

  // ----- History -----
  @Get('history/day')
  historyDay(
    @Req() req: Request,
    @Query('date') date?: string,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'history/day',
      user: req.user as ForwardUser,
      query: {
        ...(date ? { date } : {}),
        ...(dependentId ? { dependentId } : {}),
      },
    });
  }

  @Get('history')
  history(
    @Req() req: Request,
    @Query('month') month?: string,
    @Query('dependentId') dependentId?: string,
  ) {
    return this.proxy.forward({
      method: 'GET',
      path: 'history',
      user: req.user as ForwardUser,
      query: {
        ...(month ? { month } : {}),
        ...(dependentId ? { dependentId } : {}),
      },
    });
  }
}
