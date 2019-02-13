from app.lib.frproducts.FRProduct import FRProduct


class DS(FRProduct):
    _chart_name = 'ds'

    def __init__(self, instance_name):
        super().__init__(chart_name=self._chart_name, instance_name=instance_name)

