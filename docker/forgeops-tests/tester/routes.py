import os
import time
import threading
from flask import render_template, redirect, url_for, send_from_directory, jsonify, flash
from flask_login import current_user, login_user, login_required, logout_user
from tester import app, runner, forms, user
 
# only needed if we decide to implement the async runner
# from redis import Redis
# import rq


class PrefixMiddleware(object):

    def __init__(self, app, prefix=''):
        self.app = app
        self.prefix = prefix

    def __call__(self, environ, start_response):

        if environ['PATH_INFO'].startswith(self.prefix):
            environ['PATH_INFO'] = environ['PATH_INFO'][len(self.prefix):]
            environ['SCRIPT_NAME'] = self.prefix
            return self.app(environ, start_response)
        else:
            start_response('404', [('Content-Type', 'text/plain')])
            return ["This url does not belong to the app.".encode()]

if os.environ.get("INGRESS_PATH_PREFIX"):
    app.wsgi_app = PrefixMiddleware(app.wsgi_app, prefix="{}".format(os.environ.get("INGRESS_PATH_PREFIX")))

print("listening to path /{}".format(os.environ.get("INGRESS_PATH_PREFIX", "")))


@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = forms.LoginForm()
    if form.validate_on_submit():
        user_model = user.User()
        if user_model is None or not user_model.check_password(form.username.data, form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user_model, remember=form.remember_me.data)
        return redirect(url_for('index'))
    return render_template('login.html', title='Sign In', form=form)

@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('index'))


@app.route('/')
@app.route('/index')
@login_required
def index():
    return render_template('base.html', title='Forgeops Smoke Tests')

@app.route('/result', methods=['GET'])
@login_required
def result():
    if os.path.isfile(os.path.relpath(os.path.join(app.root_path, 'reports', 'latest.html'))):
        return send_from_directory('reports', 'latest.html', cache_timeout=0)
    else:
        print("not found", os.getcwd(), os.path.relpath(os.path.join('reports', 'latest.html')))
        text = "The test report is not ready yet.<br>This page will auto-refresh when the report is ready."
        with open(os.path.relpath(os.path.join(app.root_path, 'tester.log')), 'r') as f:
            return "<html><body><div><a><strong><br>{}<br><pre>{}</pre></strong></a></div></body></html>".format(text, f.read())

@app.route('/runtests', methods=['POST', 'GET'])
@app.route('/run', methods=['POST', 'GET'])
@login_required
def runTests():
    # flash('Processing Request...')
    #This is a blocking call during the request. This is a terrible/temporary hack. 
    #It is better to use a queue for a background processes and just submit to the queue.
    # queue = rq.Queue('test-runner', connection=Redis.from_url('redis://'))
    # job = queue.enqueue('tester.runner.run', "tests/smoke")

    if app.tr.isAlive():
        return "Tests are already running", 409
    try:
        # time.sleep(10)
        app.tr = threading.Thread(target=runner.run, args=("tests/smoke", ), daemon=True)
        app.tr.start()
        # runner.run("tests/smoke")
    except Exception as e:
        return "Something went wrong: {}".format(e), 500

    return redirect(url_for('index'))

@app.route("/scripts_js")
def scripts_js():
    return render_template("/js/scripts.js")

@app.route('/status', methods=['GET'])
def status():
    if current_user.is_authenticated:
        busy = app.tr.isAlive()
    #always return true for anonymous  users
    else:
        busy = True
    return jsonify({"busy": busy}), 200

@app.route('/healthz', methods=['GET'])
def healthz():
    return jsonify({"status":"OK"}), 200