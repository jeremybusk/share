#!/usr/bin/env python3.6
import sys
import subprocess
import itertools
import difflib

# Set the variables
deb_os = ['debian9', 'ubuntu1804', 'ubuntu1604', 'ubuntu']
rpm_os = ['fedora28', 'fedora27', 'fedora']
deb_package_url = ' https://repo.rchain.space/new2.deb'
rpm_package_url = ' https://repo.rchain.space/new2.rpm'
deb_rm_cmd = 'pkill -9 java; sleep 4; apt-get -yq remove --purge rnode'
rpm_rm_cmd = 'pkill -9 java; sleep 4; yum remove -y rnode'
deb_install_cmd = f'curl -s {deb_package_url} --output rnode.deb; apt-get -yq install ./rnode.deb; /bin/rm rnode.deb'
rpm_install_cmd = f'curl -s {rpm_package_url} --output rnode.rpm; yum -y install ./rnode.rpm; /bin/rm rnode.rpm'
required_packages = 'sudo curl'
deb_prep_cmd = 'apt update; apt-get -yq install sudo curl'
rpm_prep_cmd = 'yum -y install sudo curl'
ssh_user = 'root'

defaults =  {
                'bootstrap_node_run_cmd': 'sudo -u rnode rnode -s > /var/log/rnode.log 2>&1 &',
                'node_run_cmd': 'sudo -u rnode rnode -b rnode://217d5ab9604572bb90c2d66fe5aa35f4143b368e@52.119.8.14:30304 > /var/log/rnode.log 2>&1 &',
                'rm_var_lib_rnode': False 
            }

peers = [ 
            {
                'fqdn':'peer-bootstrap.pyr8.io',
                'os':'ubuntu1804',
                'provider':'pyrofex',
                'ipv4': '52.119.8.14',
                'ipv6': '',
                'run_cmd': defaults['bootstrap_node_run_cmd'] 
            },
#            {
#                'fqdn':'peer-lehi.pyr8.io',
#                'os':'ubuntu1804',
#                'provider':'uvoo',
#                'ipv4': '204.15.86.210',
#                'ipv6': '',
#                'run_cmd': defaults['node_run_cmd'] 
#            },
            {
                'fqdn':'peer-orem.pyr8.io',
                'os':'ubuntu1804',
                'provider':'pyrofex',
                'ipv4': '52.119.8.15',
                'ipv6': '',
                'run_cmd': defaults['node_run_cmd'] 
            },
            {
                'fqdn':'peer-aws.pyr8.io',
                'os':'ubuntu1804',
                'provider':'aws',
                'ipv4':'18.236.83.52',
                'ipv6': '',
                'run_cmd': defaults['node_run_cmd'] 
            },
            {
                'fqdn':'peer-bangalore.pyr8.io',
                'os':'ubuntu1804',
                'provider':'digitalocean',
                'ipv4':'159.89.161.249',
                'ipv6':'2400:6180:100:d0::853:1001',
                'run_cmd': defaults['node_run_cmd'] 
            },
            {
                'fqdn':'peer-singapore.pyr8.io',
                'os':'fedora28',
                'provider':'digitalocean',
                'ipv4':'167.99.71.110',
                'ipv6':'2400:6180:0:d1::548:2001',
                'run_cmd': defaults['node_run_cmd'] 
            }
       ] 

def main():
    get_peers()

def update_network():
    for peer in peers:
        print(peer['fqdn'])
        print(peer['os'])

        ## Check OS and run commands 
        output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", 'cat /etc/*release'], stdout=subprocess.PIPE)
        print(output)
        if 'ubuntu' in str(output):
        #if peer['os'] in deb_os:
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{deb_prep_cmd}'])
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{deb_rm_cmd}'])
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{deb_install_cmd}'])
        elif 'fedora' in str(output):
        #elif peer['os'] in rpm_os:
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{rpm_prep_cmd}'])
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{rpm_rm_cmd}'])
            output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f'{rpm_install_cmd}'])
        else:
            print("os not supported")
            sys.exit()
        
        output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", f"{peer['run_cmd']}"])

def get_peers():
    print("Display Diagnostics")
    peer_diagnostics = []
    for peer in peers: 
        print(peer['fqdn'])
        output = subprocess.run(['ssh', '-oStrictHostKeyChecking=no', f"{ssh_user}@{peer['fqdn']}", "sudo rnode --diagnostics | sed '/Node core metrics:/q' | grep ^rnode | sort"], stdout=subprocess.PIPE)
        peer_diagnostics.append(output.stdout)
    for i in peer_diagnostics:
        print(i.decode('utf-8'))
    for a, b in itertools.combinations(peer_diagnostics, 2):
        difflib.unified_diff(a, b)


if __name__ == "__main__":
    main()
