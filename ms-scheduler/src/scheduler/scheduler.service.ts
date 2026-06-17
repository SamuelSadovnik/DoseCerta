import { randomUUID } from "node:crypto";
import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { and, asc, eq, gt, lte } from "drizzle-orm";
import { DbService } from "../db/db.service";
import { doseSchedules, type DoseSchedule } from "../db/schema";
import { RabbitMQService } from "../messaging/rabbitmq.service";
import type { CoreDoseDto } from "./core-dose.dto";
import type { DoseReminderEvent, DoseScheduledEvent } from "./dose-scheduled.event";

@Injectable()
export class SchedulerService implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(SchedulerService.name);
  private syncTimer?: NodeJS.Timeout;
  private publishTimer?: NodeJS.Timeout;
  private syncing = false;
  private publishing = false;

  constructor(
    private readonly dbService: DbService,
    private readonly configService: ConfigService,
    private readonly rabbitMQService: RabbitMQService,
  ) {}

  async onApplicationBootstrap() {
    await this.syncFromMainApi();
    await this.publishDueDoses();

    this.syncTimer = setInterval(
      () => void this.syncFromMainApi(),
      this.numberConfig("SYNC_INTERVAL_MS", 30_000),
    );
    this.publishTimer = setInterval(
      () => void this.publishDueDoses(),
      this.numberConfig("PUBLISH_INTERVAL_MS", 10_000),
    );

    this.logger.log("Scheduler jobs started");
  }

  onModuleDestroy() {
    if (this.syncTimer) clearInterval(this.syncTimer);
    if (this.publishTimer) clearInterval(this.publishTimer);
  }

  async syncFromMainApi() {
    if (this.syncing) return;
    this.syncing = true;

    try {
      const doses = await this.fetchPendingDoses();

      for (const dose of doses) {
        await this.dbService.db
          .insert(doseSchedules)
          .values({
            doseId: dose.id,
            userId: dose.userId,
            dependentId: dose.dependentId,
            medicationName: dose.medicationName,
            dosage: dose.dosage,
            note: dose.note,
            scheduledAt: new Date(dose.scheduledAt),
            sourceStatus: dose.status,
            correlationId: randomUUID(),
          })
          .onConflictDoUpdate({
            target: doseSchedules.doseId,
            set: {
              dependentId: dose.dependentId,
              medicationName: dose.medicationName,
              dosage: dose.dosage,
              note: dose.note,
              scheduledAt: new Date(dose.scheduledAt),
              sourceStatus: dose.status,
              updatedAt: new Date(),
            },
          });
      }

      if (doses.length > 0) {
        this.logger.log(`Synced ${doses.length} pending doses`);
      }
    } catch (error) {
      this.logger.warn(`Failed to sync doses: ${this.errorMessage(error)}`);
    } finally {
      this.syncing = false;
    }
  }

  async publishDueDoses() {
    if (this.publishing) return;
    this.publishing = true;

    try {
      await this.publishUpcomingReminders();

      const dueDoses = await this.dbService.db
        .select()
        .from(doseSchedules)
        .where(
          and(
            eq(doseSchedules.published, false),
            lte(doseSchedules.scheduledAt, new Date()),
          ),
        )
        .orderBy(asc(doseSchedules.scheduledAt))
        .limit(this.numberConfig("BATCH_SIZE", 50));

      for (const dose of dueDoses) {
        await this.publishDose(dose);
      }
    } catch (error) {
      this.logger.error(`Failed to publish due doses: ${this.errorMessage(error)}`);
    } finally {
      this.publishing = false;
    }
  }

  private async publishUpcomingReminders() {
    const now = new Date();
    const remindBeforeMinutes = this.numberConfig("REMINDER_LEAD_MINUTES", 5);
    const reminderWindowEnd = this.addMinutes(now, remindBeforeMinutes);

    const upcomingDoses = await this.dbService.db
      .select()
      .from(doseSchedules)
      .where(
        and(
          eq(doseSchedules.reminderPublished, false),
          gt(doseSchedules.scheduledAt, now),
          lte(doseSchedules.scheduledAt, reminderWindowEnd),
        ),
      )
      .orderBy(asc(doseSchedules.scheduledAt))
      .limit(this.numberConfig("BATCH_SIZE", 50));

    for (const dose of upcomingDoses) {
      await this.publishReminder(dose, remindBeforeMinutes);
    }
  }

  private async publishReminder(
    dose: DoseSchedule,
    remindBeforeMinutes: number,
  ) {
    const event: DoseReminderEvent = {
      eventType: "DoseReminder",
      version: "1.0",
      timestamp: new Date().toISOString(),
      correlationId: dose.reminderCorrelationId,
      producer: "ms-scheduler",
      data: {
        doseId: dose.doseId,
        userId: dose.userId,
        dependentId: dose.dependentId,
        medicationName: dose.medicationName,
        dosage: dose.dosage,
        scheduledAt: dose.scheduledAt.toISOString(),
        note: dose.note,
        remindBeforeMinutes,
      },
    };

    const accepted = this.rabbitMQService.publish("dose.reminder", event);
    if (!accepted) return;

    await this.dbService.db
      .update(doseSchedules)
      .set({
        reminderPublished: true,
        reminderPublishedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(doseSchedules.id, dose.id),
          eq(doseSchedules.reminderPublished, false),
        ),
      );

    this.logger.log(`DoseReminder published for dose ${dose.doseId}`);
  }

  private async publishDose(dose: DoseSchedule) {
    const event: DoseScheduledEvent = {
      eventType: "DoseScheduled",
      version: "1.0",
      timestamp: new Date().toISOString(),
      correlationId: dose.correlationId,
      producer: "ms-scheduler",
      data: {
        doseId: dose.doseId,
        userId: dose.userId,
        dependentId: dose.dependentId,
        medicationName: dose.medicationName,
        dosage: dose.dosage,
        scheduledAt: dose.scheduledAt.toISOString(),
        note: dose.note,
      },
    };

    const accepted = this.rabbitMQService.publish("dose.scheduled", event);
    if (!accepted) return;

    await this.dbService.db
      .update(doseSchedules)
      .set({
        published: true,
        publishedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(doseSchedules.id, dose.id),
          eq(doseSchedules.published, false),
        ),
      );

    this.logger.log(`DoseScheduled published for dose ${dose.doseId}`);
  }

  private async fetchPendingDoses(): Promise<CoreDoseDto[]> {
    const mainApiUrl = this.configService.get<string>(
      "MAIN_API_URL",
      "http://host.docker.internal:3002",
    );
    const apiKey = this.configService.get<string>(
      "MAIN_API_KEY",
      "dosecerta-internal-key-scheduler",
    );
    const lookAheadMinutes = this.numberConfig("SYNC_LOOK_AHEAD_MINUTES", 1440);
    const response = await fetch(
      `${mainApiUrl}/internal/doses/pending?lookAheadMinutes=${lookAheadMinutes}`,
      {
        headers: {
          "x-api-key": apiKey,
        },
      },
    );

    if (!response.ok) {
      throw new Error(`Core API returned ${response.status}`);
    }

    return (await response.json()) as CoreDoseDto[];
  }

  private numberConfig(key: string, fallback: number): number {
    const value = Number(this.configService.get<string>(key));
    return Number.isFinite(value) && value > 0 ? value : fallback;
  }

  private addMinutes(date: Date, minutes: number): Date {
    return new Date(date.getTime() + minutes * 60_000);
  }

  private errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
  }
}
