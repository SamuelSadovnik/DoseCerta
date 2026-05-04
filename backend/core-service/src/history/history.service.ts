import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, In, Repository } from 'typeorm';
import { Dose } from '../doses/dose.entity';
import { Dependent } from '../dependents/dependent.entity';

type DayStatus = 'allTaken' | 'someMissed' | 'none';

interface HistoryDay {
  date: string;
  status: DayStatus;
}

interface MissedDose {
  medicationName: string;
  dosage: string;
  scheduledAt: Date;
  dependentName?: string;
}

interface HistorySummary {
  dosesTaken: number;
  dosesExpected: number;
  dosesMissed: number;
  days: HistoryDay[];
  missedDoses: MissedDose[];
  dependentId?: string;
  dependentName?: string;
  dependentAvatarUrl?: string;
}

@Injectable()
export class HistoryService {
  constructor(
    @InjectRepository(Dose)
    private readonly doses: Repository<Dose>,
    @InjectRepository(Dependent)
    private readonly dependents: Repository<Dependent>,
  ) {}

  async month(
    userId: string,
    accountType: string,
    month?: string,
    dependentId?: string,
  ): Promise<HistorySummary[]> {
    const range = this.monthRange(month);
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
    }
    const doses = await this.doses.find({
      where: await this.buildDoseWhere(userId, accountType, dependentId, {
        scheduledAt: Between(range.start, range.endInclusive),
      }),
      order: { scheduledAt: 'ASC' },
    });

    const dependentNames = await this.loadDependentNames(userId, doses);
    const grouped = this.groupByDependent(doses, dependentId);

    return [...grouped.entries()].map(([groupId, groupDoses]) =>
      this.buildSummary({
        monthStart: range.start,
        groupId,
        doses: groupDoses,
        dependentNames,
      }),
    );
  }

  private buildSummary(params: {
    monthStart: Date;
    groupId: string;
    doses: Dose[];
    dependentNames: Map<string, string>;
  }): HistorySummary {
    const { monthStart, groupId, doses, dependentNames } = params;
    const now = new Date();
    const dueDoses = doses.filter(
      (dose) => dose.scheduledAt <= now || dose.status === 'taken',
    );
    const missedDueDoses = dueDoses.filter(
      (dose) => dose.status !== 'taken',
    );
    const dependentId = groupId === 'self' ? undefined : groupId;
    const missedDoses = missedDueDoses
      .map((dose) => ({
        medicationName: dose.medicationName,
        dosage: dose.dosage,
        scheduledAt: dose.scheduledAt,
        ...(dose.dependentId
          ? { dependentName: dependentNames.get(dose.dependentId) }
          : {}),
      }));

    return {
      dosesTaken: dueDoses.filter((dose) => dose.status === 'taken').length,
      dosesExpected: dueDoses.length,
      dosesMissed: missedDoses.length,
      days: this.buildDays(monthStart, doses),
      missedDoses,
      ...(dependentId
        ? {
            dependentId,
            dependentName: dependentNames.get(dependentId),
          }
        : {}),
    };
  }

  private buildDays(monthStart: Date, doses: Dose[]): HistoryDay[] {
    const year = monthStart.getUTCFullYear();
    const monthIndex = monthStart.getUTCMonth();
    const daysInMonth = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();

    const statusesByDay = new Map<number, Dose['status'][]>();
    for (const dose of doses) {
      const day = dose.scheduledAt.getUTCDate();
      const statuses = statusesByDay.get(day) ?? [];
      statuses.push(dose.status);
      statusesByDay.set(day, statuses);
    }

    const days: HistoryDay[] = [];
    for (let day = 1; day <= daysInMonth; day++) {
      const statuses = statusesByDay.get(day) ?? [];
      days.push({
        date: this.formatDateUtc(year, monthIndex, day),
        status: this.dayStatus(statuses, new Date(Date.UTC(year, monthIndex, day))),
      });
    }
    return days;
  }

  private dayStatus(statuses: Dose['status'][], day: Date): DayStatus {
    if (statuses.length === 0) return 'none';
    const now = new Date();
    const isPastDay =
      day <
      new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    if (statuses.some((status) => status === 'missed')) return 'someMissed';
    if (isPastDay && statuses.some((status) => status !== 'taken')) {
      return 'someMissed';
    }
    if (statuses.every((status) => status === 'taken')) return 'allTaken';
    return 'none';
  }

  private groupByDependent(
    doses: Dose[],
    requestedDependentId?: string,
  ): Map<string, Dose[]> {
    if (doses.length === 0) {
      return new Map([[requestedDependentId ?? 'self', []]]);
    }

    const grouped = new Map<string, Dose[]>();
    for (const dose of doses) {
      const key = dose.dependentId ?? 'self';
      const group = grouped.get(key) ?? [];
      group.push(dose);
      grouped.set(key, group);
    }
    return grouped;
  }

  private async loadDependentNames(
    userId: string,
    doses: Dose[],
  ): Promise<Map<string, string>> {
    const ids = [
      ...new Set(
        doses
          .map((dose) => dose.dependentId)
          .filter((id): id is string => id !== null),
      ),
    ];
    if (ids.length === 0) return new Map();

    const dependents = await this.dependents.find({
      where: ids.map((id) => ({ id })),
    });
    return new Map(dependents.map((dependent) => [dependent.id, dependent.name]));
  }

  private async findAccessibleDependent(
    userId: string,
    dependentId: string,
  ): Promise<Dependent> {
    const dependent = await this.dependents.findOne({
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

    const dependents = await this.dependents.find({ where: { userId } });
    const dependentIds = dependents.map((dependent) => dependent.id);
    if (dependentIds.length === 0) {
      return { userId, ...extra };
    }
    return [
      { userId, ...extra },
      { dependentId: In(dependentIds), ...extra },
    ];
  }

  private monthRange(month?: string): { start: Date; endInclusive: Date } {
    const match = month?.match(/^(\d{4})-(\d{2})$/);
    const now = new Date();
    const year = match ? Number(match[1]) : now.getUTCFullYear();
    const monthNumber = match ? Number(match[2]) : now.getUTCMonth() + 1;
    const monthIndex = Math.min(Math.max(monthNumber, 1), 12) - 1;

    const start = new Date(Date.UTC(year, monthIndex, 1, 0, 0, 0, 0));
    const nextMonth = new Date(Date.UTC(year, monthIndex + 1, 1, 0, 0, 0, 0));
    const endInclusive = new Date(nextMonth.getTime() - 1);
    return { start, endInclusive };
  }

  private formatDateUtc(year: number, monthIndex: number, day: number): string {
    return new Date(Date.UTC(year, monthIndex, day)).toISOString();
  }
}
