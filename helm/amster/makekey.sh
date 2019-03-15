#!/bin/sh
# Make SSH key pairs to be used for Amster authentication.
# We pre-create the RSA key pair so that we can mount a known authorizedkey on the OpenAM pod.
# The key alias is not significant to Amster - as long as the private key and authorizedkey (public) match
# up, the alias can be anything.
# added -m PEM because ssh-keygen on mac doesn't create PEM format by default.
ssh-keygen -t rsa -b 4096 -m PEM -C "openam-install@example.com" -f secrets/id_rsa

# This is just copied as amster also requires a copy of the authorized_keys
cp secrets/id_rsa.pub ../openam/secrets/authorized_keys

# If you want to tighten up the authorized_keys to an IP range-, use a from option instead:
#key=`cat secrets/id_rsa.pub`
#echo "\"from=\"127.0.0.0/24,::1\" $key"   >secrets/authorized_keys
#rm secrets/id_rsa.pub
