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
        // Docker Hub Configuration (keeping your existing setup)
        DOCKER_HUB_CREDENTIALS = 'dockerhub-token'  
        DOCKER_HUB_USERNAME = 'ilyass10devops'                 
        IMAGE_NAME = "${DOCKER_HUB_USERNAME}/webapp-project"
        
        // Kubernetes Configuration
        K8S_NAMESPACE = 'default'
        K8S_DEPLOYMENT_NAME = 'webapp-project'
        
        // Ansible Configuration
        ANSIBLE_SERVER = 'your-ansible-server-ip'  // Update with your Ansible server IP
        ANSIBLE_USER = 'your-ansible-user'         // Update with your Ansible user
        ANSIBLE_PRIVATE_KEY = 'ansible-ssh-key-id' // Jenkins credential ID for Ansible SSH key
        KUBECONFIG_CREDENTIAL = 'kubeconfig-file'  // Jenkins credential ID for kubeconfig file
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
                    dockerImage = docker.build("${IMAGE_NAME}:${BUILD_NUMBER}")
                    // Also tag as latest
                    dockerImage.tag("latest")
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_HUB_CREDENTIALS) {
                        dockerImage.push("${BUILD_NUMBER}")
                        dockerImage.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes via Ansible') {
            steps {
                echo 'Deploying to Kubernetes using Ansible...'
                script {
                    // Create temporary inventory file for Ansible
                    writeFile file: 'ansible-inventory.ini', text: """
[k8s_nodes]
${ANSIBLE_SERVER} ansible_user=${ANSIBLE_USER} ansible_ssh_private_key_file=/tmp/ansible_key

[k8s_nodes:vars]
ansible_python_interpreter=/usr/bin/python3
"""
                    
                    // Copy SSH key and kubeconfig for Ansible
                    withCredentials([
                        sshUserPrivateKey(credentialsId: "${ANSIBLE_PRIVATE_KEY}", keyFileVariable: 'SSH_KEY'),
                        file(credentialsId: "${KUBECONFIG_CREDENTIAL}", variable: 'KUBECONFIG_FILE')
                    ]) {
                        sh '''
                            # Copy SSH key
                            cp ${SSH_KEY} /tmp/ansible_key
                            chmod 600 /tmp/ansible_key
                            
                            # Copy kubeconfig
                            mkdir -p /tmp/kube
                            cp ${KUBECONFIG_FILE} /tmp/kube/config
                            chmod 600 /tmp/kube/config
                        '''
                        
                        // Run Ansible playbook
                        sh """
                            ansible-playbook -i ansible-inventory.ini \
                            -e docker_image=${IMAGE_NAME}:${BUILD_NUMBER} \
                            -e k8s_namespace=${K8S_NAMESPACE} \
                            -e deployment_name=${K8S_DEPLOYMENT_NAME} \
                            -e dockerhub_username=${DOCKER_HUB_USERNAME} \
                            -e build_number=${BUILD_NUMBER} \
                            kubernetes-deployment.yml
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up temporary files
            sh '''
                rm -f /tmp/ansible_key
                rm -f ansible-inventory.ini
                rm -rf /tmp/kube
            '''
            
            // Archive artifacts
            archiveArtifacts artifacts: 'target/*.war', allowEmptyArchive: true
            
            // Publish test results if available
            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
        }
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image pushed: ${IMAGE_NAME}:${BUILD_NUMBER}"
            echo "Application deployed to Kubernetes namespace: ${K8S_NAMESPACE}"
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
    }
}
