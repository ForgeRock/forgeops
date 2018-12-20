# Dockerfile for building gatling image with benchmark Tests
FROM denvazh/gatling:2.3.1

# In case of you want to add custom Gatling libraries
# make sure you you add them to image and copy to apropriate place
# RUN cp /ldap-plugin/* /opt/gatling/lib/

# Using custom Gatling startup scripts for easier passing of variables
# through Helm charts
COPY custom-gatling.sh /custom-gatling.sh
RUN chmod +x /custom-gatling.sh

ENTRYPOINT ["/custom-gatling.sh"]
CMD [""]
