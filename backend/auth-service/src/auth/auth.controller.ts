import { Body, Controller, Get, Param, Patch, Post } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { RegisterDto } from "./dto/register.dto";
import { LoginDto } from "./dto/login.dto";
import { UpdateProfileDto } from "./dto/update-profile.dto";

@Controller("auth")
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post("register")
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post("login")
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Patch("users/:id")
  updateProfile(@Param("id") id: string, @Body() dto: UpdateProfileDto) {
    return this.auth.updateProfile(id, dto);
  }

  @Get("users/:id")
  getProfile(@Param("id") id: string) {
    return this.auth.getProfile(id);
  }
}
