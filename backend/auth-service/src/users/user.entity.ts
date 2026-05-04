import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from "typeorm";

export type AccountType = "personal" | "caregiver" | "admin";

@Entity({ name: "users" })
export class User {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ length: 120 })
  name: string;

  @Index({ unique: true })
  @Column({ length: 180 })
  email: string;

  @Column({ name: "password_hash", length: 200 })
  passwordHash: string;

  @Column({
    name: "account_type",
    type: "varchar",
    length: 20,
    default: "personal",
  })
  accountType: AccountType;

  @Column({ name: "accepted_terms", default: false })
  acceptedTerms: boolean;

  @Column({ name: "additional_info", type: "jsonb", nullable: true })
  additionalInfo?: Record<string, string> | null;

  @Column({ name: "emergency_contacts", type: "jsonb", nullable: true })
  emergencyContacts?: Array<Record<string, string>> | null;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
