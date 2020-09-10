FROM python:3.8-buster

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

# Configure timezone
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN /usr/local/bin/python -m pip install --upgrade pip

RUN apt-get update \
  # dependencies for building Python packages
  && apt-get install -y build-essential \
  # psycopg2 dependencies
  && apt-get install -y libpq-dev \
  # UML database diagram dependencies
  && apt-get install -y graphviz \
  # Translations dependencies
  && apt-get install -y gettext \
  # Git with Vim and Nano editors
  && apt-get install -y git git-lfs vim nano \
  && apt-get install -y nodejs npm
# cleaning up unused files
# && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
# && rm -rf /var/lib/apt/lists/*

# Setting up node dependencies

RUN npm install -g yarn elasticdump

# Requirements are installed here to ensure they will be cached.
COPY ./requirements /requirements
RUN pip install -r /requirements/local.txt

RUN apt-get update && apt-get install alien git -y
RUN apt-get install libaio1 -y
