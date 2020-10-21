FROM python:3.9-slim

RUN useradd -s /usr/sbin/nologin \
            --create-home \
            --home-dir /opt/app \
            app

COPY --chown=app:app . /opt/app
RUN echo "PATH=$PATH:$HOME/.local/bin" >> $HOME/.bashrc \
        && cd /opt/app \
            && pip install .
USER app
ENTRYPOINT ["bash", "-c"]
WORKDIR /opt/app
CMD ["exec gunicorn --bind :$PORT --timeout 900 --workers 1 --threads 1 pruner.run:app"]
