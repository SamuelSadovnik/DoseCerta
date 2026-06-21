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
  treatments: TreatmentHistory[];
  dependentId?: string;
  dependentName?: string;
  dependentAvatarUrl?: string;
}

interface TreatmentHistory {
  medicationId: string;
  medicationName: string;
  dosage: string;
  dosesTaken: number;
  dosesExpected: number;
  dosesMissed: number;
  adherencePercent: number;
  lastDoseAt?: Date;
  lastStatus?: Dose['status'];
}

interface HistoryDayDose {
  id: string;
  medicationName: string;
  dosage: string;
  scheduledAt: Date;
  status: Dose['status'];
  takenAt: Date | null;
  dependentId: string | null;
  dependentName?: string | null;
}

interface MonthRange {
  start: Date;
  endInclusive: Date;
  year: number;
  monthIndex: number;
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
        year: range.year,
        monthIndex: range.monthIndex,
        groupId,
        doses: groupDoses,
        dependentNames,
      }),
    );
  }

  async day(
    userId: string,
    accountType: string,
    date: string,
    dependentId?: string,
  ): Promise<HistoryDayDose[]> {
    const range = this.dayRange(date);
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

    return doses.map((dose) => ({
      id: dose.id,
      medicationName: dose.medicationName,
      dosage: dose.dosage,
      scheduledAt: dose.scheduledAt,
      status: dose.status,
      takenAt: dose.takenAt,
      dependentId: dose.dependentId,
      dependentName: dose.dependentId
        ? dependentNames.get(dose.dependentId) ?? null
        : null,
    }));
  }

  private buildSummary(params: {
    year: number;
    monthIndex: number;
    groupId: string;
    doses: Dose[];
    dependentNames: Map<string, string>;
  }): HistorySummary {
    const { year, monthIndex, groupId, doses, dependentNames } = params;
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
      days: this.buildDays(year, monthIndex, doses),
      missedDoses,
      treatments: this.buildTreatmentHistory(dueDoses),
      ...(dependentId
        ? {
            dependentId,
            dependentName: dependentNames.get(dependentId),
          }
        : {}),
    };
  }

  private buildTreatmentHistory(doses: Dose[]): TreatmentHistory[] {
    const grouped = new Map<string, Dose[]>();
    for (const dose of doses) {
      const group = grouped.get(dose.medicationId) ?? [];
      group.push(dose);
      grouped.set(dose.medicationId, group);
    }

    return [...grouped.values()]
      .map((group) => {
        const sorted = [...group].sort(
          (a, b) => a.scheduledAt.getTime() - b.scheduledAt.getTime(),
        );
        const latest = sorted[sorted.length - 1];
        const dosesTaken = sorted.filter(
          (dose) => dose.status === 'taken',
        ).length;
        const dosesExpected = sorted.length;
        const dosesMissed = sorted.filter(
          (dose) => dose.status !== 'taken',
        ).length;
        const adherencePercent =
          dosesExpected === 0 ? 0 : Math.round((dosesTaken / dosesExpected) * 100);

        return {
          medicationId: latest.medicationId,
          medicationName: latest.medicationName,
          dosage: latest.dosage,
          dosesTaken,
          dosesExpected,
          dosesMissed,
          adherencePercent,
          lastDoseAt: latest.scheduledAt,
          lastStatus: latest.status,
        };
      })
      .sort((a, b) => {
        const byMissed = b.dosesMissed - a.dosesMissed;
        if (byMissed !== 0) return byMissed;
        return a.medicationName.localeCompare(b.medicationName);
      });
  }

  private buildDays(
    year: number,
    monthIndex: number,
    doses: Dose[],
  ): HistoryDay[] {
    const daysInMonth = new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();

    const statusesByDay = new Map<number, Dose['status'][]>();
    for (const dose of doses) {
      const parts = this.localDateParts(dose.scheduledAt);
      if (parts.year !== year || parts.monthIndex !== monthIndex) continue;
      const day = parts.day;
      const statuses = statusesByDay.get(day) ?? [];
      statuses.push(dose.status);
      statusesByDay.set(day, statuses);
    }

    const days: HistoryDay[] = [];
    for (let day = 1; day <= daysInMonth; day++) {
      const statuses = statusesByDay.get(day) ?? [];
      days.push({
        date: this.formatDateUtc(year, monthIndex, day),
        status: this.dayStatus(statuses, this.localDayNumber(year, monthIndex, day)),
      });
    }
    return days;
  }

  private dayStatus(statuses: Dose['status'][], dayNumber: number): DayStatus {
    if (statuses.length === 0) return 'none';
    const nowParts = this.localDateParts(new Date());
    const todayNumber = this.localDayNumber(
      nowParts.year,
      nowParts.monthIndex,
      nowParts.day,
    );
    const isPastDay = dayNumber < todayNumber;
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

  private monthRange(month?: string): MonthRange {
    const match = month?.match(/^(\d{4})-(\d{2})$/);
    const now = new Date();
    const nowParts = this.localDateParts(now);
    const year = match ? Number(match[1]) : nowParts.year;
    const monthNumber = match ? Number(match[2]) : nowParts.monthIndex + 1;
    const monthIndex = Math.min(Math.max(monthNumber, 1), 12) - 1;

    const start = this.localDateToUtc(year, monthIndex, 1);
    const nextMonth = this.localDateToUtc(year, monthIndex + 1, 1);
    const endInclusive = new Date(nextMonth.getTime() - 1);
    return { start, endInclusive, year, monthIndex };
  }

  private dayRange(date: string): { start: Date; endInclusive: Date } {
    const match = date?.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    const now = new Date();
    const nowParts = this.localDateParts(now);
    const year = match ? Number(match[1]) : nowParts.year;
    const month = match ? Number(match[2]) : nowParts.monthIndex + 1;
    const day = match ? Number(match[3]) : nowParts.day;
    const start = this.localDateToUtc(year, month - 1, day);
    const nextDay = this.localDateToUtc(year, month - 1, day + 1);
    return { start, endInclusive: new Date(nextDay.getTime() - 1) };
  }

  private formatDateUtc(year: number, monthIndex: number, day: number): string {
    return new Date(Date.UTC(year, monthIndex, day)).toISOString();
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

  private localDayNumber(year: number, monthIndex: number, day: number): number {
    return year * 10000 + (monthIndex + 1) * 100 + day;
  }

  private timezoneOffsetMs(): number {
    const minutes = Number(process.env.APP_TIMEZONE_OFFSET_MINUTES ?? '-180');
    return Number.isFinite(minutes) ? minutes * 60_000 : -180 * 60_000;
  }
}
