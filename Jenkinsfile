pipeline {
    agent any

    tools {
        maven '3.9.10'
    }

    triggers {
        githubPush()
        pollSCM('H/10 * * * *')
    }

    environment {
        DOCKER_HUB_CREDENTIALS = 'dockerhub-token'  
        DOCKER_HUB_USERNAME = 'ilyass10devops'                 
        IMAGE_NAME = "${DOCKER_HUB_USERNAME}/webapp-project"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building with Maven...'
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('sq1') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Package & Deploy to Artifactory') {
            steps {
                echo 'Packaging WAR and deploying to Artifactory...'
                sh 'mvn clean deploy'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:latest")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_HUB_CREDENTIALS) {
                        dockerImage.push('latest')
                    }
                }
            }
        }

        // Remove or comment out the old Deploy to Tomcat stage:
        // stage('Deploy to Tomcat') { ... }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes (use Ansible here)...'
                // You can run ansible-playbook commands here or trigger deployment pipeline
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image pushed: ${IMAGE_NAME}:latest"
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
    }
}
