## Application Reset Sample

### Function
- Reset application
- Clear attack event

### Requirements
- [jq](https://stedolan.github.io/jq/) for JSON parse.
    ```sh
    # Mac
    brew install jq
    # CentOS
    yum -y install epel-release
    yum -y install jq
    # Ubuntu
    apt -y update
    apt -y install jq
    ```

### Steps
1. Configuration  
    ```sh
    CONTRAST_URL="https://xxx.contrastsecurity.com/Contrast"
    AUTH_HEADER="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

    ORG_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    APP_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
    ```
1. Run  
    ```sh
    chmod 755 application_reset.sh
    ./application_reset.sh
    ```
