FROM centos:7.6.1810

USER root
RUN yum -y update \
    && yum -y install gcc make autoconf curl bzip2 git \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local/ \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=2.7 \
    && conda update conda \
    && conda clean --all --yes \
    && rpm -e --nodeps curl bzip2 \
    && yum clean all

RUN mkdir /project
WORKDIR /project
COPY contrast-python-agent-2.3.1.tar.gz /project/
RUN git clone https://github.com/Contrast-Security-OSS/DjanGoat.git
RUN cp -p DjanGoat/pygoat/settings.py DjanGoat/pygoat/settings_org.py && \
    POS=`cat DjanGoat/pygoat/settings_org.py | \
    awk '/^MIDDLEWARE/,/^]/{if($1=="]")print NR}'` && cat DjanGoat/pygoat/settings_org.py | \
    sed "${POS} i \    ,'contrast.agent.middlewares.django_middleware.DjangoMiddleware'" > DjanGoat/pygoat/settings.py
RUN pip --disable-pip-version-check install -r /project/DjanGoat/requirements.txt
RUN pip --disable-pip-version-check install /project/contrast-python-agent-2.3.1.tar.gz
RUN python /project/DjanGoat/manage.py migrate

