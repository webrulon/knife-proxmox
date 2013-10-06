# Chef::Knife::Proxmox

Authors: Jorge Moratilla, Sergio Galvan, Adam Enger
Date: 2013-10-06


## Description

This knife plugin allows to access Proxmox Virtualization Environment (Proxmox VE or PVE) through its API.
It allows you to lists templates installed on the server/cluster (like images or amis), create a server or
destroy it.

Support for QEMU is in progress. 

## Requirements

* zlib (zlib1g-dev)
* openssl (libopenssl-ruby, libssl-dev)

Then install your ruby language (recommended ruby-1.9.3-xxx)

(See installation instructions beneath)

## knife.rb settings
    knife[:pve_cluster_url] = 'https://vm.adamenger.com:8006/api2/json/'
	knife[:pve_node_name] = "vm"
	knife[:pve_user_name] = "root"
	knife[:pve_user_password] = "password"
	knife[:pve_user_realm] = "pam"
	knife[:pve_vm_type] = "qemu"

## Actions implemented

+ proxmox iso list
+ proxmox server list
+ proxmox server info
+ proxmox server create
+ proxmox server start
+ proxmox server stop
+ proxmox server destroy
+ proxmox template available
+ proxmox template list

## Some Examples

### List ISO images
    $ knife proxmox iso list
    Id  Name                                                           Size  
    0   local:iso/CentOS-6.4-i386-minimal.iso                          300 MB
    1   local:iso/CentOS-6.4-x86_64-minimal.iso                        342 MB
    2   local:iso/debian-7.1.0-i386-netinst.iso                        277 MB
    3   local:iso/pfSense-LiveCD-2.0.3-RELEASE-i386-20130412-1022.iso  89 MB 
    4   local:iso/ubuntu-12.04.3-desktop-i386.iso                      707 MB

### List servers
    $ knife proxmox server list
    Id   Node    Name                 Type    Status
    102  node-1  test                 qemu    down
    104  node-1  tetatet.example.com  openvz  down
    202  node-2  chef-client1         openvz  down
    470  node-2  sg-node1.example.com openvz  up

### Get info for a server
    $ knife proxmox server info -H tetatet.example.com -P ip
    192.168.1.1

    $ knife proxmox server info -H tetatet.example.com
    knife proxmox server info -H tetatet.example.com -P ip
    cpu:       0.00281876923420022
    cpus:      2
    disk:      5833015296
    diskread:  316895232
    diskwrite: 3805184
    failcnt:   0
    ha:        0
    ip:        192.168.42.200
    maxdisk:   8589934592
    maxmem:    4294967296
    maxswap:   536870912
    mem:       1145778176
    name:      tetatet.example.com
    netin:     27888604
    netout:    2829601
    nproc:     140
    status:    running
    swap:      54460416
    type:      openvz
    uptime:    61018


### List templates installed
    $ knife proxmox  template list -U https://localhost:8006/api2/json/ -n localhost -u test -p test123 -R pve -VV
    DEBUG: Using configuration from /home/jorge/workspace/chef-repo/.chef/knife.rb
    Id  Name                                                         Size
    0   local:vztmpl/debian-6.0-request-tracker_3.8.8-2_i386.tar.gz  171 MB
    1   local:vztmpl/old_ubuntu-11.10-x86_64.tar.gz                  124 MB
    2   local:vztmpl/ubuntu-10.04-standard_10.04-4_i386.tar.gz       135 MB
    3   local:vztmpl/ubuntu-11.10-x86_64-jorge1-.tar.gz              124 MB
    4   local:vztmpl/ubuntu-11.10-x86_64-jorge2-.tar.gz              154 MB


### List templates available to download
    $ knife proxmox template available -U https://localhost:8006/api2/json/ -u test -p test123 -n localhost -R pve  -VV
    DEBUG: Using configuration from /home/jorge/workspace/chef-repo/.chef/knife.rb
    Name                                                       Operating System
    debian-6-turnkey-concrete5_12.0-1_i386.tar.gz              debian-6
    ubuntu-10.04-turnkey-prestashop_11.3-1_i386.tar.gz         ubuntu-10.04
    debian-6-turnkey-joomla25_12.0-1_i386.tar.gz               debian-6
    debian-6-turnkey-tomcat-apache_12.0-1_i386.tar.gz          debian-6
    debian-6.0-wordpress_3.4.2-1_i386.tar.gz                   debian-6.0 .....


### Create a server (read the note at the end of the document.  It's about obtaining the IPAddress)

    $  knife proxmox server create -n ankh -r "recipe[java]" -C 2 -M 1024 -H example-server -P test123 -T 4
    Creating VM 473...
    ..............OK
    Preparing the server to start
    Starting VM 473 on node ankh....
    ..OK
    New Server 473 has IP Address: 10.0.2.19
    done
    Bootstrapping Chef on 10.0.2.19
    10.0.2.19 --2013-01-23 01:27:20--  http://opscode.com/chef/install.sh
    10.0.2.19 Resolving opscode.com...
    10.0.2.19 184.106.28.83
    10.0.2.19 Connecting to opscode.com|184.106.28.83|:80...
    10.0.2.19 connected.
    10.0.2.19 HTTP request sent, awaiting response...
    10.0.2.19 301 Moved Permanently
    10.0.2.19 Location: http://www.opscode.com/chef/install.sh [following]
    10.0.2.19 --2013-01-23 01:27:21--  http://www.opscode.com/chef/install.sh
    10.0.2.19 Resolving www.opscode.com...
    10.0.2.19 184.106.28.83
    10.0.2.19 Reusing existing connection to opscode.com:80.
    10.0.2.19 HTTP request sent, awaiting response...
    10.0.2.19 200 OK


### Starting a server
    $ knife proxmox server start --vmid 401
    Starting VM 401....
    Result: 200


### Stopping a server
    $ knife proxmox server stop --vmid 103
    Stoping VM 103....
    Result: 200


### Destroy a server
    $ knife proxmox server destroy -U https://localhost:8006/api2/json/ -u test -p test123 -n localhost -R pve -N vm-node1 -VV -P
    DEBUG: Using configuration from /home/jorge/workspace/chef-repo/.chef/knife.rb
    node to destroy: vm-node1 [vmid: 200]
    Continue? (Y/N) y
    Stopping VM 303....
    Result: 200
    ..............................
    Result: 200
    WARNING: Deleted node vm-node1
    WARNING: Deleted client vm-node1


## Installation

This gem must be installed on your system using the command

    $ gem install knife-proxmox

If you want to read values from the environment variables modify your knife.rb:

    knife[:pve_cluster_url] ||= "#{ENV['PVE_CLUSTER_URL']}"
    knife[:pve_user_name]   ||= "#{ENV['PVE_USER_NAME']}"
    knife[:pve_node_name]   ||= "#{ENV['PVE_NODE_NAME']}"
    knife[:pve_user_realm]  ||= "#{ENV['PVE_USER_REALM']}"

However I don't recommend to have the user password as a environment variable.
knife[:pve_user_password] = "#{ENV['PVE_CLUSTER_URL']}"

### Environment Variables

    PVE_CLUSTER_URL = https://<proxmox_server>:8006/api2/json/
    PVE_USER_NAME   = <user>
    PVE_PASSWORD_NAME = <password>
    PVE_USER_REALM  = <pam|pve|others>
    PVE_NODE_NAME   = <nodename>

If you want to alter some variable by command line then you can use the following options:
-n --node <node>   If in a cluster, this argument will specify which node of the cluster will do the action
-U --pve_cluster_url <http://localhost...> Will change the cluster to access to
-u --username <user>   Same for user
-p --password <pass>   Same for password
-r --realm    <realm>  Same for the realm used to authenticate

There is a script in extra/set_environment_variables.sh that creates the
set of variables needed for knife-proxmox. Just answer the questions and
paste the output into your profile file.



### ABOUT CHEF AND PROXMOX

To bootstrap a newly created VM, you should apply the patch inside the extra directory.  Otherwise you must
specify the IP address in the knife proxmox server create --ipaddress argument.

