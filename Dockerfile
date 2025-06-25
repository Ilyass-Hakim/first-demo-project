FROM tomcat:11.0-jdk17-temporary

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Add Artifactory credentials (you’ll replace with Jenkins secret later)
ARG ARTIFACTORY_USER
ARG ARTIFACTORY_PASS

# Download WAR from Artifactory (replace with your actual URL)
RUN apt-get update && apt-get install -y curl && \
    curl -u $ARTIFACTORY_USER:$ARTIFACTORY_PASS -o /usr/local/tomcat/webapps/ROOT.war \
    "http://192.168.1.23:8081/artifactory/libs-release-local/edu/FSTS/informatique/webapp-project/1.0.0/webapp-project-1.0.0.war"

# Change Tomcat port to 8084
RUN sed -i 's/Connector port="8080"/Connector port="8084"/' /usr/local/tomcat/conf/server.xml

EXPOSE 8084
CMD ["catalina.sh", "run"]
