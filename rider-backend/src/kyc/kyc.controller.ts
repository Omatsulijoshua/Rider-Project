import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Patch,
  UseGuards,
  Req,
} from '@nestjs/common';
import { KycService } from './kyc.service';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { KycUpdateDto } from './dto/kyc-update.dto';
import { AuthGuard } from '@nestjs/passport';
import { RolesGuard } from '../auth/roles.guard';
import { Roles, Role } from '../auth/roles.decorator';

@Controller('kyc')
export class KycController {
  constructor(private readonly kycService: KycService) {}

  // ✅ User submits KYC
  @UseGuards(AuthGuard('jwt'))
  @Post('submit')
  async submitKyc(@Req() req: any, @Body() dto: SubmitKycDto) {
    return this.kycService.submitKyc(
      req.user.userId,
      dto.type,
      dto.documents,
      dto.selfie,
    );
  }

  // ✅ Admin approves KYC
  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Patch(':id/approve')
  async approveKyc(@Param('id') id: string) {
    return this.kycService.approveKyc(id);
  }

  // ✅ Admin rejects KYC
  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Patch(':id/reject')
  async rejectKyc(@Param('id') id: string, @Body() dto: KycUpdateDto) {
    return this.kycService.rejectKyc(id, dto.reason || 'Rejected by admin');
  }

  // ✅ Admin gets all KYCs
  @UseGuards(AuthGuard('jwt'), RolesGuard)
  @Roles(Role.ADMIN)
  @Get('all')
  async getAllKyc() {
    return this.kycService.getAllKyc();
  }

  // ✅ User gets own KYCs
  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  async getMyKyc(@Req() req: any) {
    return this.kycService.getByUser(req.user.userId);
  }
}
