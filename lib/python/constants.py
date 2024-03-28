import os
from pathlib import Path

file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_dir = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]

FORGEOPS_SCRIPT_DIR = os.path.join(root_dir, 'bin', 'commands')
DEPENDENCIES_DIR = os.path.join(root_dir, 'lib', 'dependencies')
REQUIREMENTS_FILE = os.path.join(root_dir, 'lib', 'python', 'requirements.txt')

FORGEOPS_SCRIPT_FILE = os.path.join(root_dir, 'bin', 'forgeops-ng')
ENV_FILE = os.path.join(FORGEOPS_SCRIPT_DIR, 'env')
CONFIGURED_VERSION_FILE = os.path.join(DEPENDENCIES_DIR, '.configured_version')
