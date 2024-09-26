# ECR Repo for Docker images
resource "aws_ecr_repository" "fraud_detection_repo"{
  name = "fraud-detection-app"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Use AWS Secrets Manager to store GitHub token

resource "aws_secretsmanager_secret" "github_token" {
  name = "github-token2"
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = "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943"
}


# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Effect = "Allow",
      },
    ]
  })
}

# IAM Policy for CodeBuild to access ECR and Fargate
resource "aws_iam_role_policy_attachment" "codebuild_policy" {
    role = aws_iam_role.codebuild_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}


# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Effect = "Allow",
      },
    ]
  })
}

# IAM Policy to allow CodePipeline to manage Pipeline Resources
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# CodeBuild Project to Build Docker Image
resource "aws_codebuild_project" "docker_build" {
    name = "fraud-detection-docker-build"
    service_role = aws_iam_role.codebuild_role.arn
    
    source {
        type            = "GITHUB"
        location        = "https://github.com/talhazaman2001/fraud-detection-project.git"
        git_clone_depth = 1
        buildspec       = file("buildspec.yml")
        }
    
    artifacts {
        type = "NO_ARTIFACTS"
    }
    environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
        name  = "GITHUB_TOKEN"
        value = aws_secretsmanager_secret_version.github_token.secret_string
        }
    }
}

# Create CodeStar Connection

resource "aws_codestarconnections_connection" "github_connection" {
    name = "my-github-connection"
    provider_type = "GitHub"
}

# S3 Bucket to store CodePipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "fraud-detection-pipeline-artifacts-talha"
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts_block" {
    bucket = aws_s3_bucket.pipeline_artifacts.id

    block_public_acls = true
    block_public_policy = false
    restrict_public_buckets = true
    ignore_public_acls = true
}


# CodePipeline to orchestrate CI/CD process

resource "aws_codepipeline" "fraud_detection_pipeline" {
  name = "FraudDetectionPipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = "arn:aws:codestar-connections:eu-west-2:463470963000:connection/43c0e9a0-f3d6-4d89-9645-5044376ab9f4"
        FullRepositoryId = "talhazaman2001/fraud-detection-project"
        BranchName    = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "DockerBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "${aws_codebuild_project.docker_build.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "DeployToFargate"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName     = "${aws_ecs_cluster.ecs_cluster.name}"
        ServiceName = "${aws_ecs_service.ecs_service.name}"
        FileName = "imagedefinitions.json"
      }

    }
  }
}



