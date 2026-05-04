import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Medication } from './medication.entity';
import { CreateMedicationDto } from './dto/create-medication.dto';
import { DosesService } from '../doses/doses.service';
import { calculateDoseCount } from '../doses/dose-frequency';
import { Dependent } from '../dependents/dependent.entity';

@Injectable()
export class MedicationsService {
  constructor(
    @InjectRepository(Medication)
    private readonly repo: Repository<Medication>,
    @InjectRepository(Dependent)
    private readonly dependentsRepo: Repository<Dependent>,
    private readonly doses: DosesService,
  ) {}

  async list(userId: string, dependentId?: string): Promise<Medication[]> {
    if (dependentId) {
      await this.findAccessibleDependent(userId, dependentId);
      return this.repo.find({
        where: { dependentId },
        order: { createdAt: 'DESC' },
      });
    }

    return this.repo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  /** Admin-only. The caller (controller/gateway) must enforce access. */
  listAll(): Promise<Medication[]> {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  async create(userId: string, dto: CreateMedicationDto): Promise<Medication> {
    const requiredQuantity = calculateDoseCount(dto.frequency, dto.durationDays);
    if (dto.initialQuantity < requiredQuantity) {
      throw new BadRequestException(
        `Quantidade insuficiente para a duração/frequência. Necessário: ${requiredQuantity}`,
      );
    }
    const dependent = dto.dependentId
      ? await this.findAccessibleDependent(userId, dto.dependentId)
      : null;
    const ownerUserId = dependent?.linkedUserId ?? userId;
    const med = this.repo.create({
      userId: ownerUserId,
      dependentId: dto.dependentId ?? null,
      name: dto.name,
      dosage: dto.dosage,
      unit: dto.unit,
      initialQuantity: dto.initialQuantity,
      currentQuantity: dto.initialQuantity,
      frequency: dto.frequency,
      durationDays: dto.durationDays,
    });
    const saved = await this.repo.save(med);
    await this.doses.generateForMedication(saved);
    return saved;
  }

  async refill(userId: string, id: string, quantity: number): Promise<Medication> {
    const med = await this.findOwned(userId, id);
    med.currentQuantity += quantity;
    return this.repo.save(med);
  }

  async remove(userId: string, id: string): Promise<void> {
    const med = await this.findOwned(userId, id);
    await this.repo.remove(med);
  }

  private async findOwned(userId: string, id: string): Promise<Medication> {
    const med = await this.repo.findOne({ where: { id, userId } });
    if (!med) throw new NotFoundException('Medicamento não encontrado');
    return med;
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
}
