import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Appointment } from './appointment.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { Dependent } from '../dependents/dependent.entity';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment)
    private readonly repo: Repository<Appointment>,
    @InjectRepository(Dependent)
    private readonly dependentsRepo: Repository<Dependent>,
  ) {}

  async list(
    userId: string,
    accountType: string,
    dependentId?: string,
  ): Promise<Appointment[]> {
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const appointments = await this.repo.find({
      where: await this.buildAppointmentWhere(userId, accountType, dependentId),
      order: { scheduledAt: 'ASC' },
    });
    return this.withDependentNames(appointments);
  }

  /** Admin-only. The caller must enforce access. */
  listAll(): Promise<Appointment[]> {
    return this.repo.find({ order: { scheduledAt: 'ASC' } });
  }

  async create(userId: string, dto: CreateAppointmentDto): Promise<Appointment> {
    const dependent = dto.dependentId
      ? await this.findAccessibleDependent(userId, dto.dependentId)
      : null;
    const ownerUserId = dependent?.linkedUserId ?? userId;
    const appt = this.repo.create({
      userId: ownerUserId,
      dependentId: dto.dependentId ?? null,
      doctorName: dto.doctorName,
      specialty: dto.specialty ?? null,
      scheduledAt: new Date(dto.scheduledAt),
      location: dto.location ?? null,
      status: 'scheduled',
    });
    return this.repo.save(appt);
  }

  async confirm(userId: string, id: string): Promise<Appointment> {
    const appt = await this.findAccessibleAppointment(userId, id);
    appt.status = 'done';
    return this.repo.save(appt);
  }

  async reschedule(
    userId: string,
    id: string,
    dto: CreateAppointmentDto,
  ): Promise<Appointment> {
    const appt = await this.findAccessibleAppointment(userId, id);
    const dependent = dto.dependentId
      ? await this.findAccessibleDependent(userId, dto.dependentId)
      : null;
    appt.doctorName = dto.doctorName;
    appt.specialty = dto.specialty ?? null;
    appt.scheduledAt = new Date(dto.scheduledAt);
    appt.location = dto.location ?? null;
    appt.dependentId = dto.dependentId ?? null;
    appt.userId = dependent?.linkedUserId ?? userId;
    appt.status = 'rescheduled';
    return this.repo.save(appt);
  }

  async remove(userId: string, id: string): Promise<void> {
    const appt = await this.findOwned(userId, id);
    await this.repo.remove(appt);
  }

  private async findOwned(userId: string, id: string): Promise<Appointment> {
    const appt = await this.repo.findOne({ where: { id, userId } });
    if (!appt) throw new NotFoundException('Consulta não encontrada');
    return appt;
  }

  private async findAccessibleAppointment(
    userId: string,
    id: string,
  ): Promise<Appointment> {
    const appt = await this.repo.findOne({ where: { id } });
    if (!appt) throw new NotFoundException('Consulta não encontrada');
    if (appt.userId === userId) return appt;
    if (!appt.dependentId) {
      throw new ForbiddenException('Acesso negado à consulta');
    }
    await this.findAccessibleDependent(userId, appt.dependentId);
    return appt;
  }

  private async findAccessibleDependent(
    userId: string,
    dependentId: string,
  ): Promise<Dependent> {
    const dependent = await this.dependentsRepo.findOne({
      where: { id: dependentId },
    });
    if (!dependent) {
      throw new NotFoundException('Dependente não encontrado');
    }
    if (dependent.userId !== userId && dependent.linkedUserId !== userId) {
      throw new ForbiddenException('Acesso negado ao dependente');
    }
    return dependent;
  }

  private async buildAppointmentWhere(
    userId: string,
    accountType: string,
    dependentId?: string,
  ) {
    if (dependentId) {
      return { dependentId };
    }

    const linkedRegistries = await this.dependentsRepo.find({
      where: { linkedUserId: userId },
    });
    if (accountType !== 'caregiver') {
      const linkedIds = linkedRegistries.map((dependent) => dependent.id);
      if (linkedIds.length === 0) return { userId };
      return [{ userId }, { dependentId: In(linkedIds) }];
    }

    const ownedRegistries = await this.dependentsRepo.find({ where: { userId } });
    const ownedIds = ownedRegistries.map((dependent) => dependent.id);
    if (ownedIds.length === 0) return { userId };
    return [{ userId }, { dependentId: In(ownedIds) }];
  }

  private async withDependentNames(
    appointments: Appointment[],
  ): Promise<Appointment[]> {
    const ids = [
      ...new Set(
        appointments
          .map((appointment) => appointment.dependentId)
          .filter((id): id is string => id !== null),
      ),
    ];
    if (ids.length === 0) return appointments;

    const dependents = await this.dependentsRepo.find({
      where: ids.map((id) => ({ id })),
    });
    const names = new Map(
      dependents.map((dependent) => [dependent.id, dependent.name]),
    );
    return appointments.map((appointment) =>
      Object.assign(appointment, {
        dependentName: appointment.dependentId
          ? names.get(appointment.dependentId) ?? null
          : null,
      }),
    );
  }
}
