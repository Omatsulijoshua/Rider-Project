import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { OrdersGateway } from './orders.gateway';
import { OrdersService } from './orders.service';

describe('OrdersService', () => {
  let service: OrdersService;

  const mockPrismaService = {
    order: {
      findUnique: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
    },
    driver: {
      count: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  const mockOrdersGateway = {
    broadcastDebug: jest.fn(),
    emitOrderRequest: jest.fn(),
    emitOrderUpdate: jest.fn(),
  };

  const mockWalletService = {
    findOrCreateWallet: jest.fn(),
    debit: jest.fn(),
    credit: jest.fn(),
    recordTransaction: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: OrdersGateway, useValue: mockOrdersGateway },
        { provide: WalletService, useValue: mockWalletService },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('quotes a delivery using server-side distance, ETA, and fees', () => {
    const quote = service.quoteOrder({
      pickupLat: 6.5244,
      pickupLng: 3.3792,
      dropLat: 6.6018,
      dropLng: 3.3515,
      weight: 8,
      priority: true,
    });

    expect(quote.currency).toBe('NGN');
    expect(quote.distanceKm).toBeGreaterThan(0);
    expect(quote.durationMinutes).toBeGreaterThan(0);
    expect(quote.priorityFee).toBe(750);
    expect(quote.total).toBeGreaterThan(quote.baseFare);
  });
});
