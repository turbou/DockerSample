FROM jenkins/jenkins:2.176.1
USER root
COPY ./plugins.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
RUN apt-get update
RUN apt-get install -y telnet
RUN apt-get install -y expect
RUN apt-get install -y python3
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
COPY ./requirements.txt /tmp/requirements.txt
RUN pip --disable-pip-version-check install -r /tmp/requirements.txt
USER jenkins
COPY ./PetClinic_Selenium/config.xml /usr/share/jenkins/ref/jobs/PetClinic_Selenium/config.xml

