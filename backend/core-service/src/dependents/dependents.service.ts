import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  HttpException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Dependent } from './dependent.entity';
import { CreateDependentDto } from './dto/create-dependent.dto';
import { RequestUser } from '../common/current-user.decorator';

@Injectable()
export class DependentsService {
  private readonly linkingServiceUrl =
    process.env.LINKING_SERVICE_URL || 'http://host.docker.internal:3003';
  private readonly linkingApiKey =
    process.env.LINKING_SERVICE_API_KEY || 'dosecerta-internal-key-linking';

  constructor(
    @InjectRepository(Dependent)
    private readonly repo: Repository<Dependent>,
  ) {}

  list(userId: string): Promise<Dependent[]> {
    return this.repo.find({
      where: [{ userId }, { linkedUserId: userId }],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Links the calling user (the dependent) to a registry created by a
   * caregiver, via the activation code printed in the caregiver's app.
   */
  async link(callerUserId: string, rawCode: string): Promise<Dependent> {
    const code = rawCode.trim().toUpperCase();
    if (code.length === 0) {
      throw new BadRequestException('Código inválido');
    }
    const dep = await this.repo.findOne({ where: { activationCode: code } });
    if (!dep) {
      throw new NotFoundException('Código não encontrado');
    }
    if (dep.userId === callerUserId) {
      throw new ForbiddenException(
        'Você não pode se vincular como dependente de si mesmo',
      );
    }
    if (dep.linkedUserId) {
      throw new ConflictException('Este código já foi utilizado');
    }
    await this.activateLinkingCode(code);
    dep.linkedUserId = callerUserId;
    dep.linkedAt = new Date();
    return this.repo.save(dep);
  }

  /** Admin-only. The caller must enforce access. */
  listAll(): Promise<Dependent[]> {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  async create(user: RequestUser, dto: CreateDependentDto): Promise<Dependent> {
    const dep = await this.repo.save(
      this.repo.create({
        userId: user.id,
        name: dto.name,
        birthDate: dto.birthDate ?? null,
        relationship: dto.relationship ?? null,
        activationCode: this.generateCode(),
      }),
    );

    let activationCode: string;
    try {
      activationCode = await this.generateLinkingCode({
        userId: user.id,
        caregiverName: user.email,
        dependentId: dep.id,
        dependentName: dep.name,
      });
    } catch (error) {
      await this.repo.remove(dep);
      throw error;
    }

    dep.activationCode = activationCode;
    return this.repo.save(dep);
  }

  async remove(userId: string, id: string): Promise<void> {
    const dep = await this.repo.findOne({ where: { id, userId } });
    if (!dep) throw new NotFoundException('Dependente não encontrado');
    await this.repo.remove(dep);
  }

  async unlink(callerUserId: string): Promise<void> {
    const dep = await this.repo.findOne({
      where: { linkedUserId: callerUserId },
    });
    if (!dep) {
      throw new NotFoundException('Vínculo não encontrado');
    }
    dep.linkedUserId = null;
    dep.linkedAt = null;
    await this.repo.save(dep);
  }

  private generateCode(): string {
    return Math.random().toString(36).slice(2, 10).toUpperCase();
  }

  private async generateLinkingCode(input: {
    userId: string;
    caregiverName: string;
    dependentId: string;
    dependentName: string;
  }): Promise<string> {
    const response = await this.callLinkingService<{
      code: string;
    }>('/api/v1/links/generate', {
      caregiverId: input.userId,
      caregiverName: input.caregiverName,
      dependentId: input.dependentId,
      dependentName: input.dependentName,
    });

    return response.code;
  }

  private async activateLinkingCode(code: string): Promise<void> {
    await this.callLinkingService('/api/v1/links/activate', { code });
  }

  private async callLinkingService<T = unknown>(
    path: string,
    body: Record<string, unknown>,
  ): Promise<T> {
    const response = await fetch(`${this.linkingServiceUrl}${path}`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': this.linkingApiKey,
      },
      body: JSON.stringify(body),
    });

    const payload = (await response.json().catch(() => null)) as
      | Record<string, unknown>
      | null;

    if (!response.ok) {
      const message =
        typeof payload?.error === 'object' &&
        payload.error !== null &&
        'message' in payload.error
          ? ((payload.error as { message?: string }).message ??
            'Erro ao comunicar com o serviço de vinculação')
          : 'Erro ao comunicar com o serviço de vinculação';
      throw new HttpException(message, response.status);
    }

    return payload as T;
  }
}
