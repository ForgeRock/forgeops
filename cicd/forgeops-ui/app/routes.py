import json


from flask import Response, request, send_from_directory


from app.lib.Deployment import Deployment
from app.lib.Forgeops import Forgeops
from app import app
from app.lib.ClusterController import ClusterController

controller = ClusterController()
forgeops = Forgeops()
deployment = Deployment(forgeops=forgeops, cluster=controller)

json_contenttype='application/json'


@app.route('/')
@app.route('/index')
def index():
    return send_from_directory('templates', 'index.html')


@app.route('/imgs/frlogo.png')
def logo():
    return send_from_directory('templates', 'frlogo.png')


@app.route('/deployment/default-config')
def get_default_config():
    """
    Gets a product configuration template
    """
    if request.method == 'GET':
        return response_builder(deployment.get_default_config(), status=200)
    else:
        return response_builder('{"error": "Method not allowed. Only GET allowed."}', status=405)


@app.route('/deployment/sample-config')
@app.route('/deployment/sample-config/<cfg_name>')
def example_configs(cfg_name=None):
    if cfg_name:
        return response_builder(forgeops.get_config(cfg_name))
    else:
        return response_builder(json.dumps({"configs": list(forgeops.sample_configs.keys())}))


@app.route('/deployment/current-config', methods=['GET', 'POST'])
def current_config():
    """
    Get's a configured product schema or sets a product configuration
    """
    if request.method == 'GET':
        return response_builder(deployment.get_current_config())
    elif request.method == 'POST':
        if str(request.headers.get('Content-Type')) != json_contenttype:
            return response_builder('{"error": "Unsupported content-type. Set Content-Type to application/json"}',
                                    status=415)
        deployment.set_config(request.data)
        print(response_builder('{"status": "Config successfully created"}', status=201))
        return response_builder('{"status": "Config successfully created"}', status=201)
    else:
        return response_builder('{"error": "Unsupported verb. Only GET & POST Allowed"}', status=405)


@app.route('/deployment/deploy', methods=['POST'])
def run_deployment():
    resp_code = 201

    out = deployment.deploy_products()
    if 'error' in out:
        resp_code = 500

    return response_builder(out, status=resp_code)


@app.route('/deployment/remove', methods=['POST'])
def delete_deployment():
    msg = deployment.remove_deployment()
    return response_builder(json.dumps({"status": msg}), status=200)


@app.route('/deployment/status')
def deployment_status():
    return response_builder(deployment.get_deployment_info())


@app.route('/deployment/pod-mapping')
def pod_mapping():
    return response_builder(deployment.get_product_pod_mapping())


@app.route('/deployment/endpoints')
def endpoints():
    return response_builder(deployment.get_product_endpoints())


@app.route('/deployment/status/<product_pod>')
def product_status(product_pod):
    return response_builder(deployment.get_pod_status(product_pod))


@app.route('/deployment/livecheck/<product>')
def product_livecheck(product):
    return response_builder(deployment.get_product_config_livecheck(product))


@app.route('/deployment/tests/run', methods=['POST', 'GET'])
def run_tests():
    if request.method == 'POST':
        return deployment.run_smoke_tests()
    else:
        return response_builder(deployment.get_smoke_test_status())


@app.route('/deployment/tests/results', methods=['GET'])
def get_latest_results():
    return deployment.get_latest_smoke_tests_results()


@app.route('/deplyment/repo', methods=['GET', 'POST', 'DELETE'])
def repo_ops():
    if request.method == 'GET':
        return response_builder(forgeops.get_current_repo())
    elif request.method == 'POST':
        reqdata = json.loads(request.data)
        if 'repo' not in reqdata.keys() or 'branch' not in reqdata.keys():
            return response_builder({'error': 'repo or branch missing'})
        return response_builder(forgeops.set_custom_repo(reqdata['repo'], reqdata['branch']))
    elif request.method == 'DELETE':
        return response_builder(forgeops.set_default_repo())
    else:
        response_builder({'error': 'Unknown error'})


# Helper methods
def response_builder(resp, status=200):
    headers = {"Content-Type": "application/json"}
    if 'error' in resp:
        status = 400
    return Response(resp, headers=headers, status=status)
