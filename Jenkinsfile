pipeline {
    agent any
    
    tools {
        maven '3.9.10'
    }
    
    triggers {
        // Trigger build on GitHub push events
        githubPush()
         pollSCM('H/1 * * * *')
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
        
        stage('Package & Deploy to Artifactory') {
            steps {
                echo 'Packaging WAR and deploying to Artifactory...'
                sh 'mvn clean deploy'
            }
        }
        
        stage('Deploy to Tomcat') {
            steps {
                echo 'Deploying WAR to Tomcat 11 server...'
                script {
                    deploy adapters: [
                        tomcat9(
                            credentialsId: 'tomcat-server',
                            path: '',
                            url: 'http://192.168.1.27:8084'
                        )
                    ], 
                    contextPath: '/webapp-project',
                    war: 'target/webapp-project-*.war'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application deployed at: http://192.168.1.27:8084/webapp-project'
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
    }
}
