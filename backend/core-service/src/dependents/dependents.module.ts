import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Dependent } from './dependent.entity';
import { DependentsService } from './dependents.service';
import { DependentsController } from './dependents.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Dependent])],
  providers: [DependentsService],
  controllers: [DependentsController],
  exports: [DependentsService],
})
export class DependentsModule {}
