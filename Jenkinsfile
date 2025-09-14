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

            stage('Gitleaks Scan') {
                echo 'Running Gitleaks secret scan...'
                sh '''
                    set -e
            
                    # Ensure full git history so Gitleaks can scan past commits
                    if git rev-parse --is-shallow-repository >/dev/null 2>&1; then
                      git fetch --prune --unshallow || true
                    else
                      git fetch --all --prune || true
                    fi
            
                    mkdir -p "$WORKSPACE"
            
                    # Run Gitleaks via Docker for consistent versioning
                    docker run --rm \
                      -v "$WORKSPACE":"$WORKSPACE" \
                      -w "$WORKSPACE" \
                      zricethezav/gitleaks:latest detect \
                        --source "$WORKSPACE" \
                        --report-format json \
                        --report-path "$WORKSPACE/gitleaks-report.json" \
                        --redact \
                      || true  # gitleaks exits 1 if leaks found; keep pipeline going
            
                    # Ensure we always have a JSON file to archive
                    if [ ! -s "$WORKSPACE/gitleaks-report.json" ]; then
                      echo '[]' > "$WORKSPACE/gitleaks-report.json"
                      echo "No report produced by Gitleaks; wrote empty JSON array."
                    fi
                '''
            
                archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: false
            
                script {
                    def txt = readFile('gitleaks-report.json').trim()
                    if (txt && txt != '[]') {
                        currentBuild.result = 'UNSTABLE'
                        echo 'Gitleaks detected secrets. Marking build as UNSTABLE.'
                    } else {
                        echo 'No secrets detected by Gitleaks.'
                    }
                }
            }

        
        stage('SonarQube Analysis') {
            withSonarQubeEnv('sq1') {
                sh 'mvn sonar:sonar'
            }
        }

        stage('Semgrep Analysis') {
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
                    --format ALL \
                    --out /reports \
                    --project "jenkins-build"
            '''
            archiveArtifacts artifacts: 'owasp-reports/dependency-check-report.*', fingerprint: true
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
        
        
            stage('Upload to DefectDojo') {
              withCredentials([string(credentialsId: 'DEFECTDOJO_TOKEN', variable: 'DEFECTDOJO_API_TOKEN')]) {
                def defectDojoUrl = 'http://192.168.1.24:8081'
                def engagementId  = '1'
                def environment   = 'Development'
            
                echo "Starting DefectDojo uploads..."
            
                // quick inventory
                sh '''
                  set -e
                  echo "Current directory: $(pwd)"
                  find . -maxdepth 3 -type f \\( -name "*.json" -o -name "*.xml" \\) -printf " - %p\\n" || true
                '''
            
                // ---------- Gitleaks ----------
                sh '''
                  set -e
                  if [ -f "gitleaks-report.json" ]; then
                    echo "Uploading Gitleaks report..."
                    echo "File size: $(wc -c gitleaks-report.json)"
                    RESPONSE=$(curl -s -X POST 'http://192.168.1.24:8081/api/v2/import-scan/' \
                      -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                      -F "engagement=1" \
                      -F "scan_type=Gitleaks Scan" \
                      -F "environment=Development" \
                      -F "file=@gitleaks-report.json")
                    echo "Gitleaks response: $RESPONSE"
                    echo "$RESPONSE" | grep -qE 'test_id|"id"' && echo "Gitleaks uploaded successfully" || echo "Gitleaks upload response unclear"
                  else
                    echo "gitleaks-report.json not found"
                  fi
                '''
            
                // ---------- Dependency-Check (prefer XML; JSON fallback) ----------
                sh '''
                  set -e
                  FILE_XML="owasp-reports/dependency-check-report.xml"
                  FILE_JSON="owasp-reports/dependency-check-report.json"
            
                  if [ -f "$FILE_XML" ]; then
                    echo "Uploading Dependency-Check XML report..."
                    echo "File size: $(wc -c "$FILE_XML")"
                    RESPONSE=$(curl -s -X POST 'http://192.168.1.24:8081/api/v2/import-scan/' \
                      -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                      -F "engagement=1" \
                      -F "scan_type=Dependency Check Scan" \
                      -F "environment=Development" \
                      -F "file=@${FILE_XML}")
                    echo "Dependency-Check response: $RESPONSE"
                    echo "$RESPONSE" | grep -qE 'test_id|"id"' && echo "Dependency-Check uploaded successfully" || echo "Dependency-Check upload response unclear"
                  elif [ -f "$FILE_JSON" ]; then
                    echo "XML not found; uploading Dependency-Check JSON instead..."
                    echo "File size: $(wc -c "$FILE_JSON")"
                    RESPONSE=$(curl -s -X POST 'http://192.168.1.24:8081/api/v2/import-scan/' \
                      -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                      -F "engagement=1" \
                      -F "scan_type=Dependency Check Scan" \
                      -F "environment=Development" \
                      -F "file=@${FILE_JSON}")
                    echo "Dependency-Check response: $RESPONSE"
                    echo "$RESPONSE" | grep -qE 'test_id|"id"' && echo "Dependency-Check uploaded successfully" || echo "Dependency-Check upload response unclear"
                  else
                    echo "No Dependency-Check report found under owasp-reports/"
                  fi
                '''
            
                // ---------- Semgrep ----------
                sh '''
                  set -e
                  if [ -f "semgrep-report.json" ]; then
                    echo "Uploading Semgrep report (Semgrep JSON Report)..."
                    echo "File size: $(wc -c semgrep-report.json)"
                    RESPONSE=$(curl -s -X POST 'http://192.168.1.24:8081/api/v2/import-scan/' \
                      -H "Authorization: Token ${DEFECTDOJO_API_TOKEN}" \
                      -F "engagement=1" \
                      -F "scan_type=Semgrep JSON Report" \
                      -F "environment=Development" \
                      -F "file=@semgrep-report.json")
                    echo "Semgrep response: $RESPONSE"
                    echo "$RESPONSE" | grep -qE 'test_id|"id"' && echo "Semgrep uploaded successfully" || echo "Semgrep upload response unclear"
                  else
                    echo "semgrep-report.json not found"
                  fi
                '''
            
                echo "DefectDojo uploads completed. Check: ${defectDojoUrl}/engagement/${engagementId}"
              }
            }


        // Success message
        echo 'Pipeline completed successfully!'
        echo "Docker image pushed: ${IMAGE_NAME}:${BUILD_NUMBER}"
        echo "Application deployed to Kubernetes namespace: ${K8S_NAMESPACE}"

    } catch (err) {
        echo 'Pipeline failed! Check the logs for details.'
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
