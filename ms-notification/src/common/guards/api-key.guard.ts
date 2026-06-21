import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { Request } from "express";
import { isIP } from "node:net";

@Injectable()
export class ApiKeyGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const expectedApiKey = this.configService.get<string>("API_KEY");
    const receivedApiKey = request.header("x-api-key");

    if (!expectedApiKey || receivedApiKey !== expectedApiKey) {
      throw new UnauthorizedException("Invalid API key");
    }

    if (!this.isAllowedIp(this.resolveClientIp(request))) {
      throw new UnauthorizedException("IP address is not allowed");
    }

    return true;
  }

  private resolveClientIp(request: Request): string {
    const forwardedFor = request.header("x-forwarded-for");
    const rawIp = forwardedFor?.split(",")[0]?.trim() || request.ip || "";
    return rawIp.replace("::ffff:", "");
  }

  private isAllowedIp(ip: string): boolean {
    const allowedIps = this.configService
      .get<string>("ALLOWED_IPS", "")
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);

    if (allowedIps.length === 0) return true;

    return allowedIps.some((allowedIp) => {
      if (allowedIp.includes("/")) {
        return this.matchesCidr(ip, allowedIp);
      }

      return allowedIp.replace("::ffff:", "") === ip;
    });
  }

  private matchesCidr(ip: string, cidr: string): boolean {
    const [range, bitsRaw] = cidr.split("/");
    const bits = Number(bitsRaw);

    if (isIP(ip) !== 4 || isIP(range) !== 4 || !Number.isInteger(bits)) {
      return false;
    }

    const ipNumber = this.ipv4ToNumber(ip);
    const rangeNumber = this.ipv4ToNumber(range);
    const mask = bits === 0 ? 0 : 0xffffffff << (32 - bits);

    return (ipNumber & mask) === (rangeNumber & mask);
  }

  private ipv4ToNumber(ip: string): number {
    return ip
      .split(".")
      .reduce((acc, octet) => (acc << 8) + Number(octet), 0);
  }
}
