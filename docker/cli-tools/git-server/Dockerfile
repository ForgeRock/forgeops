FROM nginxinc/nginx-unprivileged:stable

USER root
ENV DEBIAN_FRONTEND=noninteractive                           
ENV APT="apt-get --no-install-recommends --yes"                 
RUN $APT update \
        && $APT upgrade \
        && $APT install git spawn-fcgi fcgiwrap \
        && mkdir -p /srv/run \
        && mkdir -p /srv/git/helloworld.git \
        && touch /srv/run/.htpasswd \
        && GIT_DIR=/srv/git/helloworld.git git init --bare --shared \
        && chown -R nginx:nginx /srv/ \
        && rm /etc/nginx/conf.d/default.conf \
        && apt-get clean \                                   
        && rm -r /var/lib/apt/lists /var/cache/apt/archives  

USER nginx
COPY git.conf /etc/nginx/conf.d/git.conf
COPY entrypoint.sh /srv/run/entrypoint.sh
ENTRYPOINT /srv/run/entrypoint.sh
