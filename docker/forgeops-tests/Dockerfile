FROM gcr.io/engineering-devops/python-test:latest
# The config below has been moved to a base image to speed development. The base image is in forgeops/cicd/python-test
# FROM python:3-slim

#WORKDIR /usr/src/app
# RUN apt update && apt install -y netcat-openbsd chromedriver
# RUN pip install --no-cache-dir pytest allure-pytest pytest-html pytest-metadata requests kubernetes beautifulsoup4 pyyaml prettytable selenium
# ENV PYTHONUNBUFFERED=1
COPY . .
RUN export PYTHONPATH=$PYTHONPATH:$(pwd)
