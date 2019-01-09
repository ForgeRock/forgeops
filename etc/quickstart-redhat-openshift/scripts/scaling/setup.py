from setuptools import setup

setup_options = dict(
    name="aws-ose-qs-scale", 
    version="1.0",
    description="Scripts to facilitate scaling of the AWS OpenShift Quickstart",
    url="https://github.com/aws-quickstart/quickstart-redhat-openshift",
    author="AWS QuickStart Team",
    license="Apache 2.0", 
    packages=['aws_openshift_quickstart'],
    zip_safe=False,
    extras_require={
      ':python_version=="2.6"': ['argparse>=1.1']
    },
     
    classifiers=(
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'Natural Language :: English',
        'License :: OSI Approved :: Apache Software License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7'
        ),
    scripts=['bin/aws-ose-qs-scale']
    )


setup(**setup_options)
