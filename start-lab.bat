@echo off
setlocal

set AWS_REGION=ap-northeast-1
set DB_IDENTIFIER=study-db-ecs
set ECS_CLUSTER=study-cluster
set ECS_SERVICE=study-node-task-service-r7cd8nq1
set TERRAFORM_DIR=.\terraform

echo ========================================
echo Start AWS Study Lab
echo ========================================

echo.
echo [1/5] Start RDS...
aws rds start-db-instance --db-instance-identifier %DB_IDENTIFIER% --region %AWS_REGION% --no-cli-pager

echo.
echo [2/5] Wait for RDS available...
aws rds wait db-instance-available --db-instance-identifier %DB_IDENTIFIER% --region %AWS_REGION% --no-cli-pager

echo.
echo [3/5] Terraform apply...
cd /d %TERRAFORM_DIR%
terraform apply -auto-approve

echo.
echo [4/5] Start ECS Service...
aws ecs update-service --cluster %ECS_CLUSTER% --service %ECS_SERVICE% --desired-count 1 --region %AWS_REGION% --no-cli-pager

echo.
echo [5/5] Check ECS Service...
aws ecs describe-services --cluster %ECS_CLUSTER% --services %ECS_SERVICE% --region %AWS_REGION% --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,status:status}" --no-cli-pager

echo.
echo ========================================
echo Start completed.
echo Check ALB URL, /users, /add
echo ========================================

pause
endlocal