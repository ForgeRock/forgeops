# Dockerfile for building gatling image with benchmark Tests
FROM denvazh/gatling:2.2.1

# TODO - Discuss if this is needed now.
# ADD http://abondance.internal.forgerock.com/pkg/clients/gatling/ext/ldap/gatling-ldap-full-0.0.4-SNAPSHOT.zip /
# RUN mkdir /ldap-plugin
# RUN unzip /gatling-ldap-full-0.0.4-SNAPSHOT.zip -d /ldap-plugin

#RUN cp /ldap-plugin/* /opt/gatling/lib/
# Add local files

COPY custom-gatling.sh /custom-gatling.sh
RUN chmod +x /custom-gatling.sh
COPY ../../samples/simulations /opt/gatling/user-files/

ENTRYPOINT ["/custom-gatling.sh"]
CMD [""]
