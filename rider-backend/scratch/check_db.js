const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- USERS ---');
  const users = await prisma.user.findMany({
    select: { id: true, email: true, role: true }
  });
  console.table(users);

  console.log('--- DRIVERS ---');
  const drivers = await prisma.driver.findMany();
  console.table(drivers);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
