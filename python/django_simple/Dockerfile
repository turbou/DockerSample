FROM centos/python-36-centos7

ENV PYTHONDONTWRITEBYTECODE=1
USER root
RUN mkdir /project
WORKDIR /project
COPY requirements.txt /project
COPY contrast-python-agent-2.3.1.tar.gz /project
RUN pip --disable-pip-version-check install -r /project/requirements.txt
RUN pip --disable-pip-version-check install /project/contrast-python-agent-2.3.1.tar.gz
COPY sample /project/sample

