import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type MedicationUnit = 'tablet' | 'capsule' | 'drop' | 'ml' | 'mg' | 'other';
export type MedicationStatus = 'active' | 'ended';

@Entity({ name: 'medications' })
export class Medication {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @Index()
  @Column({ name: 'dependent_id', type: 'varchar', nullable: true })
  dependentId: string | null;

  @Column({ length: 120 })
  name: string;

  @Column({ length: 60 })
  dosage: string;

  @Column({ type: 'varchar', length: 20, default: 'tablet' })
  unit: MedicationUnit;

  @Column({ name: 'current_quantity', type: 'int' })
  currentQuantity: number;

  @Column({ name: 'initial_quantity', type: 'int' })
  initialQuantity: number;

  @Column({ length: 120 })
  frequency: string;

  @Column({ name: 'duration_days', type: 'int' })
  durationDays: number;

  @Column({ type: 'varchar', length: 20, default: 'active' })
  status: MedicationStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
