FROM python:3.9.7
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
RUN mkdir /project
WORKDIR /project
COPY requirements.txt /project/
RUN apt-get update
RUN apt-get install -y gettext vim postgresql-client
RUN pip --disable-pip-version-check install -r requirements.txt --trusted-host pypi.python.org --trusted-host pypi.org --trusted-host files.pythonhosted.org
COPY .vimrc /root/
