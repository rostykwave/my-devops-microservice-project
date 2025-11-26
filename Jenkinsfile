pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command:
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: aws-secret
          mountPath: /root/.aws/
        - name: docker-config
          mountPath: /kaniko/.docker/
    - name: git
      image: alpine/git
      command:
        - sleep
      args:
        - 99d
  volumes:
    - name: aws-secret
      secret:
        secretName: aws-credentials
    - name: docker-config
      configMap:
        name: docker-config
"""
    }
  }

  environment {
    AWS_DEFAULT_REGION = 'eu-central-1'
    ECR_REGISTRY = "878905833569.dkr.ecr.eu-central-1.amazonaws.com"
    IMAGE_NAME   = "lesson-5-ecr"
    IMAGE_TAG    = "v1.0.${BUILD_NUMBER}"

    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME  = "jenkins"
    HELM_REPO_URL = "https://github.com/rostykwave/my-devops-microservice-project.git"
  }

  stages {
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \\
              --context `pwd`/django \\
              --dockerfile `pwd`/django/Dockerfile \\
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
          '''
        }
      }
    }

    stage('Update Chart Tag in Git') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
            sh '''
              git clone -b lesson-8-9 $HELM_REPO_URL helm-repo
              cd helm-repo/charts/django-app

              sed -i "s/tag: .*/tag: $IMAGE_TAG/" values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"

              git add values.yaml
              git commit -m "Update image tag to $IMAGE_TAG"
              git push origin lesson-8-9
            '''
          }
        }
      }
    }
  }
}
