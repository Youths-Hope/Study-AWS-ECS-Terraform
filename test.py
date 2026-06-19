import boto3
import json

secrets = boto3.client("secretsmanager", region_name="ap-northeast-1")

for secret_id in ["study/db/user", "study/db/password"]:
    response = secrets.get_secret_value(SecretId=secret_id)

    value = response.get("SecretString", "")

    print(f"SECRET_NAME: {secret_id}")

    # パスワードをそのまま出さない
    print(f"SECRET_LENGTH: {len(value)}")