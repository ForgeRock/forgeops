from frproducts.DS import DS
from Forgeops import Forgeops
from ClusterController import ClusterController
from frproducts.AM import AM
from frproducts.IG import IG
from frproducts.IDM import IDM
import json

if __name__ == '__main__':
    """
    Entry point for testing lib libraries
    """
    fo = Forgeops()
    cc = ClusterController()

    am = AM(namespace='smoke', domain='forgeops.com')
    ig = IG(namespace='smoke', domain='forgeops.com')
    idm = IDM(namespace='smoke', domain='forgeops.com')
    ds = DS(namespace='smoke', domain='forgeops.com')

    print('=============AM==============')
    print(json.dumps(am.load_yaml(), sort_keys=True, indent=2, separators=(',', ': ')))
    print('=============DS===============')
    print(json.dumps(ds.load_yaml(), sort_keys=True, indent=2, separators=(',', ': ')))
    print('=============IDM==============')
    print(json.dumps(idm.load_yaml(), sort_keys=True, indent=2, separators=(',', ': ')))
    print('=============IG===============')
    print(json.dumps(ig.load_yaml(), sort_keys=True, indent=2, separators=(',', ': ')))
