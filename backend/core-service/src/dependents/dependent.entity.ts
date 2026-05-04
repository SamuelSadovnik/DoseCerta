import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity({ name: 'dependents' })
export class Dependent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ name: 'user_id' })
  userId: string;

  @Column({ length: 120 })
  name: string;

  @Column({ name: 'birth_date', type: 'date', nullable: true })
  birthDate: string | null;

  @Column({ type: 'varchar', length: 60, nullable: true })
  relationship: string | null;

  @Column({ name: 'activation_code', length: 12 })
  activationCode: string;

  @Index()
  @Column({ name: 'linked_user_id', type: 'varchar', nullable: true })
  linkedUserId: string | null;

  @Column({ name: 'linked_at', type: 'timestamptz', nullable: true })
  linkedAt: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
