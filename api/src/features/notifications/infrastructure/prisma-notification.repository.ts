import { PrismaClient } from '@prisma/client';

import {
  NotificationRepository,
  CreateNotificationData,
  NotificationDTO,
  FindByUserOptions,
} from '../domain/repositories/notification.repository';

function toDTO(n: {
  id: string;
  type: string;
  title: string;
  body: string;
  incidentId: string | null;
  readAt: Date | null;
  createdAt: Date;
}): NotificationDTO {
  return {
    id: n.id,
    type: n.type as NotificationDTO['type'],
    title: n.title,
    body: n.body,
    incidentId: n.incidentId,
    readAt: n.readAt?.toISOString() ?? null,
    createdAt: n.createdAt.toISOString(),
  };
}

export class PrismaNotificationRepository implements NotificationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CreateNotificationData): Promise<void> {
    await this.prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        incidentId: data.incidentId ?? null,
      },
    });
  }

  async findByUser(
    userId: string,
    options: FindByUserOptions,
  ): Promise<{ items: NotificationDTO[]; total: number; unreadCount: number }> {
    const where = {
      userId,
      ...(options.unreadOnly ? { readAt: null } : {}),
    };

    const skip = (options.page - 1) * options.pageSize;

    const [items, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: options.pageSize,
        select: {
          id: true,
          type: true,
          title: true,
          body: true,
          incidentId: true,
          readAt: true,
          createdAt: true,
        },
      }),
      this.prisma.notification.count({ where }),
      // Siempre devolver el total de no leídas (independiente del filtro)
      this.prisma.notification.count({ where: { userId, readAt: null } }),
    ]);

    return { items: items.map(toDTO), total, unreadCount };
  }

  async markAsRead(ids: string[], userId: string): Promise<number> {
    // El filtro por userId evita que un usuario marque notifs de otro
    const result = await this.prisma.notification.updateMany({
      where: { id: { in: ids }, userId, readAt: null },
      data: { readAt: new Date() },
    });
    return result.count;
  }

  async markAllAsRead(userId: string): Promise<number> {
    const result = await this.prisma.notification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return result.count;
  }
}
