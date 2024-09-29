## Overview

This is a Python sample script that retrieves a list of vulnerabilities from TeamServer and adds a table-formatted comment to a Jira ticket based on the retrieved information.

## Prerequisites

* Tested on Python 3.12.5. Should work with any Python 3.x version.
* Required libraries:
    ```bash
    certifi==2024.8.30
    charset-normalizer==3.3.2
    idna==3.10
    requests==2.32.3
    urllib3==2.2.3
    ```

## Preparation

Set the following environment variables. The information can be found in TeamServer under User Menu -> User Settings -> Profile.

```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_AUTHORIZATION=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export CONTRAST_APP_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

Also set the Jira authentication information and the ticket ID to which you want to add the comment.

```bash
export CONTRAST_JIRA_USER=xxxx.yyyy@contrastsecurity.com
export CONTRAST_JIRA_API_TOKEN=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export CONTRAST_JIRA_TICKET_ID=FAKEBUG-12730
```

If you want to filter vulnerabilities by session metadata, set the following environment variables as well.

```bash
export CONTRAST_METADATA_LABEL=branchName
export CONTRAST_METADATA_VALUE=feature/dev-001
```

## How to Run

```bash
python ./add_comment_v2.py
``` 

