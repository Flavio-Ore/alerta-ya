from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Entorno
    ENVIRONMENT: str = "development"
    PORT: int = 8000

    # Base de datos
    DATABASE_URL: str = "postgresql://alertaya:alertaya@localhost:5432/alertaya_dev"

    # API Backend (para CORS)
    API_URL: str = "http://localhost:3000"

    # Modelos — rutas a archivos .joblib
    VERIFIER_MODEL_PATH: str = "src/models/verifier_v3.joblib"
    PREDICTOR_MODEL_PATH: str = "src/models/predictor_v1.joblib"

    # Geofencing Lima Metropolitana
    LIMA_LAT_MIN: float = -12.28
    LIMA_LAT_MAX: float = -11.77
    LIMA_LNG_MIN: float = -77.17
    LIMA_LNG_MAX: float = -76.78


settings = Settings()
