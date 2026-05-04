import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type AppointmentStatus = 'scheduled' | 'confirmed' | 'rescheduled' | 'cancelled' | 'done';

@Entity({ name: 'appointments' })
export class Appointment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @Index()
  @Column({ name: 'dependent_id', type: 'varchar', nullable: true })
  dependentId: string | null;

  @Column({ name: 'doctor_name', length: 120 })
  doctorName: string;

  @Column({ type: 'varchar', length: 120, nullable: true })
  specialty: string | null;

  @Column({ name: 'scheduled_at', type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ type: 'varchar', length: 200, nullable: true })
  location: string | null;

  @Column({ type: 'varchar', length: 20, default: 'scheduled' })
  status: AppointmentStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
