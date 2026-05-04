import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { Request } from "express";
import { AuthProxyService } from "./auth-proxy.service";
import { JwtAuthGuard } from "../common/guards/jwt-auth.guard";

@Controller("auth")
export class AuthProxyController {
  constructor(private readonly proxy: AuthProxyService) {}

  @Post("login")
  login(@Body() body: unknown) {
    return this.proxy.forward("login", body);
  }

  @Post("register")
  register(@Body() body: unknown) {
    return this.proxy.forward("register", body);
  }

  @UseGuards(JwtAuthGuard)
  @Patch("me")
  updateMe(@Req() req: Request, @Body() body: unknown) {
    const user = req.user as { id: string };
    return this.proxy.patch(`users/${user.id}`, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get("me")
  getMe(@Req() req: Request) {
    const user = req.user as { id: string };
    return this.proxy.get(`users/${user.id}`);
  }
}
