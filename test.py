import boto3

ecs = boto3.client("ecs")

response = ecs.describe_services(
    cluster="study-cluster",
    services=[
        "study-node-task-service-r7cd8nq1"
    ]
)

service = response["services"][0]

print("ServiceName:", service["serviceName"])
print("Status:", service["status"])
print("RunningCount:", service["runningCount"])
print("DesiredCount:", service["desiredCount"])