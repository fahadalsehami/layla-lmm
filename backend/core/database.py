# backend/core/database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base
from typing import Generator
import boto3
from botocore.exceptions import ClientError

from .config import settings
from .logging import logger

def get_rds_endpoint() -> str:
    """Get RDS endpoint dynamically"""
    try:
        rds = boto3.client(
            'rds',
            region_name=settings.aws.REGION,
            aws_access_key_id=settings.aws.ACCESS_KEY_ID,
            aws_secret_access_key=settings.aws.SECRET_ACCESS_KEY
        )
        
        response = rds.describe_db_instances(
            DBInstanceIdentifier=settings.aws.database.DB_INSTANCE_IDENTIFIER
        )
        return response['DBInstances'][0]['Endpoint']['Address']
    except ClientError as e:
        logger.error(f"Failed to get RDS endpoint: {str(e)}")
        raise

# Set database host
settings.aws.database.POSTGRES_HOST = get_rds_endpoint()

# Database URL
SQLALCHEMY_DATABASE_URL = (
    f"postgresql://"
    f"{settings.aws.database.POSTGRES_USER}:"
    f"{settings.aws.database.POSTGRES_PASSWORD}@"
    f"{settings.aws.database.POSTGRES_HOST}:"
    f"{settings.aws.database.POSTGRES_PORT}/"
    f"{settings.aws.database.POSTGRES_DB}"
)

# Create engine
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=300
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db() -> Generator[Session, None, None]:
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()