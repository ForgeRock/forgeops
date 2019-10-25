from flask import Flask
from flask_login import LoginManager
from flask_bootstrap import Bootstrap
from tester import runner
import logging
import os 
import threading

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get("FLASK_SECRET_KEY", "you-need-to-provide-one-dont-use-this-in-production")
app.logger = logging.getLogger("flask_app")


if app.debug:
    app.logger.setLevel(logging.DEBUG)
else:
    app.logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
app.logger.addHandler(ch)

fl = logging.FileHandler(os.path.abspath(os.path.join('tester', 'tester.log')), "w+")
fl.setLevel(logging.INFO)
fl.setFormatter(formatter)
app.logger.addHandler(fl)

app.logger.info("Starting server")

app.tr = threading.Thread(target=runner.run, args=("tests/smoke", True), daemon=True)
app.tr.start()

login = LoginManager(app)
bootstrap = Bootstrap(app)
login.login_view = 'login'

#Import done last to avoid recursive imports
from tester import routes