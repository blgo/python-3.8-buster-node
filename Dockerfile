FROM python:3.8-buster as build-python-stage

RUN apt-get update \
  && apt-get -y upgrade \ 
  # dependencies for building Python packages
  && apt-get install -y build-essential \
  # psycopg2 dependencies
  && apt-get install -y libpq-dev \
  # Django UML models diagram and pygraphviz dependencies
  && apt-get install -y graphviz libgraphviz-dev \
  # Translations dependencies
  && apt-get install -y gettext

ADD ./requirements/production.txt /requirements/
ADD ./requirements/base.txt /requirements/
RUN pip install --prefix="/install" --no-warn-script-location \
  -r /requirements/production.txt \
  && rm -rf /requirements

###
# Main stage
###

FROM python:3.8-slim-buster as main

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ENV DEBIAN_FRONTEND=noninteractive

# Configure timezone
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
  libpq5 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build-python-stage /install /usr/local
