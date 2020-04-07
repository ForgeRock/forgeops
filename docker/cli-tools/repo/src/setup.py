"""setup - setuptools based setup"""

from setuptools import setup
__version__ = '0.1.0'

setup(name='forgeops',
      version=__version__,
      description='forgeops repo tools',
      author='Max Resnick',
      author_email='max.resnick@forgerock.com',
      url='http://stash.forgerock.org/scm/cloud/forgeops.git',
      license="CDDL",
      py_modules=['forgeops'],
      packages=[],
      install_requires=['gitchangelog', 'requests', 'mako'],
      entry_points = {
          'console_scripts': ['forgeops=forgeops:main'],
      },
      classifiers=[
          'Development Status :: 3 - Alpha',
          'Intended Audience :: Developers',
          'License :: OSI Approved :: COMMON DEVELOPMENT AND DISTRIBUTION LICENSE (CDDL)',
          'Natural Language :: English',
          'Operating System :: OS Independent',
          'Programming Language :: Python',
          'Topic :: Software Development :: Libraries',
          'Topic :: Utilities'])

