### Requirements
- [jq](https://stedolan.github.io/jq/) for JSON parse.
  
    ```bash
    # Mac
    brew install jq
    # CentOS
    yum -y install epel-release
    yum -y install jq
    # Ubuntu
    apt -y update
    apt -y install jq
    ```
    
- [recode](https://github.com/rrthomas/recode/) for HTML safe string parse.

    ```bash
    # Mac
    brew install recode
    # CentOS
    yum -y install recode
    # Ubuntu
    apt -y install recode
    ```

### Steps
1. Environment
    ```bash
    export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
    export CONTRAST_AUTHORIZATION=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
    export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export CONTRAST_APP_NAME=PetClinic
    export REDMINE_BASEURL=http://host/redmine/
    export REDMINE_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    export REDMINE_PROJECT_ID=contrastsecurity
    ```
1. Run  
    ```bash
    chmod 755 import.sh
    ./import.sh
    ```

