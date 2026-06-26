import os
import time
import boto3
from urllib.parse import urlparse

# イメージアップロード
def upload_image(image):
    aws_region = os.environ.get("AWS_REGION", "ap-northeast-1")
    bucket     = os.environ.get("S3_BUCKET_NAME")

    s3 = boto3.client("s3", region_name=aws_region)

    key = f"images/{int(time.time() * 1000)}-{image.filename}"

    s3.upload_fileobj(
        image,
        bucket,
        key,
        ExtraArgs={
            "ContentType": image.content_type
        }
    )

    image_url = f"https://{bucket}.s3.{aws_region}.amazonaws.com/{key}"

    print(f"UPLOAD file={image.filename} url={image_url}")

    return image_url

# イメージ削除
def delete_image(image_url):
    key        = urlparse(image_url).path.lstrip("/")
    aws_region = os.environ.get("AWS_REGION", "ap-northeast-1")
    bucket     = os.environ.get("S3_BUCKET_NAME")

    s3 = boto3.client("s3", region_name=aws_region)

    s3.delete_object(
        Bucket=bucket,
        Key=key
    )

    print(f"DELETE key={key}")
