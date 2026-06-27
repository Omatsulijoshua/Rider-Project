// src/kyc/kyc.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// ✅ Local enum as fallback / TypeScript-friendly
export enum KycStatusEnum {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

@Injectable()
export class KycService {
  constructor(private prisma: PrismaService) {}

  // ✅ Submit KYC
  async submitKyc(
    userId: string,
    type: 'CUSTOMER' | 'DRIVER',
    documents: string[],
    selfie?: string,
  ) {
    return this.prisma.kyc.create({
      data: {
        userId,
        type,
        documents,
        selfie,
        status: KycStatusEnum.PENDING,
      },
    });
  }

  // ✅ Admin: Approve KYC
  async approveKyc(kycId: string) {
    const kyc = await this.prisma.kyc.update({
      where: { id: kycId },
      data: {
        status: KycStatusEnum.APPROVED,
        reason: null,
      },
    });

    if (!kyc) throw new NotFoundException('KYC not found');
    return kyc;
  }

  // ✅ Admin: Reject KYC
  async rejectKyc(kycId: string, reason: string) {
    const kyc = await this.prisma.kyc.update({
      where: { id: kycId },
      data: {
        status: KycStatusEnum.REJECTED,
        reason,
      },
    });

    if (!kyc) throw new NotFoundException('KYC not found');
    return kyc;
  }

  // ✅ Get all KYC requests
  async getAllKyc() {
    return this.prisma.kyc.findMany({
      include: { user: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ✅ Get KYC by user
  async getByUser(userId: string) {
    return this.prisma.kyc.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ✅ Get KYC by ID
  async getById(kycId: string) {
    const kyc = await this.prisma.kyc.findUnique({
      where: { id: kycId },
      include: { user: true },
    });

    if (!kyc) throw new NotFoundException('KYC not found');
    return kyc;
  }
}
