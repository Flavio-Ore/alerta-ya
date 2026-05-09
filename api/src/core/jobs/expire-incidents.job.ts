import { PrismaClient } from '@prisma/client';

export async function expireIncidents(prisma: PrismaClient): Promise<{ closed: number }> {
  const result = await prisma.incident.updateMany({
    where: {
      status: { in: ['ACTIVE', 'IN_ATTENTION'] },
      expiresAt: { lt: new Date() },
    },
    data: { status: 'CLOSED' },
  });

  return { closed: result.count };
}
