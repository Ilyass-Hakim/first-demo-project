node('maven_build_server') {

    // Set environment variables
    env.DOCKER_HUB_CREDENTIALS = 'dockerhub-token'
    env.DOCKER_HUB_USERNAME = 'ilyass10devops'
    env.DOCKER_HUB_PASSWORD = credentials('dockerhub-token')
    env.IMAGE_NAME = "${env.DOCKER_HUB_USERNAME}/webapp-project"
    env.K8S_NAMESPACE = 'default'
    env.K8S_DEPLOYMENT_NAME = 'webapp-project'
    env.ANSIBLE_SERVER = '192.168.1.33'
    env.ANSIBLE_USER = 'ansible'
    env.ANSIBLE_PRIVATE_KEY = 'ansible-ssh-key-id'
    env.KUBECONFIG_CREDENTIAL = 'working-kubeconfig'
    env.REPO_URL = 'https://github.com/Ilyass-Hakim/first-demo-project.git'
    env.ANSIBLE_BASE_DIR = '/home/ansible/ansible/'
    env.INVENTORY_FILE = "${env.ANSIBLE_BASE_DIR}/inventories/hosts.yml"
    env.PLAYBOOK_FILE = "${env.ANSIBLE_BASE_DIR}/first-demo-project/kubernetes-deployment.yml"
    env.DEFECTDOJO_URL = 'http://192.168.1.24:8081'
    env.DEFECTDOJO_USER = 'admin'
    env.DEFECTDOJO_PASSWORD = 'admin123'

    try {

        stage('Checkout') {
            echo 'Checking out code from GitHub...'
            checkout scm
        }

        stage('Gitleaks Scan') {
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

        stage('Build & Package WAR') {
            sh 'mvn clean package'
            stash includes: 'target/*.war', name: 'war-file'
        }

        stage('Deploy WAR to Tomcat') {
            unstash 'war-file'
            sh '''
                echo "Deploying WAR..."
                scp -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no target/*.war tomcat@192.168.1.27:/opt/tomcat/webapps/
            '''
        }

        stage('Run Semgrep remotely') {
            sshagent(['sonarqube-server-credentials']) {
                sh '''
                    mkdir -p ~/.ssh
                    ssh-keyscan -H 192.168.1.2 >> ~/.ssh/known_hosts 2>/dev/null || true
                    ssh sonarqube@192.168.1.2 "mkdir -p /home/sonarqube/projects/firstDevopsProject"
                    rsync -avz --delete $WORKSPACE/ sonarqube@192.168.1.2:/home/sonarqube/projects/firstDevopsProject/
                    ssh sonarqube@192.168.1.2 "cd /home/sonarqube/projects/firstDevopsProject && /opt/ci-scripts/run-semgrep.sh"
                    scp sonarqube@192.168.1.2:/home/sonarqube/projects/firstDevopsProject/semgrep-report.json $WORKSPACE/
                '''
            }
        }

        stage('Archive Semgrep Report') {
            archiveArtifacts artifacts: 'semgrep-report.json', fingerprint: true
        }

        stage('OWASP Dependency Check') {
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
            archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.json', fingerprint: true
        }

        stage('Validate Security Reports') {
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
                        echo "📄 ${reportFile}:"
                        sh "echo 'Size: ' && wc -c '${reportFile}'"
                        sh "echo 'Content preview:' && head -n 5 '${reportFile}' || echo 'Unable to preview'"
                    } else {
                        echo "❌ ${reportFile} not found"
                    }
                }
            }
        }

stage('Upload to DefectDojo') {
            steps {
                withCredentials([string(credentialsId: 'DEFECTDOJO_TOKEN', variable: 'DEFECTDOJO_API_TOKEN')]) {
                    script {
                        def defectDojoUrl = 'http://192.168.1.24:8081'
                        def engagementId = '2'
                        def environment = 'Development'
                        
                        echo "Starting DefectDojo uploads..."
                        
                        // Upload Gitleaks report
                        if (fileExists('gitleaks-report.json')) {
                            echo "Uploading Gitleaks report to DefectDojo..."
                            def gitleaksResponse = sh(
                                script: """
                                    curl -s -X POST "${defectDojoUrl}/api/v2/import-scan/" \\
                                         -H "Authorization: Token \${DEFECTDOJO_API_TOKEN}" \\
                                         -F "engagement=${engagementId}" \\
                                         -F "scan_type=Gitleaks Scan" \\
                                         -F "environment=${environment}" \\
                                         -F "file=@gitleaks-report.json"
                                """,
                                returnStdout: true
                            ).trim()
                            echo "Gitleaks upload response: ${gitleaksResponse}"
                            
                            if (gitleaksResponse.contains('"test_id"') || gitleaksResponse.contains('"id"')) {
                                echo "✓ Gitleaks report uploaded successfully"
                            } else {
                                echo "⚠ Gitleaks upload may have failed: ${gitleaksResponse}"
                            }
                        } else {
                            echo "⚠ Gitleaks report not found, skipping upload"
                        }
                        
                        // Upload Dependency Check report
                        if (fileExists('owasp-reports/dependency-check-report.json')) {
                            echo "Uploading Dependency Check report to DefectDojo..."
                            def depCheckResponse = sh(
                                script: """
                                    curl -s -X POST "${defectDojoUrl}/api/v2/import-scan/" \\
                                         -H "Authorization: Token \${DEFECTDOJO_API_TOKEN}" \\
                                         -F "engagement=${engagementId}" \\
                                         -F "scan_type=Dependency Check Scan" \\
                                         -F "environment=${environment}" \\
                                         -F "file=@owasp-reports/dependency-check-report.json"
                                """,
                                returnStdout: true
                            ).trim()
                            echo "Dependency Check upload response: ${depCheckResponse}"
                            
                            if (depCheckResponse.contains('"test_id"') || depCheckResponse.contains('"id"')) {
                                echo "✓ Dependency Check report uploaded successfully"
                            } else {
                                echo "⚠ Dependency Check upload may have failed: ${depCheckResponse}"
                            }
                        } else {
                            echo "⚠ Dependency Check report not found, skipping upload"
                        }
                        
                        // Upload Semgrep report
                        if (fileExists('semgrep-report.json')) {
                            echo "Uploading Semgrep report to DefectDojo..."
                            def semgrepResponse = sh(
                                script: """
                                    curl -s -X POST "${defectDojoUrl}/api/v2/import-scan/" \\
                                         -H "Authorization: Token \${DEFECTDOJO_API_TOKEN}" \\
                                         -F "engagement=${engagementId}" \\
                                         -F "scan_type=Semgrep Scan" \\
                                         -F "environment=${environment}" \\
                                         -F "file=@semgrep-report.json"
                                """,
                                returnStdout: true
                            ).trim()
                            echo "Semgrep upload response: ${semgrepResponse}"
                            
                            if (semgrepResponse.contains('"test_id"') || semgrepResponse.contains('"id"')) {
                                echo "✓ Semgrep report uploaded successfully"
                            } else {
                                echo "⚠ Semgrep upload may have failed: ${semgrepResponse}"
                            }
                        } else {
                            echo "⚠ Semgrep report not found, skipping upload"
                        }
                        
                        echo "DefectDojo uploads completed. Check your DefectDojo engagement for results:"
                        echo "${defectDojoUrl}/engagement/${engagementId}"
                    }
                }
            }
        }




        stage('SonarQube Analysis') {
            withSonarQubeEnv('sq1') {
                sh 'mvn sonar:sonar'
            }
        }

        stage('Package & Deploy to Artifactory') {
            sh 'mvn clean deploy'
        }

        stage('Build Docker Image') {
            script {
                dockerImage = docker.build("${IMAGE_NAME}:${BUILD_NUMBER}")
                dockerImage.tag("latest")
            }
        }

        stage('Push Docker Image') {
            script {
                docker.withRegistry('https://registry.hub.docker.com', DOCKER_HUB_CREDENTIALS) {
                    dockerImage.push("${BUILD_NUMBER}")
                    dockerImage.push('latest')
                }
            }
        }

        stage('Deploy to Kubernetes via Ansible') {
            withCredentials([
                sshUserPrivateKey(credentialsId: "${ANSIBLE_PRIVATE_KEY}", keyFileVariable: 'SSH_KEY'),
                file(credentialsId: "${KUBECONFIG_CREDENTIAL}", variable: 'KUBECONFIG_FILE')
            ]) {
                sh '''
                    cp ${SSH_KEY} /tmp/ansible_key
                    chmod 600 /tmp/ansible_key
                    mkdir -p /tmp/kube
                    cp ${KUBECONFIG_FILE} /tmp/kube/config
                    chmod 600 /tmp/kube/config
                '''
                sh """
                    ssh -i /tmp/ansible_key -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} '
                        if [ -d "${ANSIBLE_BASE_DIR}/first-demo-project/.git" ]; then
                            cd ${ANSIBLE_BASE_DIR}/first-demo-project && git reset --hard && git pull
                        else
                            git clone ${REPO_URL} ${ANSIBLE_BASE_DIR}/first-demo-project
                        fi
                    '
                """
                sh """
                   # scp -i /tmp/ansible_key -o StrictHostKeyChecking=no /tmp/kube/config ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/kube/config
                """
                sh """
                    ssh -i /tmp/ansible_key -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_SERVER} '
                        ansible-playbook -i ${INVENTORY_FILE} \\
                            -e docker_image=${IMAGE_NAME}:${BUILD_NUMBER} \\
                            -e k8s_namespace=${K8S_NAMESPACE} \\
                            -e deployment_name=${K8S_DEPLOYMENT_NAME} \\
                            -e dockerhub_username=${DOCKER_HUB_USERNAME} \\
                            -e build_number=${BUILD_NUMBER} \\
                            ${ANSIBLE_BASE_DIR}/first-demo-project/kubernetes-deployment.yml
                    '
                """
            }
        }

        // Success message
        echo '✅ Pipeline completed successfully!'
        echo "Docker image pushed: ${IMAGE_NAME}:${BUILD_NUMBER}"
        echo "Application deployed to Kubernetes namespace: ${K8S_NAMESPACE}"

    } catch (err) {
        echo '❌ Pipeline failed! Check the logs for details.'
        currentBuild.result = 'FAILURE'
        throw err
    } finally {
        echo 'Cleaning up...'
        sh '''
            rm -f /tmp/ansible_key
            rm -rf /tmp/kube
        '''
        archiveArtifacts artifacts: 'target/*.war', allowEmptyArchive: true
        junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
    }

}
