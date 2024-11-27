# backend/services/aws_service.py

import boto3
import logging
from botocore.exceptions import ClientError
from backend.core.config import settings

logger = logging.getLogger(__name__)

class AWSService:
    """AWS Service Integration"""
    
    def __init__(self):
        self.s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.aws.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.aws.AWS_SECRET_ACCESS_KEY,
            region_name=settings.aws.AWS_REGION
        )
        
        self.sagemaker_client = boto3.client(
            'sagemaker',
            aws_access_key_id=settings.aws.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.aws.AWS_SECRET_ACCESS_KEY,
            region_name=settings.aws.AWS_REGION
        )
    
    async def upload_file(self, file_path: str, bucket: str, object_name: str):
        """Upload a file to S3"""
        try:
            self.s3_client.upload_file(file_path, bucket, object_name)
            logger.info(f"Successfully uploaded {file_path} to {bucket}/{object_name}")
            return True
        except ClientError as e:
            logger.error(f"Error uploading file to S3: {e}")
            return False
    
    async def download_file(self, bucket: str, object_name: str, file_path: str):
        """Download a file from S3"""
        try:
            self.s3_client.download_file(bucket, object_name, file_path)
            logger.info(f"Successfully downloaded {bucket}/{object_name} to {file_path}")
            return True
        except ClientError as e:
            logger.error(f"Error downloading file from S3: {e}")
            return False