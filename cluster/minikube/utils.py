import importlib.util
import pathlib

utils_path = pathlib.Path(__file__).parent.joinpath('../../bin/utils.py')
utils_spec = importlib.util.spec_from_file_location('utils', utils_path)
utils = utils_spec.loader.load_module()
