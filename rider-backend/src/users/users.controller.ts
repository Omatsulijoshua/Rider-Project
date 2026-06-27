import { Controller, Get, Param, Patch } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getAllUsers() {
    return this.usersService.getAll();
  }

  @Get(':id')
  getUser(@Param('id') id: string) {
    return this.usersService.getById(id);
  }

  @Patch(':id/activate')
  activate(@Param('id') id: string) {
    return this.usersService.activate(id);
  }

  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.usersService.deactivate(id);
  }

  @Patch(':id/block')
  block(@Param('id') id: string) {
    return this.usersService.block(id);
  }

  @Patch(':id/unblock')
  unblock(@Param('id') id: string) {
    return this.usersService.unblock(id);
  }
}
