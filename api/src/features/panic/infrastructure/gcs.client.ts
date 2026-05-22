/**
 * @deprecated Reemplazado por cloudinary.client.ts para el MVP.
 * Conservar para cuando se configure GCS/Firebase Storage con plan pago.
 *
 * Para re-activar:
 * 1. Habilitar Firebase Storage o crear bucket en GCS
 * 2. Setear GCS_BUCKET_NAME y GCP_PROJECT_ID en .env
 * 3. Cambiar panic.controller.ts para usar generateSignedUrls de este archivo
 */
export {};
