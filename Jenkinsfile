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
            # Run gitleaks
            gitleaks detect --source . --report-path $WORKSPACE/gitleaks-report.json || exit_code=$?
            
            # Ensure report exists even if no secrets found
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

        
stage('Build & Package WAR') {
    agent { label 'maven_build_server' }
    steps {
        sh 'mvn clean package'
        stash includes: 'target/*.war', name: 'war-file'
    }
}

stage('Deploy WAR to Tomcat') {
    agent { label 'maven_build_server' } 
    steps {
        unstash 'war-file'
        sh '''
            echo "Deploying WAR..."
            scp -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no target/*.war tomcat@192.168.1.27:/opt/tomcat/webapps/
        '''
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

                # Copy report back to Jenkins workspace
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
stage('OWASP Dependency Check') {
    steps {
        sh '''
            mkdir -p $WORKSPACE/owasp-reports
            docker run --rm \
              -v $WORKSPACE:/src \
              -v /opt/owasp-data:/usr/share/dependency-check/data \
              -v $WORKSPACE/owasp-reports:/reports \
              --user $(id -u):$(id -g) \
              owasp/dependency-check:latest \
              --scan /src \
              --format JSON \
              --out /reports \
              --project "jenkins-build"
        '''
    }
    post {
        success {
            archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.json', fingerprint: true
        }
    }
}



stage('Publish OWASP Report') {
    steps {
        archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.json', allowEmptyArchive: false
    }
}



   
        // NEW STAGE: Upload Reports to DefectDojo
stage('Validate Security Reports') {
    steps {
        script {
            echo "🔍 Validating security report contents..."
            
            // Check each report file
            def reports = [
                'gitleaks-report.json',
                'semgrep-report.json', 
                'owasp-reports/dependency-check-report.json'
            ]
            
            for (reportFile in reports) {
                def exists = sh(script: "[ -f '${reportFile}' ] && echo 'yes' || echo 'no'", returnStdout: true).trim()
                if (exists == 'yes') {
                    echo "📄 ${reportFile}:"
                    sh "echo 'Size: ' && wc -c '${reportFile}'"
                    sh "echo 'Content preview:' && head -n 5 '${reportFile}' || echo 'Unable to preview'"
                    
                    // Check if JSON is valid
                    def isValidJson = sh(script: "jq empty '${reportFile}' 2>/dev/null && echo 'valid' || echo 'invalid'", returnStdout: true).trim()
                    echo "JSON validity: ${isValidJson}"
                    
                    // Check if report has findings
                    if (reportFile.contains('gitleaks')) {
                        def findings = sh(script: "jq length '${reportFile}' 2>/dev/null || echo '0'", returnStdout: true).trim()
                        echo "Gitleaks findings count: ${findings}"
                    } else if (reportFile.contains('semgrep')) {
                        def findings = sh(script: "jq '.results | length' '${reportFile}' 2>/dev/null || echo '0'", returnStdout: true).trim()
                        echo "Semgrep findings count: ${findings}"
                    } else if (reportFile.contains('dependency-check')) {
                        def findings = sh(script: "jq '.dependencies | length' '${reportFile}' 2>/dev/null || echo '0'", returnStdout: true).trim()
                        echo "OWASP dependencies scanned: ${findings}"
                    }
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
                echo "Using DefectDojo token from Jenkins credentials."

                def productName = 'webapp-project'
                def engagementName = 'Jenkins-Build'
                def engagementDesc = "Automated engagement for ${productName}"

                // Get product ID
                def productId = sh(script: 'curl -s -H "Authorization: Token ' + API_TOKEN + '" ' +
                    '"' + DEFECTDOJO_URL + '/api/v2/products/?name=' + productName + '" | jq -r \'.results[0].id\'',
                    returnStdout: true).trim()

                if (productId == "null" || productId == "") {
                    error "❌ Product '${productName}' does not exist in DefectDojo. Create it first."
                }
                echo "✅ Found product ID: ${productId}"

                // Get engagement ID
                def engagementId = sh(script: 'curl -s -H "Authorization: Token ' + API_TOKEN + '" ' +
                    '"' + DEFECTDOJO_URL + '/api/v2/engagements/?name=' + engagementName + '&product=' + productId + '" | jq -r \'.results[0].id\'',
                    returnStdout: true).trim()

                // Create engagement if not exists
                if (engagementId == "null" || engagementId == "") {
                    echo "Engagement not found. Creating new engagement..."
                    engagementId = sh(script: 'curl -s -X POST "' + DEFECTDOJO_URL + '/api/v2/engagements/" ' +
                        '-H "Authorization: Token ' + API_TOKEN + '" ' +
                        '-H "Content-Type: application/json" ' +
                        '-d \'{' +
                        '"name": "' + engagementName + '",' +
                        '"description": "' + engagementDesc + '",' +
                        '"product": ' + productId + ',' +
                        '"status": "In Progress",' +
                        '"target_start": "' + sh(script: 'date +%Y-%m-%d', returnStdout: true).trim() + '",' +
                        '"target_end": "' + sh(script: 'date +%Y-%m-%d', returnStdout: true).trim() + '"' +
                        '}\' | jq -r \'.id\'',
                        returnStdout: true).trim()
                    echo "✅ Created engagement ID: ${engagementId}"
                } else {
                    echo "✅ Found existing engagement ID: ${engagementId}"
                }

                // Reports to upload with CORRECT scanner types
               def reports = [
                [file: 'gitleaks-report.json', scanType: 'Generic Findings Import'],
                [file: 'owasp-reports/dependency-check-report.json', scanType: 'Generic Findings Import'],
                [file: 'semgrep-report.json', scanType: 'Generic Findings Import']
            ]

                // Upload each report with better error handling
                for (r in reports) {
                    def filePath = r.file
                    def scanType = r.scanType
                    def description = r.description

                    def fileExists = sh(script: "[ -f '${filePath}' ] && [ -s '${filePath}' ] && echo 'yes' || echo 'no'", returnStdout: true).trim()
                    if (fileExists == 'yes') {
                        echo "📤 Uploading ${filePath} as ${scanType}..."
                        
                        // Check file content first
                        sh "echo 'File size:' && wc -c '${filePath}'"
                        sh "echo 'First 200 chars:' && head -c 200 '${filePath}'"
                        
                        def uploadResponse = sh(script: '''
                            curl -s -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
                                 -H "Authorization: Token ${API_TOKEN}" \
                                 -F "engagement=''' + engagementId + '''" \
                                 -F "scan_date=$(date +%Y-%m-%d)" \
                                 -F "minimum_severity=Info" \
                                 -F "active=true" \
                                 -F "verified=false" \
                                 -F "scan_type=''' + scanType + '''" \
                                 -F "file=@''' + filePath + '''" \
                                 -w "HTTP_CODE:%{http_code}"
                        ''', returnStdout: true).trim()
                        
                        echo "Upload response: ${uploadResponse}"
                        
                        if (uploadResponse.contains("HTTP_CODE:201") || uploadResponse.contains("HTTP_CODE:200")) {
                            echo "✅ Successfully uploaded ${filePath}"
                        } else {
                            echo "❌ Failed to upload ${filePath}: ${uploadResponse}"
                        }
                    } else {
                        echo "⚠️ File ${filePath} does not exist or is empty. Skipping."
                    }
                }

                echo "🎉 DefectDojo upload process completed! Check engagement: ${DEFECTDOJO_URL}/engagement/${engagementId}"
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
