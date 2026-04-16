pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    EKS_CLUSTER_NAME = 'surgtech-eks-dev'
    FRONTEND_REPOSITORY_URI = '113938649043.dkr.ecr.ap-south-1.amazonaws.com/surgtech-eks-dev-frontend'
    BACKEND_REPOSITORY_URI = '113938649043.dkr.ecr.ap-south-1.amazonaws.com/surgtech-eks-dev-backend'
  }

  triggers {
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare') {
      steps {
        sh '''
          set -eux
          aws --version
          kubectl version --client
          aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"
          aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$(echo "$FRONTEND_REPOSITORY_URI" | cut -d/ -f1)"
        '''
      }
    }

    stage('Build Images') {
      steps {
        sh '''
          set -eux
          IMAGE_TAG="$(git rev-parse --short HEAD)"
          echo "$IMAGE_TAG" > .image-tag
          docker build -t "$FRONTEND_REPOSITORY_URI:$IMAGE_TAG" ./frontend
          docker build -t "$BACKEND_REPOSITORY_URI:$IMAGE_TAG" ./backend
        '''
      }
    }

    stage('Push Images') {
      steps {
        sh '''
          set -eux
          IMAGE_TAG="$(cat .image-tag)"
          docker push "$FRONTEND_REPOSITORY_URI:$IMAGE_TAG"
          docker push "$BACKEND_REPOSITORY_URI:$IMAGE_TAG"
        '''
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh '''
          set -eux
          IMAGE_TAG="$(cat .image-tag)"
          export FRONTEND_IMAGE="$FRONTEND_REPOSITORY_URI:$IMAGE_TAG"
          export BACKEND_IMAGE="$BACKEND_REPOSITORY_URI:$IMAGE_TAG"
          chmod +x cicd/render-and-deploy.sh
          ./cicd/render-and-deploy.sh
        '''
      }
    }
  }
}
