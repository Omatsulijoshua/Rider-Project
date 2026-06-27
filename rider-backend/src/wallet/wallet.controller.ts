import { Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('wallet')
@UseGuards(AuthGuard('jwt'))
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('me')
  async getMyWallet(@Req() req) {
    const userId = req.user.userId;
    // Assume user type from role, but here we just need to find or create
    return this.walletService.findOrCreateWallet(userId, req.user.role);
  }

  @Get('transactions')
  async getMyTransactions(@Req() req) {
    const userId = req.user.userId;
    const wallet = await this.walletService.getWallet(userId);
    if (!wallet) return [];
    return this.walletService.getTransactions(wallet.id);
  }

  @Post('me/topup')
  async topup(@Req() req, @Body('amount') amount: number) {
    const userId = req.user.userId;
    const wallet = await this.walletService.findOrCreateWallet(userId, req.user.role);
    return this.walletService.credit(wallet.id, amount, 'TOPUP', 'MANUAL_TOPUP');
  }
}
