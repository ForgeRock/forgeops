from tester import app

if __name__ == '__main__':
   app.run(host="0.0.0.0",
            port="5000",
            debug=False,
            use_reloader=False,
            use_debugger=False)
