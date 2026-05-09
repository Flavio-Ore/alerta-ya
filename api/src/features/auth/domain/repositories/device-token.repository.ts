export interface UpsertDeviceTokenData {
  userId: string;
  token: string;
  district: string;
}

export interface DeviceTokenEntry {
  token: string;
  userId: string;
}

export interface DeviceTokenRepository {
  /** Inserta o actualiza el token del dispositivo. Un token es único por dispositivo. */
  upsert(data: UpsertDeviceTokenData): Promise<void>;

  /** Elimina el token al hacer logout — el usuario deja de recibir push. */
  deleteByToken(token: string): Promise<void>;

  /** Devuelve solo los tokens FCM de un distrito (para Redis fallback). */
  findByDistrict(district: string): Promise<string[]>;

  /** Devuelve tokens + userId para poder persistir notificaciones por usuario. */
  findByDistrictWithUserId(district: string): Promise<DeviceTokenEntry[]>;
}
