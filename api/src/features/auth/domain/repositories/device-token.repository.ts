export interface UpsertDeviceTokenData {
  userId: string;
  token: string;
  district: string;
}

export interface DeviceTokenRepository {
  /** Inserta o actualiza el token del dispositivo. Un token es único por dispositivo. */
  upsert(data: UpsertDeviceTokenData): Promise<void>;

  /** Elimina el token al hacer logout — el usuario deja de recibir push. */
  deleteByToken(token: string): Promise<void>;

  /** Devuelve todos los tokens FCM de un distrito para envío masivo. */
  findByDistrict(district: string): Promise<string[]>;
}
