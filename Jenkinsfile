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
                    ssh-keyscan -H 192.168.1.30 >> ~/.ssh/known_hosts 2>/dev/null || true
                    ssh sonarqube@192.168.1.30 "mkdir -p /home/sonarqube/projects/firstDevopsProject"
                    rsync -avz --delete $WORKSPACE/ sonarqube@192.168.1.30:/home/sonarqube/projects/firstDevopsProject/
                    ssh sonarqube@192.168.1.30 "cd /home/sonarqube/projects/firstDevopsProject && /opt/ci-scripts/run-semgrep.sh"
                    scp sonarqube@192.168.1.30:/home/sonarqube/projects/firstDevopsProject/semgrep-report.json $WORKSPACE/
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

stage('Upload Reports to DefectDojo') {
    script {
        withCredentials([string(credentialsId: 'DEFECTDOJO_TOKEN', variable: 'DEFECTDOJO_API_TOKEN')]) {

            def ENGAGEMENT_ID = '2'

            def reports = [
                [path: "${WORKSPACE}/gitleaks-report.json", type: "Gitleaks Scan"],
                [path: "${WORKSPACE}/owasp-reports/dependency-check-report.json", type: "Dependency Check"],
                [path: "${WORKSPACE}/semgrep-report.json", type: "Semgrep Scan"]
            ]

            reports.each { report ->

                def reportPath = report.path
                def scanType = report.type
                def scanTypeId = ''

                def scanTypeEncoded = URLEncoder.encode(scanType, "UTF-8")

                def result = sh(
                    script: """curl -s -k -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" -H "Accept: application/json" "${DEFECTDOJO_URL}/api/v2/test_types/?name=${scanTypeEncoded}" """,
                    returnStdout: true
                ).trim()

                def json = readJSON text: result

                if (json.count > 0) {
                    scanTypeId = json.results[0].id
                    echo "Found existing scan type '${scanType}' with ID ${scanTypeId}"
                } else {
                    // Create scan type if it does not exist
                    echo "Scan type '${scanType}' not found. Creating..."
                    def createResult = sh(
                        script: """curl -s -k -X POST "${DEFECTDOJO_URL}/api/v2/test_types/" \\
                        -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \\
                        -H "Content-Type: application/json" \\
                        -d '{ "name": "${scanType}", "active": true }'""",
                        returnStdout: true
                    ).trim()

                    def createJson = readJSON text: createResult
                    scanTypeId = createJson.id
                    echo "Created scan type '${scanType}' with ID ${scanTypeId}"
                }

                // Upload report if file exists and is not empty
                if (fileExists(reportPath)) {
                    def content = readFile(reportPath).trim()
                    if (content) {
                        echo "=== Uploading ${scanType} ==="
                        sh "ls -l ${reportPath}"
                        sh "echo '--- First 20 lines of report ---'; head -n 20 ${reportPath}"

                        sh """
                        curl -s -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \\
                            -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \\
                            -F "engagement=${ENGAGEMENT_ID}" \\
                            -F "scan_type=${scanTypeId}" \\
                            -F "file=@${reportPath}"
                        """
                        echo "${scanType} uploaded successfully!"
                    } else {
                        echo "Report ${reportPath} is empty. Skipping upload."
                    }
                } else {
                    echo "Report ${reportPath} does not exist. Skipping upload."
                }
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
                    scp -i /tmp/ansible_key -o StrictHostKeyChecking=no /tmp/kube/config ${ANSIBLE_USER}@${ANSIBLE_SERVER}:/tmp/kube/config
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
