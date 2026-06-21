import { randomInt } from "node:crypto";
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { and, asc, count, desc, eq, or, type SQL } from "drizzle-orm";
import { DbService } from "../db/db.service";
import { activationCodes, links, type ActivationCode, type Link } from "../db/schema";
import type { PaginatedResult } from "../common/types/paginated-result";
import type { ActivateLinkDto } from "./dto/activate-link.dto";
import type { ActivationCodeResponseDto } from "./dto/activation-code-response.dto";
import type { GenerateLinkCodeDto } from "./dto/generate-link-code.dto";
import type { LinkQueryDto } from "./dto/link-query.dto";
import type { LinkResponseDto } from "./dto/link-response.dto";
import { LinksMessagingService } from "./links-messaging.service";

@Injectable()
export class LinksService {
  constructor(
    private readonly dbService: DbService,
    private readonly configService: ConfigService,
    private readonly messagingService: LinksMessagingService,
  ) {}

  async generateCode(
    input: GenerateLinkCodeDto,
  ): Promise<ActivationCodeResponseDto> {
    await this.ensureNoActiveLink(input.caregiverId, input.dependentId);

    const now = new Date();
    const ttlMinutes =
      input.ttlMinutes ??
      Number(this.configService.get<string>("ACTIVATION_CODE_TTL_MINUTES", "60"));
    const expiresAt = new Date(now.getTime() + ttlMinutes * 60_000);

    await this.expirePreviousCodes(input.caregiverId, input.dependentId, now);

    for (let attempt = 0; attempt < 5; attempt += 1) {
      try {
        const [created] = await this.dbService.db
          .insert(activationCodes)
          .values({
            code: this.generateActivationCode(),
            caregiverId: input.caregiverId,
            dependentId: input.dependentId,
            caregiverName: input.caregiverName,
            dependentName: input.dependentName,
            expiresAt,
          })
          .returning();

        return this.toActivationCodeResponse(created);
      } catch (error) {
        if (!this.isUniqueViolation(error)) {
          throw error;
        }
      }
    }

    throw new ConflictException("Could not generate a unique activation code");
  }

  async activate(input: ActivateLinkDto): Promise<LinkResponseDto> {
    const normalizedCode = input.code.trim().toUpperCase();
    const now = new Date();

    const createdLink = await this.dbService.db.transaction(async (tx) => {
      const [activationCode] = await tx
        .select()
        .from(activationCodes)
        .where(eq(activationCodes.code, normalizedCode))
        .limit(1);

      if (!activationCode) {
        throw new NotFoundException("Activation code not found");
      }

      if (activationCode.used) {
        throw new ConflictException("Activation code has already been used");
      }

      if (activationCode.expiresAt.getTime() <= now.getTime()) {
        throw new BadRequestException("Activation code has expired");
      }

      const [activeLink] = await tx
        .select()
        .from(links)
        .where(
          and(
            eq(links.caregiverId, activationCode.caregiverId),
            eq(links.dependentId, activationCode.dependentId),
            eq(links.active, true),
          ),
        )
        .limit(1);

      if (activeLink) {
        throw new ConflictException("Caregiver and dependent are already linked");
      }

      const [updatedCode] = await tx
        .update(activationCodes)
        .set({ used: true, usedAt: now })
        .where(and(eq(activationCodes.id, activationCode.id), eq(activationCodes.used, false)))
        .returning();

      if (!updatedCode) {
        throw new ConflictException("Activation code has already been used");
      }

      const [link] = await tx
        .insert(links)
        .values({
          caregiverId: activationCode.caregiverId,
          dependentId: activationCode.dependentId,
          caregiverName: activationCode.caregiverName,
          dependentName: activationCode.dependentName,
        })
        .returning();

      return link;
    });

    const response = this.toLinkResponse(createdLink);
    await this.messagingService.publishLinkEstablished(response);
    return response;
  }

  async list(query: LinkQueryDto): Promise<PaginatedResult<LinkResponseDto>> {
    const page = query._page;
    const limit = query._size;
    const offset = (page - 1) * limit;
    const where = this.buildListWhere(query);
    const orderBy = query._order === "createdAt asc" ? asc(links.createdAt) : desc(links.createdAt);

    const rows = await this.dbService.db
      .select()
      .from(links)
      .where(where)
      .orderBy(orderBy)
      .limit(limit)
      .offset(offset);

    const [totalRow] = await this.dbService.db
      .select({ value: count() })
      .from(links)
      .where(where);

    return {
      data: rows.map((row) => this.toLinkResponse(row)),
      total: totalRow?.value ?? 0,
      page,
      limit,
    };
  }

  async findById(id: string): Promise<LinkResponseDto> {
    const [link] = await this.dbService.db
      .select()
      .from(links)
      .where(eq(links.id, id))
      .limit(1);

    if (!link) {
      throw new NotFoundException("Link not found");
    }

    return this.toLinkResponse(link);
  }

  async remove(id: string): Promise<void> {
    const [updated] = await this.dbService.db
      .update(links)
      .set({ active: false, deactivatedAt: new Date() })
      .where(and(eq(links.id, id), eq(links.active, true)))
      .returning();

    if (!updated) {
      throw new NotFoundException("Active link not found");
    }
  }

  private async ensureNoActiveLink(caregiverId: string, dependentId: string) {
    const [activeLink] = await this.dbService.db
      .select({ id: links.id })
      .from(links)
      .where(
        and(
          eq(links.caregiverId, caregiverId),
          eq(links.dependentId, dependentId),
          eq(links.active, true),
        ),
      )
      .limit(1);

    if (activeLink) {
      throw new ConflictException("Caregiver and dependent are already linked");
    }
  }

  private async expirePreviousCodes(
    caregiverId: string,
    dependentId: string,
    now: Date,
  ) {
    await this.dbService.db
      .update(activationCodes)
      .set({ used: true, usedAt: now })
      .where(
        and(
          eq(activationCodes.caregiverId, caregiverId),
          eq(activationCodes.dependentId, dependentId),
          eq(activationCodes.used, false),
        ),
      );
  }

  private buildListWhere(query: LinkQueryDto): SQL {
    const activeWhere = eq(links.active, true);

    if (!query.userId) {
      return activeWhere;
    }

    if (query.role === "caregiver") {
      return and(activeWhere, eq(links.caregiverId, query.userId))!;
    }

    if (query.role === "dependent") {
      return and(activeWhere, eq(links.dependentId, query.userId))!;
    }

    return and(
      activeWhere,
      or(eq(links.caregiverId, query.userId), eq(links.dependentId, query.userId)),
    )!;
  }

  private generateActivationCode(): string {
    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let code = "";

    for (let index = 0; index < 6; index += 1) {
      code += alphabet[randomInt(0, alphabet.length)];
    }

    return code;
  }

  private toActivationCodeResponse(
    activationCode: ActivationCode,
  ): ActivationCodeResponseDto {
    return {
      id: activationCode.id,
      code: activationCode.code,
      caregiverId: activationCode.caregiverId,
      dependentId: activationCode.dependentId,
      caregiverName: activationCode.caregiverName,
      dependentName: activationCode.dependentName,
      used: activationCode.used,
      expiresAt: activationCode.expiresAt.toISOString(),
      createdAt: activationCode.createdAt.toISOString(),
    };
  }

  private toLinkResponse(link: Link): LinkResponseDto {
    return {
      id: link.id,
      caregiverId: link.caregiverId,
      dependentId: link.dependentId,
      caregiverName: link.caregiverName,
      dependentName: link.dependentName,
      active: link.active,
      createdAt: link.createdAt.toISOString(),
      deactivatedAt: link.deactivatedAt?.toISOString() ?? null,
    };
  }

  private isUniqueViolation(error: unknown): error is { code: string } {
    return (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      (error as { code: unknown }).code === "23505"
    );
  }
}
