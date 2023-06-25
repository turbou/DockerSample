FROM jenkins/jenkins:2.387.3
USER root
RUN apt-get update
RUN apt-get install -y telnet
RUN apt-get install -y expect
RUN apt-get install -y python3
RUN apt-get install -y openssl ca-certificates
RUN apt-get install -y wget
RUN apt-get install -y python3-distutils
RUN rm /usr/share/ca-certificates/mozilla/DST_Root_CA_X3.crt
RUN update-ca-certificates
COPY ./plugins.txt /usr/share/jenkins/ref/
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
RUN wget https://bootstrap.pypa.io/pip/3.5/get-pip.py
RUN python3 get-pip.py
COPY ./requirements.txt /tmp/requirements.txt
RUN pip --disable-pip-version-check install -r /tmp/requirements.txt
USER jenkins
COPY ./PetClinic_Selenium/config.xml /usr/share/jenkins/ref/jobs/PetClinic_Selenium/config.xml

