import { PrismaClient } from '@prisma/client';

import {
  DeviceTokenRepository,
  DeviceTokenEntry,
  UpsertDeviceTokenData,
} from '../domain/repositories/device-token.repository';

export class PrismaDeviceTokenRepository implements DeviceTokenRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async upsert(data: UpsertDeviceTokenData): Promise<void> {
    // Si el token ya existe (mismo dispositivo) → actualiza district y timestamp
    // Si no existe → crea el registro
    await this.prisma.deviceToken.upsert({
      where: { token: data.token },
      update: { district: data.district, userId: data.userId },
      create: { userId: data.userId, token: data.token, district: data.district },
    });
  }

  async deleteByToken(token: string): Promise<void> {
    // deleteMany en vez de delete para no lanzar error si el token no existe
    await this.prisma.deviceToken.deleteMany({ where: { token } });
  }

  async findByDistrict(district: string): Promise<string[]> {
    const rows = await this.prisma.deviceToken.findMany({
      where: { district },
      select: { token: true },
    });
    return rows.map((r) => r.token);
  }

  async findByDistrictWithUserId(district: string): Promise<DeviceTokenEntry[]> {
    const rows = await this.prisma.deviceToken.findMany({
      where: { district },
      select: { token: true, userId: true },
    });
    return rows;
  }
}
