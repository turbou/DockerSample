aws ecr describe-repositories
aws ecr create-repository --repository-name sample/tomcat --image-scanning-configuration scanOnPush=true --region ap-northeast-1

docker tag sample/tomcat:8.5.54 [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com/sample/tomcat:8.5.54
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com
docker push [ACCOUNT_ID].dkr.ecr.ap-northeast-1.amazonaws.com/sample/tomcat:8.5.54

