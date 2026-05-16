const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/reverse';
const TIMEOUT_MS = 1500;

interface NominatimResponse {
  address?: {
    road?: string;
    house_number?: string;
    suburb?: string;
    city_district?: string;
  };
}

export async function reverseGeocode(lat: number, lng: number): Promise<string | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const url = `${NOMINATIM_URL}?lat=${lat}&lon=${lng}&format=json&addressdetails=1&accept-language=es`;
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'AlertaYa/1.0 (nakea.studio@gmail.com)',
      },
    });

    if (!response.ok) return null;

    const data = (await response.json()) as NominatimResponse;
    const addr = data.address;
    if (!addr) return null;

    // Armar dirección legible: "Av. Larco 800" o solo "Av. Larco" si no hay número
    const parts: string[] = [];
    if (addr.road) {
      parts.push(addr.house_number ? `${addr.road} ${addr.house_number}` : addr.road);
    }

    return parts.length > 0 ? parts.join(', ') : null;
  } catch {
    // Timeout, red caída, respuesta inválida → fail open
    return null;
  } finally {
    clearTimeout(timer);
  }
}
