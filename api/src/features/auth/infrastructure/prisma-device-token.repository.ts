import { PrismaClient } from '@prisma/client';

import {
  DeviceTokenRepository,
  DeviceTokenEntry,
  UpsertDeviceTokenData,
} from '../domain/repositories/device-token.repository';

export class PrismaDeviceTokenRepository implements DeviceTokenRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async upsert(data: UpsertDeviceTokenData): Promise<void> {
    // Si el token ya existe (mismo dispositivo) → actualiza district + proxTile y timestamp
    // Si no existe → crea el registro
    await this.prisma.deviceToken.upsert({
      where: { token: data.token },
      update: {
        district: data.district,
        userId: data.userId,
        // Solo overwritear proxTile si vino algo — preserva el último conocido si null.
        ...(data.proxTile !== undefined && { proxTile: data.proxTile }),
      },
      create: {
        userId: data.userId,
        token: data.token,
        district: data.district,
        proxTile: data.proxTile ?? null,
      },
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

  async findByProxTiles(proxTiles: string[]): Promise<DeviceTokenEntry[]> {
    if (proxTiles.length === 0) return [];
    const rows = await this.prisma.deviceToken.findMany({
      where: { proxTile: { in: proxTiles } },
      select: { token: true, userId: true },
    });
    return rows;
  }
}
