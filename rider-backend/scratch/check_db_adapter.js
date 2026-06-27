const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
require('dotenv').config();

async function main() {
  const connectionString = process.env.DATABASE_URL;
  const pool = new Pool({ connectionString });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter });

  console.log('--- USERS ---');
  const users = await prisma.user.findMany({
    select: { id: true, email: true, role: true }
  });
  console.table(users);

  console.log('--- DRIVERS ---');
  const drivers = await prisma.driver.findMany();
  console.table(drivers);

  await prisma.$disconnect();
}

main().catch(console.error);
