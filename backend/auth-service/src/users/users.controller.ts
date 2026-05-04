import { Controller, Get, Param } from '@nestjs/common';
import { UsersService } from './users.service';

/**
 * Internal endpoints — only the gateway should reach these.
 * The gateway is responsible for enforcing access control before
 * forwarding (e.g. only admins may hit `GET /users`).
 */
@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  async list() {
    const all = await this.users.listAll();
    return all.map((u) => this.users.toPublic(u));
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    const user = await this.users.findById(id);
    return this.users.toPublic(user);
  }
}
