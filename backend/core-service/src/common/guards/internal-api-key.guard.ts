import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';

@Injectable()
export class InternalApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const expected = process.env.INTERNAL_API_KEY;
    const received = request.header('x-api-key');

    if (!expected || received !== expected) {
      throw new UnauthorizedException('Invalid internal API key');
    }

    return true;
  }
}
