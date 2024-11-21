## Overview

This is a Groovy sample script that retrieves a list of vulnerabilities from TeamServer and adds a table-formatted comment to a Jira ticket based on the retrieved information.

## Prerequisites
Script verified to work with:
* Groovy Version: 4.0.22
* JVM: 1.8.0_392
* Vendor: Temurin
* OS: Mac OS X

## Preparation

Set the following environment variables. The information can be found in TeamServer under User Menu -> User Settings -> Profile.

```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_AUTHORIZATION=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export CONTRAST_JIRA_URL=https://contrast.atlassian.net/
export CONTRAST_JIRA_USER=xxxx.yyyy@contrastsecurity.com
export CONTRAST_JIRA_API_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
```

## How to Run

```bash
# help
groovy add_comment_v4.groovy --help
# Run
groovy add_comment_v4.groovy -a PetClinic_8001 -j FAKEBUG-12730
```
