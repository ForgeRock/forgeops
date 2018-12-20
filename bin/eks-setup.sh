#!/usr/bin/env bash

# install packages
sudo yum update -y && sudo yum install git docker -y

# install AWS kubectl
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/

# install Helm

curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

# install aws-iam-authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mv ./aws-iam-authenticator /usr/local/bin

# install pip
pip install --upgrade pip
# https://stackoverflow.com/questions/26302805/pip-broken-after-upgrading
hash -r
pip install --upgrade awscli
