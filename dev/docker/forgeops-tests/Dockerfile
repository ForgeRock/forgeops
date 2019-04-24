FROM python:3-slim

WORKDIR /usr/src/app
RUN apt update && apt install -y netcat-openbsd
RUN pip install --no-cache-dir pytest allure-pytest pytest-html pytest-metadata requests kubernetes beautifulsoup4 pyyaml prettytable
ENV PYTHONUNBUFFERED=1
COPY . .
RUN chmod +x run-tests.sh