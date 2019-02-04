# Lib imports
import subprocess


def run_cmd_process(cmd):
    """
    Useful for getting flow output
    :param cmd: command to run
    :return: Process handle
    """
    print('Running following background command as process: ' + cmd)
    popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return popen


def run_cmd(cmd):
    """
    Useful for getting flow output
    :param cmd: command to run
    :return: Process handle
    """
    print('Running following foreground command as process: ' + cmd)
    popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = popen.communicate()
    return out, err
