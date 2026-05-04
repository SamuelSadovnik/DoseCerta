import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Dependent } from './dependent.entity';
import { CreateDependentDto } from './dto/create-dependent.dto';

@Injectable()
export class DependentsService {
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
    dep.linkedUserId = callerUserId;
    dep.linkedAt = new Date();
    return this.repo.save(dep);
  }

  /** Admin-only. The caller must enforce access. */
  listAll(): Promise<Dependent[]> {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  async create(userId: string, dto: CreateDependentDto): Promise<Dependent> {
    const dep = this.repo.create({
      userId,
      name: dto.name,
      birthDate: dto.birthDate ?? null,
      relationship: dto.relationship ?? null,
      activationCode: this.generateCode(),
    });
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
}
