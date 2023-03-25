FROM python:3.9.7
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
ADD contrast_security.yaml /code/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN django-admin startproject app .
COPY settings.py /code/app/
COPY wsgi.py /code/app/
RUN python manage.py migrate
