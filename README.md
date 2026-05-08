
# DevSecOps Pipeline Showcase (first-demo-project)

![DevSecOps](https://img.shields.io/badge/DevSecOps-Ready-brightgreen)
![Jenkins](https://img.shields.io/badge/CI%2FCD-Jenkins-orange)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-blue)
![Security](https://img.shields.io/badge/Security-Multi--Layered-red)

## 📋 Project Overview

This project is a comprehensive **DevSecOps Pipeline** demonstration. It features a simple Java Web application (JSP) used as a baseline to showcase how to integrate security at every stage of the Software Development Life Cycle (SDLC).

The pipeline automates everything from code checkout to deployment on a Kubernetes cluster, while performing deep security analysis using industry-standard tools.

---

## 🏗️ Architecture & Pipeline Stages

The Jenkins pipeline (`Jenkinsfile`) is organized into the following stages:

1.  **Checkout**: Retrieves the latest code from GitHub.
2.  **Build & Package**: Compiles the Java code and packages it into a `.war` file using Maven.
3.  **Deploy to Tomcat (Legacy)**: Deploys the WAR file to a traditional Tomcat server via SCP for legacy support demonstration.
4.  **Gitleaks Scan**: Scans the repository history for leaked secrets (API keys, passwords, etc.).
5.  **SonarQube Analysis**: Performs Static Application Security Testing (SAST) and code quality checks.
6.  **Semgrep Analysis**: Executes fast, customizable security scans using Semgrep.
7.  **OWASP Dependency Check**: Analyzes project dependencies for known vulnerabilities (SCA).
8.  **Artifactory Deployment**: Pushes the validated Maven artifacts to **JFrog Artifactory**.
9.  **Dockerization**: Builds a Docker image (based on Tomcat 11) and pushes it to **Docker Hub**.
10. **K8s Deployment via Ansible**: Uses **Ansible playbooks** to orchestrate the deployment onto a Kubernetes cluster.
11. **Vulnerability Management**: Uploads all security reports to **DefectDojo** for centralized tracking.

---

## 🛡️ Security Stack (DevSecOps)

| Tool | Category | Purpose |
| :--- | :--- | :--- |
| **Gitleaks** | Secret Scanning | Detects hardcoded secrets in git history. |
| **SonarQube** | SAST / Quality | Deep code analysis, coverage, and security hotspots. |
| **Semgrep** | SAST | Fast security linting with custom rule support. |
| **OWASP Dep-Check** | SCA | Identifies vulnerable third-party libraries. |
| **DefectDojo** | ASOC | Centralizes and triages all security findings. |

---

## 🚀 Infrastructure & DevOps Tools

*   **CI/CD**: Jenkins (Declarative Pipeline)
*   **Artifacts**: JFrog Artifactory (`http://192.168.1.23:8081`)
*   **Containers**: Docker (Images: `ilyass10devops/webapp-project`)
*   **Provisioning**: Ansible (Playbooks in `kubernetes-deployment.yml`)
*   **Orchestration**: Kubernetes (K8s)
*   **Deployment Target**: NodePort Service on port `30080`

---

## ⚙️ Configuration & Requirements

To run this pipeline, the following credentials must be configured in Jenkins:

| Credential ID | Type | Description |
| :--- | :--- | :--- |
| `dockerhub-token` | Secret Text | Docker Hub API token/password. |
| `ansible-ssh-key-id` | SSH Key | Private key to access the Ansible server. |
| `working-kubeconfig` | Secret File | Kubeconfig file for K8s cluster access. |
| `DEFECTDOJO_TOKEN` | Secret Text | API Key for DefectDojo. |
| `sonarqube-server-credentials`| SSH Key | Access to the SonarQube scan host. |

### Ports Mapping
*   **Artifactory**: 8081
*   **SonarQube**: 9000 (Default)
*   **DefectDojo**: 8081 (Custom mapping in pipeline)
*   **Kubernetes Service**: 30080

---

## 📄 License
Project created for educational purposes at **FSTS Informatique**.
