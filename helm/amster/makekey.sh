#!/bin/sh
# Make SSH key pairs to be used for Amster authentication.
# We pre-create the RSA key pair so that we can mount a known authorizedkey on the OpenAM pod.
# The key alias is not signifcant to Amster - as long as the private key and authorizedkey (public) match
# up, the alias can be anything.
ssh-keygen -t rsa -b 4096 -C "openam-install@example.com" -f secrets/id_rsa

mv secrets/id_rsa.pub secrets/authorized_keys

# The runtime needs the same secret if you want to use Amster.
cp secrets/*  ../openam/secrets

# If you want to tighten up the authorized_keys to an IP range-, use a from option instead:
#key=`cat secrets/id_rsa.pub`
#echo "\"from=\"127.0.0.0/24,::1\" $key"   >secrets/authorized_keys
#rm secrets/id_rsa.pub
