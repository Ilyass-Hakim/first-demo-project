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
        DOCKER_HUB_PASSWORD = credentials('dockerhub-token')
        IMAGE_NAME = "${DOCKER_HUB_USERNAME}/webapp-project"
        
        K8S_NAMESPACE = 'default'
        K8S_DEPLOYMENT_NAME = 'webapp-project'
        
        ANSIBLE_SERVER = '192.168.1.33'
        ANSIBLE_USER = 'ansible'
        ANSIBLE_PRIVATE_KEY = 'ansible-ssh-key-id'
        
        KUBECONFIG_CREDENTIAL = 'working-kubeconfig'
        
        REPO_URL = 'https://github.com/Ilyass-Hakim/first-demo-project.git'
        ANSIBLE_BASE_DIR = '/home/ansible/ansible/'
        INVENTORY_FILE = "${ANSIBLE_BASE_DIR}/inventories/hosts.yml"
        PLAYBOOK_FILE = "${ANSIBLE_BASE_DIR}/first-demo-project/kubernetes-deployment.yml"
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
                    dockerImage.tag("latest")
                }
            }
        }
        
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_HUB_CREDENTIALS) {
                        dockerImage.push("${BUILD_NUMBER}")
                        dockerImage.push('latest')
                    }
                }
            }
        }
        
        }


        
        stage('Deploy to Kubernetes via Ansible') {
            steps {
                echo 'Deploying to Kubernetes via Ansible on remote server...'
                withCredentials([
                    sshUserPrivateKey(credentialsId: "${ANSIBLE_PRIVATE_KEY}", keyFileVariable: 'SSH_KEY'),
                    file(credentialsId: "${KUBECONFIG_CREDENTIAL}", variable: 'KUBECONFIG_FILE')
                ]) {
                    script {
                        // Prepare SSH key and kubeconfig locally for copying
                        sh '''
                            cp ${SSH_KEY} /tmp/ansible_key
                            chmod 600 /tmp/ansible_key

                            mkdir -p /tmp/kube
                            cp ${KUBECONFIG_FILE} /tmp/kube/config
                            chmod 600 /tmp/kube/config
                        '''

                        // Clone or pull repo on Ansible server
                        sh """
                            ssh -i /tmp/ansible_key -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} '
                              if [ -d "${ANSIBLE_BASE_DIR}/.git" ]; then
                                cd ${ANSIBLE_BASE_DIR} && git pull;
                              else
                                git clone ${REPO_URL} ${ANSIBLE_BASE_DIR};
                              fi
                              mkdir -p /tmp/kube
                            '
                        """

                        // Copy kubeconfig to Ansible server
                        sh """
                            scp -i /tmp/ansible_key -o StrictHostKeyChecking=no /tmp/kube/config ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/kube/config
                        """

                        // Run ansible-playbook on Ansible server
                        sh """
                            ssh -i /tmp/ansible_key -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} '
                              ansible-playbook -i ${INVENTORY_FILE} \\
                                -e docker_image=${IMAGE_NAME}:${BUILD_NUMBER} \\
                                -e k8s_namespace=${K8S_NAMESPACE} \\
                                -e deployment_name=${K8S_DEPLOYMENT_NAME} \\
                                -e dockerhub_username=${DOCKER_HUB_USERNAME} \\
                                -e build_number=${BUILD_NUMBER} \\
                                ${PLAYBOOK_FILE}
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh '''
                rm -f /tmp/ansible_key
                rm -rf /tmp/kube
            '''
            archiveArtifacts artifacts: 'target/*.war', allowEmptyArchive: true
            junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
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
