FROM centos/python-36-centos7

ENV PYTHONDONTWRITEBYTECODE=1
USER root
RUN yum -y install git
RUN mkdir /project
WORKDIR /project
RUN git clone https://github.com/k-tamura/easybuggy4django.git easybuggy
RUN cp -p easybuggy/config/settings.py easybuggy/config/settings_org.py && \
    POS=`cat easybuggy/config/settings_org.py | \
    awk '/^MIDDLEWARE/,/^]/{if($1=="]")print NR}'` && cat easybuggy/config/settings_org.py | \
    sed "${POS} i \    'contrast.agent.middlewares.django_middleware.DjangoMiddleware'" > easybuggy/config/settings.py
COPY contrast-python-agent-2.3.1.tar.gz /project
RUN pip --disable-pip-version-check install -r /project/easybuggy/requirements.txt
RUN pip --disable-pip-version-check install /project/contrast-python-agent-2.3.1.tar.gz

