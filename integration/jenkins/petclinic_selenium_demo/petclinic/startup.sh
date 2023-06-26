#!/bin/sh
if [ $# -eq 1 ]; then
    APP_VERSION=${1}
fi
java -javaagent:/tmp/contrast/contrast.jar \
-Dcontrast.server.environment=development \
-Dcontrast.server.name=MacBookPro \
-Dcontrast.agent.java.standalone_app_name=PetClinic_8001_JenkinsDemo \
-Dcontrast.application.version=${APP_VERSION} \
-Dcontrast.agent.contrast_working_dir=contrast-8001/ \
-Dcontrast.agent.logger.level=INFO \
-Dcontrast.agent.polling.app_activity_ms=3000 \
-Dcontrast.agent.polling.server_activity_ms=3000 \
-Dcontrast.api.timeout_ms=1000 \
-jar /tmp/petclinic/spring-petclinic-2.5.0-SNAPSHOT.jar --server.port=8001
