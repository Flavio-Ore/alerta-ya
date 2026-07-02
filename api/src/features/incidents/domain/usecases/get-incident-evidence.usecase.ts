import { AppError } from '../../../../core/errors/AppError';
import { classifyMediaUrl, MediaKind } from '../../infrastructure/media-type';
import { ReportRepository } from '../repositories/report.repository';

/** Una evidencia resuelta a URL firmada, lista para render. NUNCA incluye identidad. */
export interface EvidenceItem {
  signedUrl: string;
  kind: Exclude<MediaKind, 'other'>; // solo 'image' | 'video'
}

/** Contexto del solicitante. `prismaUserId` es el id interno, nunca se expone en la respuesta. */
export interface EvidenceRequester {
  prismaUserId: string;
  isAuthority: boolean;
}

export interface GetIncidentEvidenceDeps {
  reportRepo: Pick<ReportRepository, 'findByIncidentId'>;
  resolveSignedUrl: (gsPath: string) => Promise<string | null>;
}

/**
 * Resuelve la evidencia (mediaUrls gs://) de un incidente a URLs firmadas.
 *
 * AUTHZ:
 *  - Autoridad/admin → toda la evidencia del incidente.
 *  - Ciudadano → solo la evidencia de SUS PROPIOS reportes en ese incidente.
 *    Si no tiene ningún reporte propio en el incidente → 403 (no se filtra la
 *    existencia del incidente ni la evidencia ajena).
 *
 * Fail-open: una media que no resuelve (gs:// inválido, sin permisos, expirada)
 * se OMITE; el resto se devuelve igual. Nunca lanza por una URL rota.
 * La respuesta NUNCA incluye userId/identidad del reportante.
 */
export async function getIncidentEvidence(
  incidentId: string,
  requester: EvidenceRequester,
  deps: GetIncidentEvidenceDeps,
): Promise<EvidenceItem[]> {
  const reports = await deps.reportRepo.findByIncidentId(incidentId);

  const allowed = requester.isAuthority
    ? reports
    : reports.filter((r) => r.userId === requester.prismaUserId);

  if (!requester.isAuthority && allowed.length === 0) {
    throw new AppError(403, 'No tienes acceso a la evidencia de este incidente');
  }

  const gsPaths = allowed.flatMap((r) => r.mediaUrls);

  const resolved = await Promise.all(
    gsPaths.map(async (gsPath): Promise<EvidenceItem | null> => {
      const kind = classifyMediaUrl(gsPath);
      if (kind === 'other') return null; // solo imágenes/videos
      const signedUrl = await deps.resolveSignedUrl(gsPath);
      if (!signedUrl) return null; // fail-open: media que no resuelve se omite
      return { signedUrl, kind };
    }),
  );

  return resolved.filter((item): item is EvidenceItem => item !== null);
}
