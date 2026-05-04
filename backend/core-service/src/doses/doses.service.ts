import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, MoreThan, Repository } from 'typeorm';
import { Dose } from './dose.entity';
import { Medication } from '../medications/medication.entity';
import { Dependent } from '../dependents/dependent.entity';
import { calculateDoseCount, parseFrequencyHours } from './dose-frequency';

@Injectable()
export class DosesService {
  constructor(
    @InjectRepository(Dose)
    private readonly repo: Repository<Dose>,
    @InjectRepository(Medication)
    private readonly medsRepo: Repository<Medication>,
    @InjectRepository(Dependent)
    private readonly dependentsRepo: Repository<Dependent>,
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
  ): Promise<Dose[]> {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const doses = await this.repo.find({
      where: await this.buildDoseWhere(userId, accountType, dependentId, {
        scheduledAt: Between(start, end),
      }),
      order: { scheduledAt: 'ASC' },
    });
    return this.withDependentNames(doses);
  }

  async schedule(
    userId: string,
    accountType: string,
    dependentId?: string,
  ): Promise<Dose[]> {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const doses = await this.repo.find({
      where: await this.buildDoseWhere(userId, accountType, dependentId, {
        scheduledAt: Between(start, new Date('9999-12-31T23:59:59.999Z')),
      }),
      order: { scheduledAt: 'ASC' },
    });
    return this.withDependentNames(doses);
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
    return this.repo.save(dose);
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
        userId,
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
    return this.repo.save(dose);
  }

  private async findOwned(userId: string, id: string): Promise<Dose> {
    const dose = await this.repo.findOne({ where: { id } });
    if (!dose) throw new NotFoundException('Dose não encontrada');
    if (dose.userId !== userId) {
      throw new ForbiddenException('Você não pode alterar esta dose');
    }
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
    extra: Record<string, unknown>,
  ) {
    if (dependentId) {
      return { dependentId, ...extra };
    }
    if (accountType !== 'caregiver') {
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
