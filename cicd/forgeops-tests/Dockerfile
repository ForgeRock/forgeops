# Dockerfile with dependencies for forgeops-tests
FROM python:3.5-alpine

RUN apk add --no-cache bash

RUN pip3 install pytest
RUN pip3 install allure-pytest
RUN pip3 install pytest-html
RUN pip3 install pytest-metadata
RUN pip3 install requests
RUN pip3 install beautifulsoup4
