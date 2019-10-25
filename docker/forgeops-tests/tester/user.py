import os
import random
import time
from flask_login import UserMixin
from tester import login


#simple, single user model. Need an actual user handler here 
class User(UserMixin):

    def __init__(self):
        self.id = os.environ.get("SMOKETESTS_USER", "admin")
        self.password = os.environ.get("SMOKETESTS_PASSWORD", "password")
    
    def check_password(self, form_user, form_password):
        valid = (self.id == form_user) & (self.password == form_password) 
        time.sleep(1.0/random.randint(1, 20)) #wait random amount up to 1 sec
        return valid
        
    def __repr__(self):
        return "{} {}".format(self.id, self.password)

@login.user_loader
def load_user(id):
    return User()