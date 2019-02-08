# Lib imports
from requests import get, post, put, delete, session
from kubernetes import client, config, stream
from kubernetes.client import Configuration
from kubernetes.client.rest import ApiException
from kubernetes.stream import stream
from pprint import pprint

# Framework imports
# from ProductConfig import IDMConfig
# from utils import logger, rest


class TestMilestoneValidation(object):

    def list_idm_objects(self):
        # Configs can be set in Configuration class directly or using helper utility
        config.load_kube_config()

        v2 = client.AppsV1beta2Api()

        # create an instance of the API class
        namespace = 'markg'
        include_uninitialized = True
        pretty = True
        # _continue = '_continue_example' # str | The continue option should be set when retrieving more results from the server. Since this value is server defined, kubernetes.clients may only use the continue value from a previous query result with identical query parameters (except for the value of continue) and the server may reject a continue value it does not recognize. If the specified continue value is no longer valid whether due to expiration (generally five to fifteen minutes) or a configuration change on the server, the server will respond with a 410 ResourceExpired error together with a continue token. If the kubernetes.client needs a consistent list, it must restart their list without the continue field. Otherwise, the kubernetes.client may send another list request with the token received with the 410 error, the server will respond with a list starting from the next key, but from the latest snapshot, which is inconsistent from the previous list results - objects that are created, modified, or deleted after the first list request will be included in the response, as long as their keys are after the \"next key\".  This field is not supported when watch is true. Clients may start a watch from the last resourceVersion value returned by the server and not miss any modifications. (optional)
        # field_selector = 'field_selector_example' # str | A selector to restrict the list of returned objects by their fields. Defaults to everything. (optional)
        # label_selector = 'label_selector_example' # str | A selector to restrict the list of returned objects by their labels. Defaults to everything. (optional)
        # limit = 56 # int | limit is a maximum number of responses to return for a list call. If more items exist, the server will set the `continue` field on the list metadata to a value that can be used with the same initial query to retrieve the next set of results. Setting a limit may return fewer than the requested amount of items (up to zero items) in the event all requested objects are filtered out and kubernetes.clients should only use the presence of the continue field to determine whether more results are available. Servers may choose not to support the limit argument and will return all of the available results. If limit is specified and the continue field is empty, kubernetes.clients may assume that no more results are available. This field is not supported if watch is true.  The server guarantees that the objects returned when using continue will be identical to issuing a single list call without a limit - that is, no objects created, modified, or deleted after the first request is issued will be included in any subsequent continued requests. This is sometimes referred to as a consistent snapshot, and ensures that a kubernetes.client that is using limit to receive smaller chunks of a very large result can ensure they see all possible objects. If objects are updated during a chunked list the version of the object that was present at the time the first list result was calculated is returned. (optional)
        # resource_version = 'resource_version_example' # str | When specified with a watch call, shows changes that occur after that particular version of a resource. Defaults to changes from the beginning of history. When specified for list: - if unset, then the result is returned from remote storage based on quorum-read flag; - if it's 0, then we simply return what we currently have in cache, no guarantee; - if set to non zero, then the result is at least as fresh as given rv. (optional)
        timeout_seconds = 56 # int | Timeout for the list/watch call. This limits the duration of the call, regardless of any activity or inactivity. (optional)

        try:
            api_response = v2.list_namespaced_stateful_set(namespace,
                                                                     include_uninitialized=include_uninitialized,
                                                                     pretty=pretty, timeout_seconds=timeout_seconds)
            pprint(api_response)
        except ApiException as e:
            print("Exception when calling AppsV1beta2Api->list_namespaced_stateful_set: %s\n" % e)

    def test_idm_objects(self):
        self.list_idm_objects()

    def test_list_pods(self):
        # Load the kubeconfig file from $HOME/.kube/config
        config.load_kube_config()

        # Instantiate class CoreV1Api to access V1 version of Kubernetes core API objects
        v1 = client.CoreV1Api()

        print("Listing pods with their IPs:")
        ret = v1.list_pod_for_all_namespaces(watch=False)
        for i in ret.items:
            print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))

    def test_pod_exec(self):
        # Load the kubeconfig file from $HOME/.kube/config
        config.load_kube_config()

        # Instantiate class CoreV1Api to access V1 version of Kubernetes core API objects
        v1 = client.CoreV1Api()

        # calling exec and wait for response.
        exec_command = [
            'java',
            '-version'
        ]

        resp = stream(v1.connect_get_namespaced_pod_exec, 'markg-openidm-openidm-0', 'markg',
                      command=exec_command, container='openidm',
                      stderr=True, stdin=True,
                      stdout=True, tty=True, _request_timeout=30)

        print("Response: " + resp)