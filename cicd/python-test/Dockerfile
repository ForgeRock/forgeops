FROM python:3-slim

WORKDIR /usr/src/app
#RUN apt update && apt install -y netcat-openbsd chromedriver
RUN apt update && apt install -y netcat-openbsd curl

RUN pip3 install --no-cache-dir pytest allure-pytest pytest-html pytest-metadata requests kubernetes beautifulsoup4 pyyaml prettytable flask flask-login flask-wtf flask-bootstrap gunicorn

ENV PYTHONUNBUFFERED=1
