import importlib.util
import pathlib

forgeops_dependencies_path = pathlib.Path(__file__).parent.joinpath('../../lib/python/forgeops_dependencies.py')
forgeops_dependencies_spec = importlib.util.spec_from_file_location('forgeops_dependencies', forgeops_dependencies_path)
forgeops_dependencies = forgeops_dependencies_spec.loader.load_module()
