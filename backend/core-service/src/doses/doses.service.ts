import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, IsNull, MoreThan, Repository } from 'typeorm';
import { Dose } from './dose.entity';
import { Medication } from '../medications/medication.entity';
import { Dependent } from '../dependents/dependent.entity';
import { calculateDoseCount, parseFrequencyHours } from './dose-frequency';
import { RabbitMQPublisherService } from '../messaging/rabbitmq-publisher.service';

@Injectable()
export class DosesService {
  constructor(
    @InjectRepository(Dose)
    private readonly repo: Repository<Dose>,
    @InjectRepository(Medication)
    private readonly medsRepo: Repository<Medication>,
    @InjectRepository(Dependent)
    private readonly dependentsRepo: Repository<Dependent>,
    private readonly events: RabbitMQPublisherService,
  ) {}

  /**
   * Generates the full schedule from ten minutes after registration. That
   * gives the user time to react to the newly registered first dose.
   */
  async generateForMedication(med: Medication): Promise<void> {
    const hours = parseFrequencyHours(med.frequency);
    const rawCount = calculateDoseCount(med.frequency, med.durationDays);
    const count = Math.min(rawCount, 90);
    if (count <= 0) return;

    const start = new Date();
    start.setMinutes(start.getMinutes() + 10);

    const doses: Partial<Dose>[] = [];
    for (let i = 0; i < count; i++) {
      const at = new Date(start);
      at.setHours(at.getHours() + i * hours);
      doses.push({
        userId: med.userId,
        medicationId: med.id,
        dependentId: med.dependentId,
        medicationName: med.name,
        dosage: med.dosage,
        scheduledAt: at,
        status: 'pending',
      });
    }
    await this.repo.save(doses);
  }

  async today(
    userId: string,
    accountType: string,
    dependentId?: string,
    scope?: string,
  ): Promise<Dose[]> {
    const { start, endInclusive } = this.currentLocalDayRange();
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const doses = await this.repo.find({
      where: await this.buildDoseWhere(
        userId,
        accountType,
        dependentId,
        scope,
        {
          scheduledAt: Between(start, endInclusive),
        },
      ),
      order: { scheduledAt: 'ASC' },
    });
    return this.withDependentNames(doses);
  }

  async schedule(
    userId: string,
    accountType: string,
    dependentId?: string,
    scope?: string,
  ): Promise<Dose[]> {
    const { start } = this.currentLocalDayRange();
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const doses = await this.repo.find({
      where: await this.buildDoseWhere(
        userId,
        accountType,
        dependentId,
        scope,
        {
          scheduledAt: Between(start, new Date('9999-12-31T23:59:59.999Z')),
        },
      ),
      order: { scheduledAt: 'ASC' },
    });
    return this.withDependentNames(doses);
  }

  async pendingForScheduler(lookAheadMinutes: number): Promise<Dose[]> {
    const now = new Date();
    const start = new Date(now);
    start.setDate(start.getDate() - 1);
    const end = new Date(now);
    end.setMinutes(end.getMinutes() + Math.max(1, lookAheadMinutes));

    const doses = await this.repo.find({
      where: {
        status: In(['pending', 'postponed']),
        scheduledAt: Between(start, end),
      },
      order: { scheduledAt: 'ASC' },
    });

    return this.withDependentNames(doses);
  }

  async removeFuturePendingForMedication(
    userId: string,
    medicationId: string,
  ): Promise<void> {
    const now = new Date();
    await this.repo.delete({
      userId,
      medicationId,
      scheduledAt: MoreThan(now),
      status: In(['pending', 'postponed']),
    });
  }

  async take(userId: string, id: string): Promise<Dose> {
    const dose = await this.findOwned(userId, id);
    if (dose.status === 'taken') {
      throw new BadRequestException('Esta dose já foi tomada');
    }
    if (dose.status === 'missed') {
      throw new BadRequestException('Esta dose já foi perdida');
    }
    dose.status = 'taken';
    dose.takenAt = new Date();
    const med = await this.medsRepo.findOne({
      where: { id: dose.medicationId },
    });
    if (med && med.currentQuantity > 0) {
      med.currentQuantity -= 1;
      await this.medsRepo.save(med);
    }
    const saved = await this.repo.save(dose);
    await this.publishDoseTaken(saved);
    return saved;
  }

  async postpone(userId: string, id: string, minutes: number): Promise<Dose> {
    const dose = await this.findOwned(userId, id);
    if (dose.status === 'taken') {
      throw new BadRequestException('Dose tomada não pode ser adiada');
    }
    if (dose.status === 'missed') {
      throw new BadRequestException('Dose perdida não pode ser adiada');
    }
    const originalScheduledAt = new Date(dose.scheduledAt);
    const futureDoses = await this.repo.find({
      where: {
        userId: dose.userId,
        medicationId: dose.medicationId,
        scheduledAt: MoreThan(originalScheduledAt),
        status: In(['pending', 'postponed']),
      },
      order: { scheduledAt: 'ASC' },
    });

    dose.scheduledAt = this.addMinutes(dose.scheduledAt, minutes);
    dose.status = 'postponed';

    for (const futureDose of futureDoses) {
      futureDose.scheduledAt = this.addMinutes(futureDose.scheduledAt, minutes);
    }

    await this.repo.save(futureDoses);
    const saved = await this.repo.save(dose);
    await this.publishDosePostponed(saved);
    return saved;
  }

  private async publishDoseTaken(dose: Dose) {
    const dependent = await this.findDependentForEvent(dose.dependentId);
    this.events.publish('DoseTaken', 'dose.taken', {
      doseId: dose.id,
      userId: dose.userId,
      dependentId: dose.dependentId,
      dependentName: dependent?.name ?? null,
      medicationName: dose.medicationName,
      takenAt: dose.takenAt?.toISOString() ?? new Date().toISOString(),
    });
  }

  private async publishDosePostponed(dose: Dose) {
    const dependent = await this.findDependentForEvent(dose.dependentId);
    this.events.publish('DosePostponed', 'dose.postponed', {
      doseId: dose.id,
      userId: dose.userId,
      dependentId: dose.dependentId,
      dependentName: dependent?.name ?? null,
      medicationName: dose.medicationName,
      postponedUntil: dose.scheduledAt.toISOString(),
    });
  }

  private async findDependentForEvent(
    dependentId: string | null,
  ): Promise<Dependent | null> {
    if (!dependentId) return null;
    return this.dependentsRepo.findOne({ where: { id: dependentId } });
  }

  private async findOwned(userId: string, id: string): Promise<Dose> {
    const dose = await this.repo.findOne({ where: { id } });
    if (!dose) throw new NotFoundException('Dose não encontrada');
    if (dose.userId === userId) {
      return dose;
    }
    if (!dose.dependentId) {
      throw new ForbiddenException('Você não pode alterar esta dose');
    }
    await this.findAccessibleDependent(userId, dose.dependentId);
    return dose;
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

  private async buildDoseWhere(
    userId: string,
    accountType: string,
    dependentId: string | undefined,
    scope: string | undefined,
    extra: Record<string, unknown>,
  ) {
    if (dependentId) {
      return { dependentId, ...extra };
    }
    if (scope === 'self') {
      return { userId, dependentId: IsNull(), ...extra };
    }
    if (accountType !== 'caregiver') {
      const linkedRegistries = await this.dependentsRepo.find({
        where: { linkedUserId: userId },
      });
      const linkedIds = linkedRegistries.map((dependent) => dependent.id);
      if (linkedIds.length > 0) {
        return [
          { userId, ...extra },
          { dependentId: In(linkedIds), ...extra },
        ];
      }
      return { userId, ...extra };
    }

    const dependents = await this.dependentsRepo.find({
      where: { userId },
    });
    const dependentIds = dependents.map((dependent) => dependent.id);
    if (dependentIds.length === 0) {
      return { userId, ...extra };
    }
    return [
      { userId, ...extra },
      { dependentId: In(dependentIds), ...extra },
    ];
  }

  private addMinutes(value: Date, minutes: number): Date {
    const result = new Date(value);
    result.setMinutes(result.getMinutes() + minutes);
    return result;
  }

  private currentLocalDayRange(): { start: Date; endInclusive: Date } {
    const parts = this.localDateParts(new Date());
    const start = this.localDateToUtc(parts.year, parts.monthIndex, parts.day);
    const nextDay = this.localDateToUtc(
      parts.year,
      parts.monthIndex,
      parts.day + 1,
    );
    return { start, endInclusive: new Date(nextDay.getTime() - 1) };
  }

  private localDateParts(date: Date): {
    year: number;
    monthIndex: number;
    day: number;
  } {
    const shifted = new Date(date.getTime() + this.timezoneOffsetMs());
    return {
      year: shifted.getUTCFullYear(),
      monthIndex: shifted.getUTCMonth(),
      day: shifted.getUTCDate(),
    };
  }

  private localDateToUtc(year: number, monthIndex: number, day: number): Date {
    return new Date(
      Date.UTC(year, monthIndex, day, 0, 0, 0, 0) - this.timezoneOffsetMs(),
    );
  }

  private timezoneOffsetMs(): number {
    const minutes = Number(process.env.APP_TIMEZONE_OFFSET_MINUTES ?? '-180');
    return Number.isFinite(minutes) ? minutes * 60_000 : -180 * 60_000;
  }

  private async withDependentNames(doses: Dose[]): Promise<Dose[]> {
    const ids = [
      ...new Set(
        doses
          .map((dose) => dose.dependentId)
          .filter((id): id is string => id !== null),
      ),
    ];
    if (ids.length === 0) return doses;

    const dependents = await this.dependentsRepo.find({
      where: ids.map((id) => ({ id })),
    });
    const names = new Map(
      dependents.map((dependent) => [dependent.id, dependent.name]),
    );
    return doses.map((dose) =>
      Object.assign(dose, {
        dependentName: dose.dependentId
          ? names.get(dose.dependentId) ?? null
          : null,
      }),
    );
  }
}
