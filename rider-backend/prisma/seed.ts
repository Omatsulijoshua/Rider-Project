import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as bcrypt from 'bcrypt';
import 'dotenv/config';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  try {
    // Create admin
    const adminExists = await prisma.user.findUnique({
      where: { email: 'joshuaomatsuli01@gmail.com' },
    });

    let admin = adminExists;
    if (!admin) {
      const hashedPassword = await bcrypt.hash('Admin@123456', 10);
      admin = await prisma.user.create({
        data: {
          email: 'joshuaomatsuli01@gmail.com',
          phone: '+2348123456789',
          name: 'Admin User',
          passwordHash: hashedPassword,
          role: 'ADMIN',
          status: 'ACTIVE',
          isActive: true,
        },
      });
      console.log('✅ Admin user created:', admin.email);
    }

    // Create sample customers
    const customers: any[] = [];
    for (let i = 1; i <= 5; i++) {
      customers.push(
        await prisma.user.create({
          data: {
            email: `customer${i}@rider.com`,
            phone: `+234812345678${i}`,
            name: `Customer ${i}`,
            passwordHash: await bcrypt.hash('Password123', 10),
            role: 'CUSTOMER',
            status: 'ACTIVE',
            isActive: true,
          },
        }),
      );
    }
    console.log('✅ Created 5 sample customers');

    // Create sample drivers
    const drivers: any[] = [];
    for (let i = 1; i <= 5; i++) {
      const driverUser = await prisma.user.create({
        data: {
          email: `driver${i}@rider.com`,
          phone: `+234913345678${i}`,
          name: `Driver ${i}`,
          passwordHash: await bcrypt.hash('Password123', 10),
          role: 'DRIVER',
          status: 'ACTIVE',
          isActive: true,
        },
      });

      const driver = await prisma.driver.create({
        data: {
          userId: driverUser.id,
          isOnline: i % 2 === 0,
          latitude: 6.5244 + (Math.random() - 0.5),
          longitude: 3.3792 + (Math.random() - 0.5),
        },
      });
      drivers.push(driver);
    }
    console.log('✅ Created 5 sample drivers');

    // Create customer wallets
    for (const customer of customers) {
      await (prisma.wallet.create({
        data: {
          userId: customer.id,
          type: 'CUSTOMER',
          balance: Math.random() * 50000,
        },
      }) as any);
    }

    // Create driver wallets
    for (const driver of drivers) {
      await (prisma.wallet.create({
        data: {
          userId: driver.userId,
          type: 'DRIVER',
          balance: Math.random() * 100000,
        },
      }) as any);
    }
    console.log('✅ Created wallets for customers and drivers');

    // Create sample orders
    for (let i = 0; i < 10; i++) {
      const customer = customers[Math.floor(Math.random() * customers.length)];
      const driver = drivers[Math.floor(Math.random() * drivers.length)];
      const statuses = ['COMPLETED', 'ACCEPTED', 'EN_ROUTE', 'DESTINATION_REACHED', 'CANCELLED'] as const;
      const price = Math.random() * 10000 + 2000;

      await prisma.order.create({
        data: {
          trackingId: `SEED-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
          customerId: customer.id,
          driverId: driver.id,
          status: statuses[Math.floor(Math.random() * statuses.length)],
          pickupLat: 6.5244,
          pickupLng: 3.3792,
          dropLat: 6.4969,
          dropLng: 3.3676,
          pickupAddress: "Lagos Mainland",
          dropoffAddress: "Victoria Island",
          price,
          createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
        },
      });
    }
    console.log('✅ Created 10 sample orders');

    console.log('\n✅ Database seeded successfully!');
    console.log('📊 Summary:');
    console.log('   - 1 admin user');
    console.log('   - 5 customers');
    console.log('   - 5 drivers');
    console.log('   - 10 wallets (customers + drivers)');
    console.log('   - 10+ orders');
    console.log('   - Ready for admin dashboard!');
  } catch (error) {
    console.error('Error seeding database:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main();
