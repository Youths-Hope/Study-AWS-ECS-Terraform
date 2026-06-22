import boto3
import json

s3 = boto3.client("s3")

s3.download_file(
    "youth-study-bucket-001",
    "test/test.txt",
    "/tmp/download.txt"
)

with open("/tmp/download.txt") as f:
    print(f.read())

print("DOWNLOAD OK: test/test.txt")