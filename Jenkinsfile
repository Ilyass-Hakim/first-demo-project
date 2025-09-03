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
                    # Run gitleaks and capture the exit code
                    gitleaks detect --source . --report-path gitleaks-report.json || exit_code=$?
                    
                    # If no report was created (no secrets found), create a proper empty report
                    if [ ! -f "gitleaks-report.json" ]; then
                        echo '{"results":[]}' > gitleaks-report.json
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
                        # Add host key to known_hosts if not already present
                        mkdir -p ~/.ssh
                        ssh-keyscan -H 192.168.1.30 >> ~/.ssh/known_hosts 2>/dev/null || true
                        
                        # Ensure the remote project folder exists
                        ssh sonarqube@192.168.1.30 "mkdir -p /home/sonarqube/projects/firstDevopsProject"

                        # Sync the Jenkins workspace to the remote server
                        rsync -avz --delete $WORKSPACE/ sonarqube@192.168.1.30:/home/sonarqube/projects/firstDevopsProject/

                        # Run Semgrep on the remote server
                        ssh sonarqube@192.168.1.30 "cd /home/sonarqube/projects/firstDevopsProject && /opt/ci-scripts/run-semgrep.sh"

                        # Copy the Semgrep report back to Jenkins workspace
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

        // NEW STAGE: OWASP Dependency Check
stage('OWASP Dependency-Check') {
    agent { label 'maven_build_server' }
    steps {
        script {


            // Run OWASP Dependency-Check Docker scan
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

            // Show report
            sh 'ls -la $WORKSPACE/owasp-reports'
        }
    }
}
        stage('Publish OWASP Report') {
    steps {
        archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.json', allowEmptyArchive: false
    }
}


   
        // NEW STAGE: Upload Reports to DefectDojo
        stage('Upload Reports to DefectDojo') {
            agent { label 'maven_build_server' }
            steps {
                echo 'Uploading security reports to DefectDojo...'
                script {
                    // Get DefectDojo API token
                    def apiToken = sh(
                        script: '''
                            # Get API token from DefectDojo
                            curl -s -X POST "${DEFECTDOJO_URL}/api/v2/api-token-auth/" \\
                                -H "Content-Type: application/json" \\
                                -d "{\\"username\\":\\"${DEFECTDOJO_USER}\\",\\"password\\":\\"${DEFECTDOJO_PASSWORD}\\"}" \\
                                | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || echo "failed"
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    if (apiToken != "failed") {
                        echo "✅ Successfully obtained DefectDojo API token"
                        
                        // Create or get product ID
                        def productId = sh(
                            script: """
                                # Create product if it doesn't exist
                                curl -s -X POST "${DEFECTDOJO_URL}/api/v2/products/" \\
                                    -H "Authorization: Token ${apiToken}" \\
                                    -H "Content-Type: application/json" \\
                                    -d '{"name":"webapp-project","description":"Web Application Security Scans","prod_type":1}' \\
                                    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('id', ''))" 2>/dev/null || \\
                                # If creation fails, try to get existing product
                                curl -s -X GET "${DEFECTDOJO_URL}/api/v2/products/?name=webapp-project" \\
                                    -H "Authorization: Token ${apiToken}" \\
                                    | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['results'][0]['id'] if data['results'] else '')" 2>/dev/null || echo "1"
                            """,
                            returnStdout: true
                        ).trim()
                        
                        echo "Using Product ID: ${productId}"
                        
                        // Upload Gitleaks report
                        sh """
                            if [ -f "gitleaks-report.json" ] && [ -s "gitleaks-report.json" ]; then
                                echo "Uploading Gitleaks report..."
                                curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                                    -H "Authorization: Token ${apiToken}" \\
                                    -F "scan_date=\$(date +%Y-%m-%d)" \\
                                    -F "minimum_severity=Info" \\
                                    -F "active=true" \\
                                    -F "verified=false" \\
                                    -F "scan_type=Gitleaks Scan" \\
                                    -F "product_name=webapp-project" \\
                                    -F "file=@gitleaks-report.json" \\
                                    -F "engagement_name=Jenkins-Build-${BUILD_NUMBER}"
                                echo "✅ Gitleaks report uploaded"
                            else
                                echo "⚠️  No Gitleaks report to upload"
                            fi
                        """
                        
                        // Upload Semgrep report
                        sh """
                            if [ -f "semgrep-report.json" ] && [ -s "semgrep-report.json" ]; then
                                echo "Uploading Semgrep report..."
                                curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                                    -H "Authorization: Token ${apiToken}" \\
                                    -F "scan_date=\$(date +%Y-%m-%d)" \\
                                    -F "minimum_severity=Info" \\
                                    -F "active=true" \\
                                    -F "verified=false" \\
                                    -F "scan_type=Semgrep JSON Report" \\
                                    -F "product_name=webapp-project" \\
                                    -F "file=@semgrep-report.json" \\
                                    -F "engagement_name=Jenkins-Build-${BUILD_NUMBER}"
                                echo "✅ Semgrep report uploaded"
                            else
                                echo "⚠️  No Semgrep report to upload"
                            fi
                        """
                        
                        // Upload OWASP Dependency Check report
                        sh """
                            if [ -f "owasp-reports/dependency-check-report.json" ]; then
                                echo "Uploading OWASP Dependency Check report..."
                                curl -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                                    -H "Authorization: Token ${apiToken}" \\
                                    -F "scan_date=\$(date +%Y-%m-%d)" \\
                                    -F "minimum_severity=Info" \\
                                    -F "active=true" \\
                                    -F "verified=false" \\
                                    -F "scan_type=Dependency Check Scan" \\
                                    -F "product_name=webapp-project" \\
                                    -F "file=@owasp-reports/dependency-check-report.json" \\
                                    -F "engagement_name=Jenkins-Build-${BUILD_NUMBER}"
                                echo "✅ OWASP Dependency Check report uploaded"
                            else
                                echo "⚠️  No OWASP Dependency Check report to upload"
                            fi
                        """
                        
                        echo "🎉 All reports uploaded to DefectDojo!"
                        echo "📊 View results at: ${DEFECTDOJO_URL}/product/webapp-project"
                        
                    } else {
                        echo "❌ Failed to get DefectDojo API token. Skipping upload."
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
