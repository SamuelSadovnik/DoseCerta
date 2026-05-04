import { Injectable, UnauthorizedException } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { UsersService } from "../users/users.service";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import { UpdateProfileDto } from "./dto/update-profile.dto";

export interface AuthResult {
  accessToken: string;
  user: {
    id: string;
    name: string;
    email: string;
    accountType: string;
    additionalInfo?: Record<string, string> | null;
    emergencyContacts?: Array<Record<string, string>> | null;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthResult> {
    const user = await this.users.create({
      name: dto.name,
      email: dto.email,
      password: dto.password,
      accountType: dto.accountType,
      acceptedTerms: dto.acceptedTerms,
    });
    return this.buildResult(user);
  }

  async login(dto: LoginDto): Promise<AuthResult> {
    const user = await this.users.findByEmail(dto.identifier);
    if (!user) throw new UnauthorizedException("Credenciais inválidas");
    const ok = await this.users.validatePassword(user, dto.password);
    if (!ok) throw new UnauthorizedException("Credenciais inválidas");
    return this.buildResult(user);
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<AuthResult> {
    const user = await this.users.update(userId, {
      name: dto.name,
      email: dto.email,
      currentPassword: dto.currentPassword,
      newPassword: dto.newPassword,
      additionalInfo: dto.additionalInfo,
      emergencyContacts: dto.emergencyContacts,
    });
    return this.buildResult(user);
  }

  async getProfile(userId: string): Promise<AuthResult> {
    const user = await this.users.findById(userId);
    return this.buildResult(user);
  }

  private buildResult(user: {
    id: string;
    name: string;
    email: string;
    accountType: string;
    additionalInfo?: Record<string, string> | null;
    emergencyContacts?: Array<Record<string, string>> | null;
  }): AuthResult {
    const accessToken = this.jwt.sign({
      sub: user.id,
      email: user.email,
      accountType: user.accountType,
    });
    return {
      accessToken,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        accountType: user.accountType,
        additionalInfo: user.additionalInfo ?? null,
        emergencyContacts: user.emergencyContacts ?? [],
      },
    };
  }
}
