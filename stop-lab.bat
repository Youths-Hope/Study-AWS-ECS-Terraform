@echo off
setlocal

set AWS_REGION=ap-northeast-1
set DB_IDENTIFIER=study-db-ecs
set ECS_CLUSTER=study-cluster
set ECS_SERVICE=study-node-task-service-r7cd8nq1

set TERRAFORM_DIR=.\terraform

echo ========================================
echo Stop AWS Study Lab
echo ========================================

echo.
echo [1/4] Stop ECS Service...
aws ecs update-service --cluster %ECS_CLUSTER% --service %ECS_SERVICE% --desired-count 0 --region %AWS_REGION% --no-cli-pager

echo.
echo [2/4] Check ECS Service...
aws ecs describe-services --cluster %ECS_CLUSTER% --services %ECS_SERVICE% --region %AWS_REGION% --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount,status:status}" --no-cli-pager

echo.
echo [3/4] Stop RDS...
aws rds stop-db-instance --db-instance-identifier %DB_IDENTIFIER% --region %AWS_REGION% --no-cli-pager

echo.
echo [4/4] ALB / Target Group deletion
echo Delete ALB and Target Group manually, or use Terraform target destroy if needed.
echo.
cd /d %TERRAFORM_DIR%
terraform destroy   -target=aws_lb_listener.http   -target=aws_lb.study_alb   -target=aws_lb_target_group.study_alb_tg   -auto-approve

echo ========================================
echo Stop completed.
echo ========================================

pause
endlocal