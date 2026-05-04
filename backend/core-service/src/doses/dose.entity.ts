import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type DoseStatus = 'pending' | 'taken' | 'missed' | 'postponed';

@Entity({ name: 'doses' })
export class Dose {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @Index()
  @Column({ name: 'medication_id' })
  medicationId: string;

  @Index()
  @Column({ name: 'dependent_id', type: 'varchar', nullable: true })
  dependentId: string | null;

  @Column({ name: 'medication_name', length: 120 })
  medicationName: string;

  @Column({ length: 60 })
  dosage: string;

  @Column({ name: 'note', type: 'varchar', length: 200, nullable: true })
  note: string | null;

  @Index()
  @Column({ name: 'scheduled_at', type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ type: 'varchar', length: 20, default: 'pending' })
  status: DoseStatus;

  @Column({ name: 'taken_at', type: 'timestamptz', nullable: true })
  takenAt: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
