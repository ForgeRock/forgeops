#!/usr/bin/env python3
"""
This is a sample front end to the deploy.sh script. It is not supported by ForgeRock.
"""
from tkinter import *
from tkinter import ttk
from tkinter import scrolledtext, messagebox

from threading import Thread
from queue import Queue

import shutil
import os
import subprocess

from subprocess import PIPE
try:
    from yaml import dump
except ImportError:
    print("Pyyaml package is not installed. Run 'pip3 install pyyaml' to install it.")


class ForgeopsGUI(object):

    def __init__(self):
        # Root window definition
        self._root = Tk()
        self._root.geometry('1015x825')
        self._root.title('Forgeops deployer UI')

        # Vars & globally accessible UI parts
        self.check_btns_state = {}
        self.check_btns = {}

        # Product image vars
        self.product_textbox_input = {}
        self.product_textbox_input_val = {}
        self.product_image_textbox_input = {}
        self.product_image_textbox_val = {}
        self.product_image_tag_textbox_input = {}
        self.product_image_tag_textbox_input_val = {}
        self.product_image_check_btn = {}
        self.product_image_check_btn_val = {}

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
        self.forgeops_path = os.path.dirname(os.path.abspath(__file__))
        self.config_folder = os.path.join(self.forgeops_path, 'config-deploy')

        # Misc
        self.init_message = """
        Experimental UI for deploying Forgerock products into cloud. It's not supported by Forgerock. Use with caution.

        Prerequisites:
            This utility expects following conditions to be met:
                - Have connection to cluster setup
                - Have kubectl, helm, kubens binaries setup and in the PATH
        Usage:
            Select products which you want to deploy. If you want to use custom image and tag, please check override
            and provide custom image and tag. If you are deploying openam, remember you need to deploy
            userstore/ctsstore/configstore based on configuration you are going to provide to this product.

            Once products are selected, you can proceed to deploy products. Utility doesn't save existing deployment
            anywhere. If you quit utility before cleaning up namespace, products will stay in cloud.

        WARNING: Remove deployment button will delete whole namespace with persistent volumes. Be careful
        """

    # UI design

    def run(self):
        select_frame = Frame(self._root)
        select_frame.grid(column=0, row=1, pady=10, padx=10, sticky=(W, E, S, N))

        select_frame.columnconfigure(0, weight=0)
        select_frame.rowconfigure(0, weight=0)

        terminal_frame = Frame(self._root)
        terminal_frame.grid(column=0, columnspan=5, row=2, pady=10, padx=10, sticky=(W, E, S, N))

        menubar = Menu(self._root)
        filemenu = Menu(menubar, tearoff=0)
        filemenu.add_command(label='About', command=self.about_dialog)
        filemenu.add_command(label='Exit', command=self.exit_gui)
        menubar.add_cascade(label='File', menu=filemenu)

        self._root.config(menu=menubar)

        Label(select_frame, text='Forgeops product deployment', font=('Arial', 16), pady=10).grid(column=0, row=1)
        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=2, columnspan=6, sticky='we')

        Label(select_frame, text='Select products to deploy', font=('Arial', 10)).grid(row=3, column=0, sticky='w')
        Label(select_frame, text='Config path', font=('Arial', 10)).grid(row=3, column=1, sticky='w')
        Label(select_frame, text='Override', font=('Arial', 10)).grid(row=3, column=2, sticky='w')
        Label(select_frame, text='Image', font=('Arial', 10)).grid(row=3, column=3, sticky='w')
        Label(select_frame, text='Tag', font=('Arial', 10)).grid(row=3, column=4, sticky='w')

        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=4, columnspan=5, sticky='w')

        i = 5

        for product in self.product_list:
            self.check_btns_state[product] = BooleanVar()
            self.check_btns_state[product].set(False)
            self.check_btns[product] = Checkbutton(select_frame, text=product,
                                                   var=self.check_btns_state[product])
            self.check_btns[product].grid(row=i, column=0, sticky=W)

            self.product_image_textbox_val[product] = StringVar()
            self.product_image_tag_textbox_input_val[product] = StringVar()

            self.product_image_tag_textbox_input[product] = Entry(select_frame, textvariable=self.product_image_tag_textbox_input_val[product], state=DISABLED)
            self.product_image_textbox_input[product] = Entry(select_frame, textvariable=self.product_image_textbox_val[product], state=DISABLED)

            self.product_image_check_btn_val[product] = BooleanVar()

            self.product_image_check_btn[product] = \
                Checkbutton(select_frame, var=self.product_image_check_btn_val[product],
                            command=lambda entry1=self.product_image_textbox_input[product],
                            entry2=self.product_image_tag_textbox_input[product],
                            val=self.product_image_check_btn_val[product]: self.override_checks(entry1, entry2, val))

            self.product_image_check_btn[product].grid(row=i, column=2, sticky='w')

            self.product_image_textbox_input[product].grid(row=i, column=3, sticky='w')
            self.product_image_tag_textbox_input[product].grid(row=i, column=4, sticky='w')

            if product in ['openam', 'openidm', 'openig']:
                self.product_textbox_input_val[product] = StringVar()
                self.product_textbox_input[product] = Entry(select_frame, textvariable=self.product_textbox_input_val[product], width=50)
                self.product_textbox_input[product].grid(row=i, column=1)

            i += 1

        self.product_textbox_input_val['openam'].set('/git/config/6.5/smoke-tests/am/')
        self.product_textbox_input_val['openidm'].set('/git/config/6.5/smoke-tests/idm/')
        self.product_textbox_input_val['openig'].set('/git/config/6.5/default/ig/basic-sample')

        ttk.Separator(select_frame, orient=HORIZONTAL).grid(row=i, columnspan=5, sticky='we')
        i += 1

        Label(select_frame, text='Global settings', font=('Arial', 10), pady=10).grid(row=i, column=0, sticky=W)
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
        self.namespace_input_var.set('changeme')
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
        self.terminal_output.pack(fill='both')
        self.terminal_output.insert(END, self.init_message)
        messagebox.showwarning("Caution", "This utility is not supported by Forgerock")
        self._root.mainloop()

    # Deploy process related methods

    def about_dialog(self):
        messagebox.showinfo("About", "Simple utility to deploy Forgerock product into cloud")

    def set_inputs_state(self, state):
        self.git_branch_text_field.config(state=state)
        self.git_repo_text_field.config(state=state)
        self.domain_text_field.config(state=state)
        self.namespace_text_field.config(state=state)

    def set_product_inputs_state(self, product, state):
        self.product_image_check_btn[product].config(state=state)
        if product not in ['userstore', 'configstore', 'ctsstore']:
            self.product_textbox_input[product].config(state=state)

    def delete_deployment(self):
        print('Removing...')
        self.deploy_process = subprocess.Popen([self.forgeops_path + '/remove-all.sh', '-N', self.namespace_input_var.get()],
                                               stdout=PIPE, bufsize=1)
        self.subqueue = Queue()
        t = Thread(target=self.run_script_nonblocking, args=(self.deploy_process.stdout, self.subqueue))
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
        t = Thread(target=self.run_script_nonblocking, args=(self.deploy_process.stdout, self.subqueue))
        t.daemon = True
        t.start()

    def run_script_nonblocking(self, out, queue):
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
        self.frconfig_gen()

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

        if self.product_image_check_btn_val['userstore'].get() == 1:
            userstore['image']['repository'] = self.product_image_textbox_input['userstore'].get()
            userstore['image']['tag'] = self.product_image_tag_textbox_input_val['userstore'].get()

        if self.product_image_check_btn_val['configstore'].get() == 1:
            configstore['image']['repository'] = self.product_image_textbox_input['configstore'].get()
            configstore['image']['tag'] = self.product_image_tag_textbox_input_val['configstore'].get()

        if self.product_image_check_btn_val['ctsstore'].get() == 1:
            ctsstore['image']['repository'] = self.product_image_textbox_input['ctsstore'].get()
            ctsstore['image']['tag'] = self.product_image_tag_textbox_input_val['ctsstore'].get()

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
        if self.product_image_check_btn_val['openam'].get() == 1:
            openam['image']['repository'] = self.product_image_textbox_input['openam'].get()
            openam['image']['tag'] = self.product_image_tag_textbox_input_val['openam'].get()

        with open(os.path.join(self.config_folder, amster_filename), 'w') as f:
            dump(amster, f, default_flow_style=False)
        with open(os.path.join(self.config_folder, openam_filename), 'w') as f:
            dump(openam, f, default_flow_style=False)

    def idm_config_gen(self):
        idm_filename = 'openidm.yaml'
        idm = {'config': {'path': self.product_textbox_input_val['openidm'].get()}}
        if self.product_image_check_btn_val['openidm'].get() == 1:
            idm['image']['repository'] = self.product_image_textbox_input['openidm'].get()
            idm['image']['tag'] = self.product_image_tag_textbox_input_val['openidm'].get()

        with open(os.path.join(self.config_folder, idm_filename), 'w') as f:
            dump(idm, f, default_flow_style=False)

    def ig_config_gen(self):
        ig_filename = 'openig.yaml'
        ig = {'config': {'path': self.product_textbox_input_val['openig'].get()}}
        if self.product_image_check_btn_val['openig'].get() == 1:
            ig['image']['repository'] = self.product_image_textbox_input['openig'].get()
            ig['image']['tag'] = self.product_image_tag_textbox_input_val['openig'].get()

        with open(os.path.join(self.config_folder, ig_filename), 'w') as f:
            dump(ig, f, default_flow_style=False)

    def frconfig_gen(self):
        frconfig_filename = 'frconfig.yaml'
        frconfig = {'git': {'repo': self.frconfig_git_repo.get(), 'branch': self.frconfig_git_branch.get()}}

        with open(os.path.join(self.config_folder, frconfig_filename), 'w') as f:
            dump(frconfig, f, default_flow_style=False)

    # Helper methods

    def override_checks(self, entry1, entry2, val):
        if val.get() == 0:
            entry1.config(state=DISABLED)
            entry2.config(state=DISABLED)
        else:
            entry1.config(state=NORMAL)
            entry2.config(state=NORMAL)

    def exit_gui(self):
        self._root.quit()


if __name__ == "__main__":
    gui = ForgeopsGUI()
    gui.run()
