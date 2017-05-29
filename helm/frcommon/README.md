# Common chart functions


This chart is not deployed directly. It contains common _partial template functions that 
are referenced by other charts. 

Note that currently we trick helm into packaging the _utils.tpl by creating a symbolic link to it:

cd opendj/templates
ln -s ../../frcommon/templates/_utils.tpl

This is done for expediency in developing the frcommon chart, so we do need to republish every time a change is made.

When the frcommon chart stablizes, the proper way to package this will be used, which is to create a dependency 
in requirements.yaml.

