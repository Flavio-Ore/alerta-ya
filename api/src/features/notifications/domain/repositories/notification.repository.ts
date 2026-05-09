import { NotificationType } from '@prisma/client';

export interface CreateNotificationData {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  incidentId?: string | null;
}

export interface NotificationDTO {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  incidentId: string | null;
  readAt: string | null;
  createdAt: string;
}

export interface FindByUserOptions {
  unreadOnly?: boolean;
  page: number;
  pageSize: number;
}

export interface NotificationRepository {
  create(data: CreateNotificationData): Promise<void>;
  findByUser(userId: string, options: FindByUserOptions): Promise<{
    items: NotificationDTO[];
    total: number;
    unreadCount: number;
  }>;
  /** Marca como leídas solo las notificaciones que pertenecen al userId */
  markAsRead(ids: string[], userId: string): Promise<number>;
  /** Marca todas las notificaciones del usuario como leídas */
  markAllAsRead(userId: string): Promise<number>;
}
