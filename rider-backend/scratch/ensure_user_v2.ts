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
  const email = 'joshuaomasul01@gmail.com';
  const password = 'Jos@56567';
  const passwordHash = await bcrypt.hash(password, 10);

  // Upsert User
  const user = await prisma.user.upsert({
    where: { email },
    update: {
      passwordHash,
      status: 'ACTIVE',
      role: 'DRIVER',
    },
    create: {
      email,
      name: 'Joshua Omasul',
      phone: '08000000001',
      passwordHash,
      role: 'DRIVER',
      status: 'ACTIVE',
    },
  });

  console.log(`User ${user.email} ensured.`);

  // Ensure Driver record exists
  await prisma.driver.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      isOnline: true,
    },
  });
  console.log(`Driver record for ${user.email} ensured.`);

  // Ensure Wallet exists
  await prisma.wallet.upsert({
    where: { userId: user.id },
    update: {},
    create: {
      userId: user.id,
      type: 'DRIVER',
      balance: 1000.0,
    },
  });
  console.log(`Wallet for ${user.email} ensured.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
