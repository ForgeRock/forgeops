#!/usr/bin/python3
"""
Simple UI for deploy.sh script. 
"""
from tkinter import *
from tkinter import ttk
from tkinter import scrolledtext

from threading import Thread
from queue import Queue, Empty

import time
import shutil
import os
import subprocess

from subprocess import PIPE
from yaml import dump

class ForgeopsGUI(object):

    def __init__(self):
        # Root window definition
        self._root = Tk()
        self._root.geometry('800x825')
        self._root.title('Forgeops UI')
        
        # Vars & globally accessible UI parts
        self.check_btns_state = None
        self.check_btns = None
        self.product_textbox_input = None
        self.product_textbox_input_val = None
        self.deploy_button = None
        self.cleanup_button = None
        self.terminal_output = None
        self.domain_input_var = None
        self.namespace_input_var = None
        self.product_list = ['openam', 'openidm', 'openig', 'userstore', 'configstore', 'ctsstore']
        self.frconfig_git_repo = StringVar()
        self.frconfig_git_branch = StringVar()
        self.text_output = None
        self.deploy_process = None
        self.subqueue = None
        self.deploy_process = None

        self.domain_text_field = None
        self.git_repo_text_field = None
        self.namespace_text_field = None
        self.git_branch_text_field = None

        # Path related things
        self.forgeops_path=os.path.dirname(os.path.abspath(__file__))
        self.config_folder=os.path.join(self.forgeops_path, 'config-deploy')

    # UI design 

    def run(self):

        select_frame = Frame(self._root)
        select_frame.grid(column=0, row=1, pady=10, padx=10, sticky=(W, E, S, N))

        select_frame.columnconfigure(0, weight=0)
        select_frame.rowconfigure(0, weight=0)
       

        terminal_frame = Frame(self._root)
        terminal_frame.grid(column=0, row=2, pady=10, padx=10, sticky=(W, E, S, N))

        Label(select_frame, text='Forgeops product deployment', font=('Arial', 16), pady=10).grid(column=0, row=1)
        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=2, columnspan=5, sticky='we')

        Label(select_frame, text='Select products to deploy', font=('Arial', 12)).grid(row=3, column=0, sticky='w')
        Label(select_frame, text='Config path', font=('Arial', 12)).grid(row=3, column=1, sticky='w')

        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=4, columnspan=5, sticky='w')

        self.check_btns_state = {}
        self.check_btns = {}
        self.product_textbox_input = {}
        self.product_textbox_input_val = {}
        i = 5

        for product in self.product_list:
            self.check_btns_state[product] = BooleanVar()
            self.check_btns_state[product].set(False)
            self.check_btns[product] = Checkbutton(select_frame, text=product,
                                                   var=self.check_btns_state[product])
            self.check_btns[product].grid(row=i, column=0, sticky=W)

            if product in ['openam', 'openidm', 'openig']:
                self.product_textbox_input_val[product] = StringVar()
                self.product_textbox_input[product] = \
                    Entry(select_frame,
                          textvariable=self.product_textbox_input_val[product], width=50).grid(row=i, column=1)
            i += 1

        self.product_textbox_input_val['openam'].set('/git/config/6.5/smoke-tests/am/')
        self.product_textbox_input_val['openidm'].set('/git/config/6.5/smoke-tests/idm/')
        self.product_textbox_input_val['openig'].set('/git/config/6.5/default/ig/basic-sample')

        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=i, columnspan=5, sticky='we')
        i += 1

        Label(select_frame, text='Global settings', font=('Arial', 12), pady=10).grid(row=i, column=0, sticky=W)
        self.deploy_button = Button(select_frame, text='Deploy', command=self.deploy)
        self.cleanup_button = Button(select_frame, text='Remove deployment', command=self.delete_deployment, state=DISABLED)
       
        i += 1
        Label(select_frame, text='Domain').grid(row=i, column=0, sticky=W)
        self.domain_input_var = StringVar()
        self.domain_input_var.set('forgeops.com')
        self.domain_text_field = Entry(select_frame, textvariable=self.domain_input_var, width=50)
        self.domain_text_field.grid(row=i, column=1, sticky=W)

        i += 1
        Label(select_frame, text='Namespace').grid(row=i, column=0, sticky=W)
        self.namespace_input_var = StringVar()
        self.namespace_input_var.set('pavel')
        self.namespace_text_field = Entry(select_frame, textvariable=self.namespace_input_var, width=50)
        self.namespace_text_field.grid(row=i, column=1, sticky=W)

        i += 1
        Label(select_frame, text='Product config git repository').grid(row=i, column=0, sticky=W)
        self.frconfig_git_repo.set('https://github.com/ForgeRock/forgeops-init')
        self.git_repo_text_field = Entry(select_frame, textvariable=self.frconfig_git_repo, width=50)
        self.git_repo_text_field.grid(row=i, column=1, sticky=W)

        i += 1
        Label(select_frame, text='Product config git branch').grid(row=i, column=0, sticky=W)
        self.frconfig_git_branch.set('master')
        self.git_branch_text_field = Entry(select_frame, textvariable=self.frconfig_git_branch, width=50)
        self.git_branch_text_field.grid(row=i, column=1, sticky=W)

        i += 1
        self.deploy_button.grid(row=i, column=0, sticky=W)
        i += 1
        self.cleanup_button.grid(row=i, column=0, sticky=W)
        
        i += 1
        self.terminal_output = scrolledtext.ScrolledText(terminal_frame)
        self.terminal_output.grid(row=1, sticky=S)
        self._root.mainloop()
        
    # Deploy process related methods

    def set_inputs_state(self, state):
        self.git_branch_text_field.config(state=state)
        self.git_repo_text_field.config(state=state)
        self.domain_text_field.config(state=state)
        self.namespace_text_field.config(state=state)

    def delete_deployment(self):
        print('Removing...')
        self.deploy_process = subprocess.Popen([self.forgeops_path + '/remove-all.sh', '-N', self.namespace_input_var.get()], 
            stdout=PIPE, bufsize=1)
        self.subqueue = Queue()
        t = Thread(target=self.get_output_nonblocking, args=(self.deploy_process.stdout, self.subqueue))
        t.daemon = True 
        t.start() 

    def deploy(self):
        self.generate_product_yaml()
        self.deploy_button.config(state=DISABLED)
        self.set_inputs_state(DISABLED)

        print('Deploying...')
        self.deploy_process = subprocess.Popen([self.forgeops_path + '/deploy.sh', self.config_folder], 
            stdout=PIPE, bufsize=1)
        self.subqueue = Queue()
        t = Thread(target=self.get_output_nonblocking, args=(self.deploy_process.stdout, self.subqueue))
        t.daemon = True 
        t.start() 
        
    def get_output_nonblocking(self, out, queue):
        while 1:
            poll = self.deploy_process.poll()
            if poll is None:
                for line in iter(out.readline, b''):
                    self.terminal_output.insert('1.0', line)
            else:
                break     

        if self.cleanup_button['state'] == NORMAL:
            self.deploy_button.config(state=NORMAL)
            self.cleanup_button.config(state=DISABLED)
            
            self.set_inputs_state(NORMAL)
        else:
            self.deploy_button.config(state=DISABLED)
            self.cleanup_button.config(state=NORMAL)
        
        out.close()

    # Product deployment configuration methods

    def generate_product_yaml(self):
        try:
            shutil.rmtree(self.config_folder, ignore_errors=True)
        except FileNotFoundError:
            pass

        os.mkdir(self.config_folder)

        # frconfig chart must be included
        products = '( frconfig'

        for p in self.check_btns_state.keys():
            if self.check_btns_state[p].get():
                products += ' ' + p + ' '
                if p is 'openam':
                    products += ' amster '
                if p is 'openidm':
                    products += ' postgres-openidm '

        products += ')'

        self.am_config_gen()
        self.ig_config_gen()
        self.idm_config_gen()
        self.ds_config_gen()

        with open(os.path.join(self.config_folder, 'env.sh'), 'w') as f:
            f.write('DOMAIN="' + self.domain_input_var.get() + '"\n')
            f.write('NAMESPACE="' + self.namespace_input_var.get() + '"\n')
            f.write('COMPONENTS=' + products)

        with open(os.path.join(self.config_folder, 'common.yaml'), 'w') as f:
            dump({'domain': '.' + self.domain_input_var.get()}, f, default_flow_style=False)    

    def ds_config_gen(self):
        userstore_filename = 'userstore.yaml'
        configstore_filename = 'configstore.yaml'
        ctsstore_filename = 'ctsstore.yaml'

        userstore = {'instance': 'userstore'}
        configstore = {'instance': 'configstore'}
        ctsstore = {'instance': 'ctsstore'}

        with open(os.path.join(self.config_folder, userstore_filename), 'w') as f:
            dump(userstore, f, default_flow_style=False)
        with open(os.path.join(self.config_folder, configstore_filename), 'w') as f:
            dump(configstore, f, default_flow_style=False)
        with open(os.path.join(self.config_folder, ctsstore_filename), 'w') as f:
            dump(ctsstore, f, default_flow_style=False)

    def am_config_gen(self):
        amster_filename = 'amster.yaml'
        openam_filename = 'openam.yaml'

        amster = {'config': {'claim': 'frconfig', 'importPath': self.product_textbox_input_val['openam'].get()}}
        openam = {'image': {'pullPolicy': 'Always'}}

        with open (os.path.join(self.config_folder, amster_filename), 'w') as f:
            dump(amster, f, default_flow_style=False)
        with open(os.path.join(self.config_folder, openam_filename), 'w') as f:
            dump(openam, f, default_flow_style=False)

    def idm_config_gen(self):
        idm_filename = 'openidm.yaml'
        idm = {'config': {'path': self.product_textbox_input_val['openidm'].get()}}

        with open (os.path.join(self.config_folder, idm_filename), 'w') as f:
            dump(idm, f, default_flow_style=False)

    def ig_config_gen(self):
        ig_filename = 'openig.yaml'
        ig = {'config': {'path': self.product_textbox_input_val['openig'].get()}}

        with open (os.path.join(self.config_folder, ig_filename), 'w') as f:
            dump(ig, f, default_flow_style=False)


if __name__ == "__main__":
    gui = ForgeopsGUI()
    gui.run()
