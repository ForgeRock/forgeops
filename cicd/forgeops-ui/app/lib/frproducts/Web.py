from app.lib.frproducts.FRProduct import FRProduct


class Web(FRProduct):
    _chart_name = 'web'

    def __init__(self, instance_name):
        super().__init__(chart_name=self._chart_name, instance_name=instance_name)
