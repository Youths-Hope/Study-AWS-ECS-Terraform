import boto3
import json

s3 = boto3.client("s3")

with open("/tmp/test.txt", "w") as f:
    f.write("Hello S3")

s3.upload_file(
    "/tmp/test.txt",
    "youth-study-bucket-001",
    "test/test.txt"
)

print("UPLOAD OK: test/test.txt")