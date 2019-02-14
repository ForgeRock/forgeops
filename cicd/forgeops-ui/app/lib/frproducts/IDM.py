from logging import INFO, ERROR

from requests import get

from app.lib.frproducts.FRProduct import FRProduct


class IDM(FRProduct):
    _chart_name = 'openidm'

    def __init__(self, instance_name):
        super().__init__(chart_name=self._chart_name, instance_name=instance_name)

    def set_livecheck_url(self):
        self.livecheck_url = self.namespace + '.iam' + self.domain + '/idm/'

    def livecheck(self):
        self.logger.log(INFO, 'Running ' + self.__class__.__name__ + ' livecheck')
        self.logger.log(INFO, 'Livecheck to ' + self.livecheck_url)
        headers = {'X-OpenIDM-Username': 'openidm-admin', 'X-OpenIDM-Password': 'openidm-admin'}
        r = get(url='https://' + self.livecheck_url, verify=False, headers=headers)
        self.logger.log(INFO, 'Livecheck status code: ' + str(r.status_code))
        if r.status_code is 200:
            self.logger.log(INFO, 'Livecheck successful')
            return True
        else:
            return False
