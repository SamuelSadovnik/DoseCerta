import { Injectable, HttpException } from "@nestjs/common";
import { HttpService } from "@nestjs/axios";
import { firstValueFrom } from "rxjs";
import { AxiosError } from "axios";

@Injectable()
export class AuthProxyService {
  private readonly baseUrl =
    process.env.AUTH_SERVICE_URL || "http://auth-service:3001";

  constructor(private readonly http: HttpService) {}

  async forward(path: string, body: unknown) {
    try {
      const { data } = await firstValueFrom(
        this.http.post(`${this.baseUrl}/auth/${path}`, body),
      );
      return data;
    } catch (e) {
      this.rethrow(e as AxiosError);
    }
  }

  async patch(path: string, body: unknown) {
    try {
      const { data } = await firstValueFrom(
        this.http.patch(`${this.baseUrl}/auth/${path}`, body),
      );
      return data;
    } catch (e) {
      this.rethrow(e as AxiosError);
    }
  }

  async get(path: string) {
    try {
      const { data } = await firstValueFrom(
        this.http.get(`${this.baseUrl}/auth/${path}`),
      );
      return data;
    } catch (e) {
      this.rethrow(e as AxiosError);
    }
  }

  private rethrow(err: AxiosError): never {
    const status = err.response?.status ?? 502;
    const data = err.response?.data ?? { message: "Upstream error" };
    throw new HttpException(data, status);
  }
}
