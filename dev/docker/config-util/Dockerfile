FROM python:3-slim

WORKDIR /usr/src/app
RUN pip install --no-cache-dir requests
ENV PYTHONUNBUFFERED=1
COPY . . 
