import { HttpException, Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { AxiosError, AxiosRequestConfig } from 'axios';

export interface AdminUser {
  id: string;
  email: string;
  accountType: string;
}

@Injectable()
export class AdminProxyService {
  constructor(private readonly http: HttpService) {}

  private readonly authUrl =
    process.env.AUTH_SERVICE_URL || 'http://auth-service:3001';
  private readonly coreUrl =
    process.env.CORE_SERVICE_URL || 'http://core-service:3002';

  forwardToAuth(path: string, user: AdminUser) {
    return this.request(`${this.authUrl}/${path}`, user);
  }

  forwardToCore(path: string, user: AdminUser) {
    return this.request(`${this.coreUrl}/${path}`, user);
  }

  private async request(url: string, user: AdminUser) {
    const config: AxiosRequestConfig = {
      method: 'GET',
      url,
      headers: {
        'x-user-id': user.id,
        'x-user-email': user.email,
        'x-user-account-type': user.accountType,
      },
    };
    try {
      const { data } = await firstValueFrom(this.http.request(config));
      return data;
    } catch (e) {
      const err = e as AxiosError;
      const status = err.response?.status ?? 502;
      const body = err.response?.data ?? { message: 'Upstream error' };
      throw new HttpException(body, status);
    }
  }
}
