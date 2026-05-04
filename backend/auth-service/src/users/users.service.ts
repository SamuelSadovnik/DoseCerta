import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import * as bcrypt from "bcryptjs";
import { AccountType, User } from "./user.entity";

export interface CreateUserInput {
  name: string;
  email: string;
  password: string;
  accountType: AccountType;
  acceptedTerms?: boolean;
}

export interface UpdateUserInput {
  name?: string;
  email?: string;
  currentPassword?: string;
  newPassword?: string;
  additionalInfo?: Record<string, string>;
  emergencyContacts?: Array<Record<string, string>>;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  async create(input: CreateUserInput): Promise<User> {
    const existing = await this.repo.findOne({ where: { email: input.email } });
    if (existing) {
      throw new ConflictException("Email já cadastrado");
    }
    const passwordHash = await bcrypt.hash(input.password, 10);
    const user = this.repo.create({
      name: input.name,
      email: input.email,
      passwordHash,
      accountType: input.accountType,
      acceptedTerms: input.acceptedTerms ?? false,
    });
    return this.repo.save(user);
  }

  findByEmail(email: string): Promise<User | null> {
    return this.repo.findOne({ where: { email } });
  }

  listAll(): Promise<User[]> {
    return this.repo.find({ order: { createdAt: "DESC" } });
  }

  async findById(id: string): Promise<User> {
    const user = await this.repo.findOne({ where: { id } });
    if (!user) throw new NotFoundException("Usuário não encontrado");
    return user;
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const user = await this.findById(id);

    if (input.email && input.email !== user.email) {
      const existing = await this.repo.findOne({
        where: { email: input.email },
      });
      if (existing && existing.id !== user.id) {
        throw new ConflictException("Email já cadastrado");
      }
      user.email = input.email;
    }

    if (input.name && input.name.trim().length >= 2) {
      user.name = input.name.trim();
    }

    if (input.newPassword) {
      if (!input.currentPassword) {
        throw new UnauthorizedException("Informe a senha atual");
      }
      const ok = await this.validatePassword(user, input.currentPassword);
      if (!ok) throw new UnauthorizedException("Senha atual inválida");
      user.passwordHash = await bcrypt.hash(input.newPassword, 10);
    }

    if (input.additionalInfo !== undefined) {
      user.additionalInfo = input.additionalInfo;
    }

    if (input.emergencyContacts !== undefined) {
      user.emergencyContacts = input.emergencyContacts;
    }

    return this.repo.save(user);
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.passwordHash);
  }

  toPublic(user: User) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      accountType: user.accountType,
      additionalInfo: user.additionalInfo ?? null,
      emergencyContacts: user.emergencyContacts ?? [],
    };
  }
}
