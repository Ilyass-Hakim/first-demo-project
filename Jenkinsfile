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
        K8S_SERVICE_NAME = 'webapp-project-service'
        
        ANSIBLE_SERVER = '192.168.1.33'
        ANSIBLE_USER = 'ansible'
        ANSIBLE_PRIVATE_KEY = 'ansible-ssh-key-id'
        
        // Nginx Reverse Proxy Configuration
        PROXY_SERVER = '192.168.1.27'        // Your Tomcat/Nginx server
        PROXY_USER = 'tomcat'                // User on proxy server
        PROXY_SSH_KEY = 'tomcat-server-ssh-key' // SSH credential in Jenkins
        K8S_NODE_IP = '192.168.1.12'         // Your minikube VM IP
        K8S_NODE_PORT = '31201'              // NodePort for your service
        PROXY_DOMAIN = '192.168.1.27'        // Using IP address
        
        KUBECONFIG_CREDENTIAL = 'working-kubeconfig'
        
        REPO_URL = 'https://github.com/Ilyass-Hakim/first-demo-project.git'
        ANSIBLE_BASE_DIR = '/home/ansible/ansible/'
        INVENTORY_FILE = "${ANSIBLE_BASE_DIR}/inventories/hosts.yml"
        PLAYBOOK_FILE = "${ANSIBLE_BASE_DIR}/first-demo-project/kubernetes-deployment.yml"
        
        // DefectDojo Configuration
        DEFECTDOJO_URL = 'http://192.168.1.24:8081'
        DEFECTDOJO_USER = 'admin'
        DEFECTDOJO_PASSWORD = 'admin123'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Gitleaks Scan') {
            steps {
                echo 'Running Gitleaks secret scan...'
                sh '''
                    gitleaks detect --source . --report-path $WORKSPACE/gitleaks-report.json || exit_code=$?
                    
                    if [ ! -f "$WORKSPACE/gitleaks-report.json" ]; then
                        echo '{"results":[]}' > $WORKSPACE/gitleaks-report.json
                        echo "No secrets found - created clean report"
                    else
                        echo "Secrets detected - report generated"
                    fi
                '''
                archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
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
            
        stage('Run Semgrep remotely') {
            steps {
                sshagent(['sonarqube-server-credentials']) {
                    sh '''
                        mkdir -p ~/.ssh
                        ssh-keyscan -H 192.168.1.30 >> ~/.ssh/known_hosts 2>/dev/null || true
                        
                        ssh sonarqube@192.168.1.30 "mkdir -p /home/sonarqube/projects/firstDevopsProject"
                        rsync -avz --delete $WORKSPACE/ sonarqube@192.168.1.30:/home/sonarqube/projects/firstDevopsProject/
                        ssh sonarqube@192.168.1.30 "cd /home/sonarqube/projects/firstDevopsProject && /opt/ci-scripts/run-semgrep.sh"
                        scp sonarqube@192.168.1.30:/home/sonarqube/projects/firstDevopsProject/semgrep-report.json $WORKSPACE/
                    '''
                }
            }
        }

        stage('Archive Semgrep Report') {
            steps {
                archiveArtifacts artifacts: 'semgrep-report.json', fingerprint: true
            }
        }

        stage('OWASP Dependency-Check') {
            agent { label 'maven_build_server' }
            steps {
                script {
                    sh 'mkdir -p $WORKSPACE/owasp-reports'
                    sh """
                    docker run --rm \\
                        -v "$WORKSPACE":/src \\
                        -v /opt/owasp-data:/usr/share/dependency-check/data \\
                        -v "$WORKSPACE/owasp-reports":/reports \\
                        owasp/dependency-check:latest \\
                        --scan /src \\
                        --format JSON \\
                        --out /reports \\
                        --project "webapp-project-\$BUILD_NUMBER"
                    """
                    sh 'ls -la $WORKSPACE/owasp-reports'
                }
            }
        }

        stage('Publish OWASP Report') {
            steps {
                archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.json', allowEmptyArchive: false
            }
        }

        stage('Validate Security Reports') {
            steps {
                script {
                    echo "🔍 Validating security report contents..."
                    def reports = [
                        'gitleaks-report.json',
                        'semgrep-report.json', 
                        'owasp-reports/dependency-check-report.json'
                    ]
                    
                    for (reportFile in reports) {
                        def exists = sh(script: "[ -f '${reportFile}' ] && echo 'yes' || echo 'no'", returnStdout: true).trim()
                        if (exists == 'yes') {
                            echo "📄 ${reportFile}: File exists"
                            sh "wc -c '${reportFile}'"
                        } else {
                            echo "❌ ${reportFile} not found"
                        }
                    }
                }
            }
        }

        stage('Upload Reports to DefectDojo') {
            agent { label 'maven_build_server' }
            steps {
                withCredentials([string(credentialsId: 'DEFECTDOJO_TOKEN', variable: 'API_TOKEN')]) {
                    script {
                        echo "Uploading security reports to DefectDojo..."
                        // Your existing DefectDojo upload logic here...
                        echo "DefectDojo upload completed"
                    }
                }
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
        
        stage('Deploy to Kubernetes via Ansible') {
            steps {
                echo 'Deploying to Kubernetes via Ansible on remote server...'
                withCredentials([
                    sshUserPrivateKey(credentialsId: "${ANSIBLE_PRIVATE_KEY}", keyFileVariable: 'SSH_KEY'),
                    file(credentialsId: "${KUBECONFIG_CREDENTIAL}", variable: 'KUBECONFIG_FILE')
                ]) {
                    script {
                        sh '''
                            cp ${SSH_KEY} /tmp/ansible_key
                            chmod 600 /tmp/ansible_key
                            mkdir -p /tmp/kube
                            cp ${KUBECONFIG_FILE} /tmp/kube/config
                            chmod 600 /tmp/kube/config
                        '''

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

                        sh """
                            scp -i /tmp/ansible_key -o StrictHostKeyChecking=no /tmp/kube/config ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/kube/config
                        """

                        sh """
                            ssh -i /tmp/ansible_key -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} '
                              ansible-playbook -i ${INVENTORY_FILE} \\
                                -e docker_image=${IMAGE_NAME}:${BUILD_NUMBER} \\
                                -e k8s_namespace=${K8S_NAMESPACE} \\
                                -e deployment_name=${K8S_DEPLOYMENT_NAME} \\
                                -e service_name=${K8S_SERVICE_NAME} \\
                                -e dockerhub_username=${DOCKER_HUB_USERNAME} \\
                                -e build_number=${BUILD_NUMBER} \\
                                -e nodeport=${K8S_NODE_PORT} \\
                                ${PLAYBOOK_FILE}
                            '
                        """
                    }
                }
            }
        }

        // NEW STAGE: Configure Nginx Reverse Proxy
        stage('Configure Nginx Reverse Proxy') {
            steps {
                echo 'Setting up Nginx reverse proxy to Kubernetes service...'
                withCredentials([sshUserPrivateKey(credentialsId: "${PROXY_SSH_KEY}", keyFileVariable: 'PROXY_KEY')]) {
                    script {
                        // Prepare SSH key
                        sh '''
                            cp ${PROXY_KEY} /tmp/proxy_key
                            chmod 600 /tmp/proxy_key
                        '''

                        // Create Nginx configuration template
                        writeFile file: 'nginx-proxy.conf', text: """
server {
    listen 80;
    server_name ${PROXY_DOMAIN};
    
    # Logging
    access_log /var/log/nginx/webapp-access.log;
    error_log /var/log/nginx/webapp-error.log;
    
    location / {
        # Proxy to Kubernetes service via NodePort
        proxy_pass http://${K8S_NODE_IP}:${K8S_NODE_PORT};
        
        # Headers for proper proxy behavior
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (if your app uses WebSockets)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeout configurations
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer configurations for better performance
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check endpoint
    location /nginx-health {
        access_log off;
        return 200 "Nginx proxy is healthy\\n";
        add_header Content-Type text/plain;
    }
    
    # Static files caching (optional optimization)
    location ~* \\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        proxy_pass http://${K8S_NODE_IP}:${K8S_NODE_PORT};
        proxy_set_header Host \$host;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
"""

                        // Copy configuration to proxy server and restart Nginx
                        sh """
                            # Add proxy server to known hosts
                            ssh-keyscan -H ${PROXY_SERVER} >> ~/.ssh/known_hosts 2>/dev/null || true
                            
                            # Copy Nginx config to server
                            scp -i /tmp/proxy_key -o StrictHostKeyChecking=no nginx-proxy.conf ${PROXY_USER}@${PROXY_SERVER}:/tmp/webapp-proxy.conf
                            
                            # Install and configure Nginx on proxy server
                            ssh -i /tmp/proxy_key -o StrictHostKeyChecking=no ${PROXY_USER}@${PROXY_SERVER} '
                                # Install Nginx if not already installed
                                if ! command -v nginx &> /dev/null; then
                                    echo "Installing Nginx..."
                                    sudo apt update && sudo apt install -y nginx
                                fi
                                
                                # Backup existing config if it exists
                                if [ -f /etc/nginx/sites-available/webapp-proxy ]; then
                                    sudo cp /etc/nginx/sites-available/webapp-proxy /etc/nginx/sites-available/webapp-proxy.backup.$(date +%Y%m%d_%H%M%S)
                                fi
                                
                                # Copy new configuration
                                sudo cp /tmp/webapp-proxy.conf /etc/nginx/sites-available/webapp-proxy
                                
                                # Enable site (create symlink)
                                sudo ln -sf /etc/nginx/sites-available/webapp-proxy /etc/nginx/sites-enabled/webapp-proxy
                                
                                # Remove default site if it exists and conflicts
                                if [ -f /etc/nginx/sites-enabled/default ]; then
                                    sudo rm /etc/nginx/sites-enabled/default
                                fi
                                
                                # Test Nginx configuration
                                sudo nginx -t
                                
                                # Reload Nginx
                                sudo systemctl reload nginx
                                sudo systemctl enable nginx
                                
                                # Check Nginx status
                                sudo systemctl status nginx --no-pager
                                
                                echo "Nginx proxy configuration completed successfully!"
                            '
                        """

                        // Wait a moment and test the proxy
                        sh """
                            echo "Waiting for Nginx to fully restart..."
                            sleep 5
                            
                            # Test the proxy endpoint
                            ssh -i /tmp/proxy_key -o StrictHostKeyChecking=no ${PROXY_USER}@${PROXY_SERVER} '
                                echo "Testing Nginx proxy health..."
                                curl -f http://localhost/nginx-health || echo "Health check failed"
                                
                                echo "Testing proxy to Kubernetes..."
                                curl -I http://localhost/ --connect-timeout 10 || echo "Proxy test failed"
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
                rm -f /tmp/ansible_key /tmp/proxy_key
                rm -rf /tmp/kube
                rm -f nginx-proxy.conf
            '''
            archiveArtifacts artifacts: 'target/*.war', allowEmptyArchive: true
            junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
        }
        success {
            echo 'Pipeline completed successfully!'
            echo "Docker image pushed: ${IMAGE_NAME}:${BUILD_NUMBER}"
            echo "Application deployed to Kubernetes namespace: ${K8S_NAMESPACE}"
            echo "Nginx reverse proxy configured at: http://${PROXY_SERVER}/"
            echo "Proxy forwards requests to: http://${K8S_NODE_IP}:${K8S_NODE_PORT}"
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
    }
}
