import { PrismaClient, User } from '@prisma/client';

export class UserLookupService {
  constructor(private readonly prisma: PrismaClient) {}

  async findOrCreate(firebaseUid: string): Promise<User> {
    const existing = await this.prisma.user.findUnique({ where: { firebaseUid } });
    if (existing) return existing;

    return this.prisma.user.create({
      data: { firebaseUid, reputationScore: 100 },
    });
  }
}
