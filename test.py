import boto3
import json

s3 = boto3.client("s3")

response = s3.list_objects_v2(
    Bucket="youth-study-bucket-001"
)

for obj in response.get("Contents", []):
    print("FILE:", obj["Key"])