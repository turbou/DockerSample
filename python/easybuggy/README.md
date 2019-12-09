## EasyBuggy4Django

### Steps
1. Download PythonAgent  
contrast-python-agent-2.4.0.tar.gz is dummy file.  
replace with the correct agent file.  
_If the version changes, change the file name in Dockerfile._

1. Download contrast_security.yaml from TeamServer or rewrite the existing file.  
_If the agent cannot communicate with the service due to an agent bug, add the following settings._
    ```yaml
	server:
		name: Docker_CentOS7
		path: /project
    ```

1. Build  
    ```sh
    docker-compose build --no-cache
    ```

1. Run  
    ```sh
    docker-compose up -d
    ```

1. Access  
    `http://localhost:8888`  

1. Check TeamServer  
make sure the Server and Application are onboarded.

1. Other
    ```sh
    docker ps
    docker exec -it easybuggy bash
    docker-compose down
    ```

