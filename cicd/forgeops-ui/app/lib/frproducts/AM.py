from logging import INFO, ERROR

from app.lib.frproducts.FRProduct import FRProduct
from app.lib.log import get_logger
from requests import get


class AM(FRProduct):
    _chart_name = 'openam'

    def __init__(self, instance_name):
        super().__init__(chart_name=self._chart_name, instance_name=instance_name)
        self.url = None
        self.livecheck_url = self.url
        self.logger = get_logger(self.__class__.__name__)

    def set_livecheck_url(self):
        self.livecheck_url = self.namespace + '.iam' + self.domain + '/am/'

    def livecheck(self):
        self.logger.log(INFO, 'Running ' + self.__class__.__name__ + ' livecheck')
        self.logger.log(INFO, 'Livecheck to ' + self.livecheck_url)

        r = get(url='https://' + self.livecheck_url, verify=False)
        self.logger.log(INFO, 'Livecheck status code: ' + str(r.status_code))
        if r.status_code is 200:
            self.logger.log(INFO, 'Livecheck successful')
            return '{"status": "ready"}'
        else:
            return '{"status": "not ready"}'
