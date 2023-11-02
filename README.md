# Webapp-sample

The project is to introduce a cross-account solution CI/CD pipeline with AWS services

## Prerequisites
- You need have at least two [AWS Accounts](https://aws.amazon.com/): AccountA and AccountB
- You need have working environment which should include tools, such as aws cli, git, unzip etc. In the working environment, you should setup CodeCommit to AccountA already and should be able to access both accounts by aws cli. For CodeCommit setup, please refer to [CodeCommit document](https://docs.aws.amazon.com/zh_cn/codecommit/latest/userguide/setting-up-ide.html).  

## Deployment Steps

1. download this repository and push to CodeCommit in AccountA; set REGION variable before run below commands;
```bash
wget https://github.com/qyzhangaws/webapp-sample/archive/refs/heads/main.zip  
unzip main.zip  
mv webapp-sample-main webapp-sample 

aws --region $REGION codecommit create-repository --repository-name webapp-sample 

cd webapp-sample
git init
git add . && git commit -m "initial commit"
git remote add webapp-sample https://git-codecommit.$REGION.amazonaws.com/v1/repos/webapp-sample
git push --set-upstream webapp-sample master
```

2. Create CodeBuild project and setup ECR by cloudformation in AccountA; set $DESTINATION_ACCOUNT and REGION variables before run below command
```bash
 cd deployment/AccountA
 aws --region us-west-1 cloudformation create-stack --stack-name webapp-sample-codebuild --template-body file://main.template.yaml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=ECRReplicationDestinationAWSAccount,ParameterValue=$DESTINATION_ACCOUNT ParameterKey=ECRReplicationDestinationRegion,ParameterValue=$REGION

```

3. Setup ECR in AccountB; set SOURCE_ACCOUNT variable before run below command
```bash
cd deployment/AccountB
aws --region ap-northeast-2 cloudformation create-stack --stack-name ecr-setting --template-body file://ecr.yaml --parameters ParameterKey=ECRReplicationSourceAWSAccount,ParameterValue=$SOURCE_ACCOUNT

```

4. Setup VPC in AccountB; feel free to provide parameters according to the parameters in template
```bash
cd deployment/AccountB
aws --region ap-northeast-1 cloudformation create-stack --stack-name vpc --template-body file://vpc.yaml
```
5. Setup S3 bucket with version enabled for CodePipeline source provider and put source files; set REGION and BUCKET_NAMe variables before run below commands
```bash
aws --region $REGION s3api create-bucket --bucket $BUCKET_NAME 
aws --region $REGION s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
wget https://github.com/qyzhangaws/webapp-sample/archive/refs/heads/main.zip  
unzip main.zip  
mv webapp-sample-main webapp-sample 
cd webapp-sample/deployment/AccountB/PipelineSource/
zip webapp-sample-deployment.zip ./*
aws --region $REGION s3 cp webapp-sample-deployment.zip s3://$BUCKET_NAME/

```

6. Setup CodePipeline in AccountB; feel free to provide more parameters
```bash
cd deployment/AccountB
aws --region ap-northeast-2 cloudformation create-stack --stack-name webapp-sample-pipeline --template-body file://pipeline.yaml --parameters ParameterKey=CodePipelineSourceArtifactsBucketName,ParameterValue=codepipline-source-ap-northeast-2-451902973616 --capabilities CAPABILITY_NAMED_IAM
```


## After Deployment

Once you done a code push to master branch on CodeCommint repository webapp-sample in AccountA, the image build will be triggered and it will push image to ECR in AccountA, then sync to ECR on AccountB. The pipeline in AccountB will be automatically triggered by new ECT image with latest tag, then the pipeline will run CloudFormation in pipeline stage to deploy new version application to ECR on Fargate.