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
1. Configuration  
    ```bash
    # URLは正規ライセンス環境の場合はapp, 評価(POC)用ライセンス環境の場合はevalとなります。
    CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast/
    CONTRAST_AUTHORIZATION : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
    CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    CONTRAST_APP_NAME      : PetClinic_8001
    CONTRAST_APP_VERSION   : v8001
    ```
1. Run  
    ```bash
    chmod 755 import.sh
    ./import.sh
    ```

