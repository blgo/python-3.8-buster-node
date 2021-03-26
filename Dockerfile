FROM python:3.8-slim-buster

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV DEBIAN_FRONTEND=noninteractive

# Configure timezone
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN /usr/local/bin/python -m pip install --upgrade pip

RUN apt-get update \
  && apt-get -y upgrade \ 
  # dependencies for building Python packages
  && apt-get install -y build-essential \
  # psycopg2 dependencies
  && apt-get install -y libpq-dev \
  # Django UML models diagram and pygraphviz dependencies
  && apt-get install -y graphviz libgraphviz-dev \
  # Translations dependencies
  && apt-get install -y gettext \
  # Git with Vim and Nano editors
  && apt-get install -y git git-lfs vim nano \
  && apt-get install -y nodejs npm

RUN npm install -g yarn elasticdump

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.1/zsh-in-docker.sh)" -- \
    -t robbyrussell \
    -p git -p node \
    -p pip \
    -p django \
    -p python \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions

# Requirements are installed here to ensure they will be cached.
COPY ./requirements /requirements
RUN pip install -r /requirements/local.txt
# Install production dependencies
RUN pip install -r /requirements/production.txt

ENV ORACLE_HOME /usr/lib/oracle/18.5/client64
ENV PATH $PATH:$ORACLE_HOME/bin
ENV LD_LIBRARY_PATH /usr/lib/oracle/18.5/client64/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV TNS_ADMIN /usr/lib/oracle/18.5/client64/network/admin
ENV ORACLE_URL https://download.oracle.com/otn_software/linux/instantclient/185000/

RUN apt-get update && apt-get install alien git -y
RUN apt-get install libaio1 -y

RUN mkdir cdf-org-exporter
RUN wget ${ORACLE_URL}oracle-instantclient18.5-basic-18.5.0.0.0-3.x86_64.rpm --directory-prefix=cdf-org-exporter
RUN wget ${ORACLE_URL}oracle-instantclient18.5-devel-18.5.0.0.0-3.x86_64.rpm --directory-prefix=cdf-org-exporter
RUN wget ${ORACLE_URL}oracle-instantclient18.5-sqlplus-18.5.0.0.0-3.x86_64.rpm --directory-prefix=cdf-org-exporter
RUN wget ${ORACLE_URL}oracle-instantclient18.5-tools-18.5.0.0.0-3.x86_64.rpm --directory-prefix=cdf-org-exporter

RUN alien -i cdf-org-exporter/oracle-instantclient18.5-basic-18.5.0.0.0-3.x86_64.rpm
RUN alien -i cdf-org-exporter/oracle-instantclient18.5-sqlplus-18.5.0.0.0-3.x86_64.rpm
RUN alien -i cdf-org-exporter/oracle-instantclient18.5-devel-18.5.0.0.0-3.x86_64.rpm

RUN echo "/usr/lib/oracle/18.5/client64/lib/" >> /etc/ld.so.conf.d/oracle.conf && ldconfig

RUN apt-get remove alien -y
RUN rm -r cdf-org-exporter
# cleaning up unused files
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
   && rm -rf /var/lib/apt/lists/*
