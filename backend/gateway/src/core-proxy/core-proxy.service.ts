import { Injectable, HttpException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { AxiosError, AxiosRequestConfig } from 'axios';

export interface ForwardUser {
  id: string;
  email: string;
  accountType: string;
}

interface PublicUser {
  id: string;
  name: string;
  email: string;
}

interface DependentPayload {
  userId?: string;
  caregiverName?: string;
  caregiverEmail?: string;
  [key: string]: unknown;
}

@Injectable()
export class CoreProxyService {
  private readonly baseUrl =
    process.env.CORE_SERVICE_URL || 'http://core-service:3002';
  private readonly authUrl =
    process.env.AUTH_SERVICE_URL || 'http://auth-service:3001';

  constructor(private readonly http: HttpService) {}

  async forward(opts: {
    method: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    path: string;
    user: ForwardUser;
    query?: Record<string, unknown>;
    body?: unknown;
  }) {
    const config: AxiosRequestConfig = {
      method: opts.method,
      url: `${this.baseUrl}/${opts.path.replace(/^\//, '')}`,
      params: opts.query,
      data: opts.body,
      headers: {
        'x-user-id': opts.user.id,
        'x-user-email': opts.user.email,
        'x-user-account-type': opts.user.accountType,
      },
    };
    try {
      const { data } = await firstValueFrom(this.http.request(config));
      return data;
    } catch (e) {
      const err = e as AxiosError;
      const status = err.response?.status ?? 502;
      const data = err.response?.data ?? { message: 'Upstream error' };
      throw new HttpException(data, status);
    }
  }

  async enrichDependentsWithCaregivers(payload: unknown): Promise<unknown> {
    if (!Array.isArray(payload)) return payload;
    const dependents = payload as DependentPayload[];
    const caregiverIds = [
      ...new Set(
        dependents
          .map((dependent) => dependent.userId)
          .filter((id): id is string => typeof id === 'string' && id.length > 0),
      ),
    ];
    if (caregiverIds.length === 0) return dependents;

    const users = new Map<string, PublicUser>();
    await Promise.all(
      caregiverIds.map(async (id) => {
        const user = await this.getAuthUser(id);
        if (user) users.set(id, user);
      }),
    );

    return dependents.map((dependent) => {
      const caregiver = dependent.userId ? users.get(dependent.userId) : null;
      return {
        ...dependent,
        caregiverName: caregiver?.name ?? null,
        caregiverEmail: caregiver?.email ?? null,
      };
    });
  }

  private async getAuthUser(id: string): Promise<PublicUser | null> {
    try {
      const { data } = await firstValueFrom(
        this.http.get<PublicUser>(`${this.authUrl}/users/${id}`),
      );
      return data;
    } catch {
      return null;
    }
  }
}
