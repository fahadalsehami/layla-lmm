# backend/core/config.py
from pydantic_settings import BaseSettings
from typing import List, Optional
from pathlib import Path

class NetworkSettings(BaseSettings):
    """Network Infrastructure Settings"""
    VPC_ID: str
    PUBLIC_SUBNET_1A: str
    PUBLIC_SUBNET_1B: str
    PRIVATE_SUBNET_1A: str
    PRIVATE_SUBNET_1B: str
    VPC_CIDR: str = "10.0.0.0/16"
    
    class Config:
        env_file = ".env"

class DatabaseSettings(BaseSettings):
    """RDS Database Settings"""
    DB_INSTANCE_IDENTIFIER: str = "layla-app-db"
    DB_SUBNET_GROUP: str = "layla-app-db-subnet-group"
    DB_SECURITY_GROUP: str = "layla-app-db-sg"
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str = "layla_db"
    POSTGRES_PORT: int = 5432
    POSTGRES_HOST: Optional[str] = None  # Set dynamically from RDS
    
    class Config:
        env_file = ".env"

class StorageSettings(BaseSettings):
    """S3 Storage Settings"""
    DATA_BUCKET: str = "layla-app-data"
    MODELS_BUCKET: str = "layla-app-models"
    LOGS_BUCKET: str = "layla-app-logs"
    
    class Config:
        env_file = ".env"

class MLSettings(BaseSettings):
    """SageMaker Settings"""
    NOTEBOOK_INSTANCE: str = "layla-app-notebook"
    SECURITY_GROUP: str = "layla-app-sagemaker-sg"
    IAM_ROLE_ARN: str
    INSTANCE_TYPE: str = "ml.t3.medium"
    
    class Config:
        env_file = ".env"

class AWSSettings(BaseSettings):
    """AWS Global Settings"""
    REGION: str = "us-east-1"
    ACCESS_KEY_ID: str
    SECRET_ACCESS_KEY: str
    
    network: NetworkSettings = NetworkSettings()
    database: DatabaseSettings = DatabaseSettings()
    storage: StorageSettings = StorageSettings()
    ml: MLSettings = MLSettings()
    
    class Config:
        env_file = ".env"

class Settings(BaseSettings):
    """Global Application Settings"""
    PROJECT_NAME: str = "Layla App"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENV: str = "development"
    
    # AWS Configuration
    aws: AWSSettings = AWSSettings()
    
    # API Settings
    API_V1_STR: str = "/api/v1"
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8501"
    ]
    
    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"

settings = Settings()
