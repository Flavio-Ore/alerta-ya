"""
Extractor de incidentes de DataCrim (INEI) para Lima Metropolitana.

Fuente: ArcGIS REST MapServer de INEI/DataCrim (puntos de delitos georreferenciados).
  http://arcgis3.inei.gob.pe:6080/arcgis/rest/services/Datacrim/DATACRIM002_AGS_PUNTOSDELITOS/MapServer

Qué hace:
  1. Enumera las CAPAS HOJA (cada una = un tipo de delito en un período).
  2. Por cada hoja, pide los OBJECTID que caen dentro del bounding box de Lima.
  3. Baja los registros en LOTES (el server limita a 1000 por query y NO soporta
     paginación con offset → estrategia: pedir IDs y luego query por OBJECTID IN (...)).
  4. Normaliza todo a un esquema plano y lo guarda como CSV.

LIMITACIÓN CONOCIDA DEL DATO (verificada): el campo temporal es `periodo` = AÑO.
  NO hay fecha, NO hay día de semana, NO hay hora. Por eso este CSV sirve para el
  modelo ESPACIAL (Fase 2a), no para el modelo hora-por-hora.

Uso:
  uv run python scripts/extract_datacrim.py                 # todas las hojas
  uv run python scripts/extract_datacrim.py --layers 6 21   # solo esas hojas (prueba)
  uv run python scripts/extract_datacrim.py --max-per-layer 200  # tope por hoja (prueba)
"""
from __future__ import annotations

import argparse
import csv
import sys
import time
from pathlib import Path

import httpx

# --- Endpoint y configuración ---------------------------------------------------
BASE = ("http://arcgis3.inei.gob.pe:6080/arcgis/rest/services/"
        "Datacrim/DATACRIM002_AGS_PUNTOSDELITOS/MapServer")

# Bounding box de Lima Metropolitana + Callao (coincide con ml/src/core/config.py)
LIMA_BBOX = {"xmin": -77.20, "ymin": -12.30, "xmax": -76.75, "ymax": -11.70}

# Tamaño de lote para bajar por OBJECTID (server tope = 1000; usamos 500 por margen)
BATCH = 500


def normalize(attrs: dict, layer_id: int) -> dict:
    """Normaliza atributos a un esquema plano, tolerante a variantes entre capas.

    GOTCHA REAL: las 290 capas NO comparten esquema. Varían en mayúsculas
    (generico vs GENERICO), en nombres (periodo vs AÑO, ubigeo_hecho vs UBIGEO_HEC)
    y algunas capas no traen nombre de distrito. Por eso bajamos outFields=* y acá
    buscamos cada campo por varios alias, sin importar mayúsculas.
    """
    low = {k.lower(): v for k, v in attrs.items()}

    def pick(*names):
        for n in names:
            v = low.get(n)
            if v not in (None, "", " "):
                return v
        return None

    return {
        "incident_generic": pick("generico"),
        "incident_specific": pick("especifico"),
        "district": pick("nombdist", "nomb_dist"),
        "ubigeo": pick("ubigeo_hecho", "ubigeo_hec", "ubigeo"),
        "lat": pick("y"),   # OJO: en DataCrim Y=lat, X=lng
        "lng": pick("x"),
        "year": pick("periodo", "año", "ano", "anio"),
        "source_layer": layer_id,
    }


def get_json(client: httpx.Client, url: str, params: dict) -> dict:
    """GET con f=json + reintentos simples (el server de INEI a veces tarda)."""
    params = {**params, "f": "json"}
    for intento in range(3):
        try:
            r = client.get(url, params=params, timeout=40)
            r.raise_for_status()
            return r.json()
        except Exception as e:  # noqa: BLE001 — reintento amplio a propósito
            if intento == 2:
                raise
            time.sleep(2 * (intento + 1))
    return {}


def list_leaf_layers(client: httpx.Client) -> list[dict]:
    """Devuelve solo las capas HOJA (las que tienen puntos; los grupos se descartan)."""
    root = get_json(client, BASE, {})
    layers = root.get("layers", [])
    # Una capa es 'grupo' si tiene subLayerIds; las hojas no.
    leaves = [l for l in layers if not l.get("subLayerIds")]
    return leaves


def layer_ids_in_bbox(client: httpx.Client, layer_id: int) -> tuple[str, list[int]]:
    """Pide los OBJECTID de la capa dentro del bbox de Lima.

    OJO: filtramos por los CAMPOS x/y (atributos numéricos), NO por geometría.
    La geometría (Shape) está en un SR distinto a 4326 y un envelope espacial
    devuelve 0 resultados. El bbox sobre x/y sí funciona y es independiente del SR.
    """
    where = (f"x>={LIMA_BBOX['xmin']} AND x<={LIMA_BBOX['xmax']} "
             f"AND y>={LIMA_BBOX['ymin']} AND y<={LIMA_BBOX['ymax']}")
    data = get_json(client, f"{BASE}/{layer_id}/query",
                    {"where": where, "returnIdsOnly": "true"})
    oid_field = data.get("objectIdFieldName", "OBJECTID")
    return oid_field, data.get("objectIds") or []


def fetch_batch(client: httpx.Client, layer_id: int, oid_field: str, ids: list[int]) -> list[dict]:
    """Baja un lote por OBJECTID IN (...). outFields=* porque el esquema varía por capa."""
    params = {
        "where": f"{oid_field} IN ({','.join(map(str, ids))})",
        "outFields": "*",          # esquema inconsistente entre capas → traemos todo y normalizamos
        "returnGeometry": "false",  # x,y ya vienen como campos
        "f": "json",
    }
    # POST: el where con muchos IDs excede el largo de una URL GET.
    r = client.post(f"{BASE}/{layer_id}/query", data=params, timeout=60)
    r.raise_for_status()
    feats = r.json().get("features", [])
    return [f.get("attributes", {}) for f in feats]


def main() -> int:
    ap = argparse.ArgumentParser(description="Extractor DataCrim → CSV (Lima)")
    ap.add_argument("--out", default="data/raw/datacrim_lima.csv", help="ruta del CSV de salida")
    ap.add_argument("--layers", nargs="*", type=int, help="IDs de capa específicos (default: todas las hojas)")
    ap.add_argument("--max-per-layer", type=int, default=0, help="tope de registros por capa (0 = sin tope)")
    args = ap.parse_args()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)

    with httpx.Client(headers={"User-Agent": "alertaya-ml/1.0"}) as client:
        if args.layers:
            leaves = [{"id": i, "name": f"layer-{i}"} for i in args.layers]
        else:
            leaves = list_leaf_layers(client)
        print(f"Capas hoja a procesar: {len(leaves)}", file=sys.stderr)

        total = 0
        with out.open("w", newline="", encoding="utf-8") as fh:
            writer = None
            for leaf in leaves:
                lid = leaf["id"]
                try:
                    oid_field, ids = layer_ids_in_bbox(client, lid)
                except Exception as e:  # noqa: BLE001
                    print(f"  capa {lid}: ERROR pidiendo IDs ({e}) — skip", file=sys.stderr)
                    continue
                if not ids:
                    continue
                if args.max_per_layer:
                    ids = ids[: args.max_per_layer]

                got = 0
                for k in range(0, len(ids), BATCH):
                    chunk = ids[k : k + BATCH]
                    rows = fetch_batch(client, lid, oid_field, chunk)
                    for a in rows:
                        rec = normalize(a, lid)
                        if writer is None:
                            writer = csv.DictWriter(fh, fieldnames=list(rec.keys()))
                            writer.writeheader()
                        writer.writerow(rec)
                        got += 1
                total += got
                print(f"  capa {lid} ({leaf['name']}): {got} registros en Lima", file=sys.stderr)

        print(f"\nTOTAL: {total} registros → {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
