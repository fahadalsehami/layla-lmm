# backend/core/logging.py
import logging
from pathlib import Path
import boto3
from botocore.exceptions import ClientError
import json
from datetime import datetime

class S3Handler(logging.Handler):
    """Custom logging handler for S3"""
    
    def __init__(self, bucket: str, prefix: str):
        super().__init__()
        self.bucket = bucket
        self.prefix = prefix
        self.s3_client = boto3.client(
            's3',
            region_name=settings.aws.REGION,
            aws_access_key_id=settings.aws.ACCESS_KEY_ID,
            aws_secret_access_key=settings.aws.SECRET_ACCESS_KEY
        )
    
    def emit(self, record):
        try:
            log_entry = {
                'timestamp': datetime.utcnow().isoformat(),
                'level': record.levelname,
                'message': record.getMessage(),
                'module': record.module,
                'function': record.funcName,
                'line': record.lineno
            }
            
            # Create S3 key with timestamp
            key = f"{self.prefix}/{datetime.utcnow().strftime('%Y/%m/%d/%H')}/{record.levelname}.log"
            
            # Upload to S3
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=json.dumps(log_entry)
            )
        except Exception as e:
            print(f"Failed to write log to S3: {str(e)}")

def setup_logging():
    """Configure logging"""
    logger = logging.getLogger('layla-app')
    logger.setLevel(logging.INFO)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    # S3 handler
    s3_handler = S3Handler(
        bucket=settings.aws.storage.LOGS_BUCKET,
        prefix='application_logs'
    )
    s3_handler.setLevel(logging.INFO)
    logger.addHandler(s3_handler)
    
    return logger

logger = setup_logging()