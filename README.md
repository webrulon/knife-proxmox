# Knife Proxmox

Authors: Jorge Moratilla, Sergio Galvan, Adam Enger

Date: 2013-10-06


## Description

This is a knife plugin for Chef Server 11. knife proxmox allows to access the Proxmox Virtualization Environment (PVE) through its API.

PVE API Docs :: http://pve.proxmox.com/pve2-api-doc/

Supports both OpenVZ and QEMU instances. Not all API methods are supported quite yet, however most functionality will work.

Bootstrapping is now supported for OpenVZ instances

## Installation

I have yet to upload this to rubygems.org so you'll have to manually build and install:

    $ git clone https://github.com/adamenger/knife-proxmox.git
	$ gem build knife-proxmox/knife-proxmox.gemspec
    $ gem install --local knife-proxmox/knife-proxmox-0.0.20.gem


## knife.rb settings
    knife[:pve_cluster_url] = 'https://vm.adamenger.com:8006/api2/json/'
	knife[:pve_node_name] = "vm"
	knife[:pve_user_name] = "root"
	knife[:pve_user_password] = "password"
	knife[:pve_user_realm] = "pam"

## Actions implemented

+ knife proxmox iso list (options)
+ knife proxmox node list (options)
+ knife proxmox template available (options)
+ knife proxmox template list (options)
+ knife proxmox vm create (options)
+ knife proxmox vm delete (options)
+ knife proxmox vm info (options)
+ knife proxmox vm list (options)
+ knife proxmox vm start (options)
+ knife proxmox vm stop (options)

## Some Examples

### List ISO images
    $ knife proxmox iso list
    Id  Name                                                           Size  
    0   local:iso/CentOS-6.4-i386-minimal.iso                          300 MB
    1   local:iso/CentOS-6.4-x86_64-minimal.iso                        342 MB
    2   local:iso/debian-7.1.0-i386-netinst.iso                        277 MB
    3   local:iso/pfSense-LiveCD-2.0.3-RELEASE-i386-20130412-1022.iso  89 MB 
    4   local:iso/ubuntu-12.04.3-desktop-i386.iso                      707 MB

### List virtual machines
    $ knife proxmox vm list
	Id   Node  Name                   Type    Status
	101  vm    qemu-test              qemu    running
	102  vm    qemu-test2             qemu    stopped
	103  vm    openvz-test            openvz  running
	104  vm    openvz-test2           openvz  running

### List PVE servers
    $ knife proxmox node list
	#  Id       Name  Free Mem  Disk    Uptime
	1  node/vm  vm    10.08GB   923 GB  31 Days

### Get VM information

**Get all server attributes - OpenVZ**

    $ knife proxmox vm info -I 102
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
    name:      test.example.com
    netin:     27888604
    netout:    2829601
    nproc:     140
    status:    running
    swap:      54460416
    type:      openvz
    uptime:    61018

**Get all server attributes - QEMU**

	$ knife proxmox vm info -I 103
	balloon:   536870912
	cpu:       0
	cpus:      1
	disk:      0
	diskread:  35338740
	diskwrite: 0
	ha:        0
	maxdisk:   0
	maxmem:    536870912
	mem:       151617269
	name:      proxmox
	netin:     0
	netout:    0
	pid:       609365
	qmpstatus: running
	status:    running
	template:
	uptime:    2435

**Get specific attribute**

    $ knife proxmox vm info -I 102 -f name
    proxmox

### List templates installed
    $ knife proxmox  template list
    Id  Name                                                         Size
    0   local:vztmpl/debian-6.0-request-tracker_3.8.8-2_i386.tar.gz  171 MB
    1   local:vztmpl/old_ubuntu-11.10-x86_64.tar.gz                  124 MB
    2   local:vztmpl/ubuntu-10.04-standard_10.04-4_i386.tar.gz       135 MB
    3   local:vztmpl/ubuntu-11.10-x86_64-jorge1-.tar.gz              124 MB
    4   local:vztmpl/ubuntu-11.10-x86_64-jorge2-.tar.gz              154 MB


### List templates available to download
    $ knife proxmox template available
    Name                                                       Operating System
    debian-6-turnkey-concrete5_12.0-1_i386.tar.gz              debian-6
    ubuntu-10.04-turnkey-prestashop_11.3-1_i386.tar.gz         ubuntu-10.04
    debian-6-turnkey-joomla25_12.0-1_i386.tar.gz               debian-6
    debian-6-turnkey-tomcat-apache_12.0-1_i386.tar.gz          debian-6
    debian-6.0-wordpress_3.4.2-1_i386.tar.gz                   debian-6.0 .....

### Bootstrapping OpenVZ VM

    knife proxmox vm create --vm_type openvz -m 1024 --ip 192.168.7.6 \
    -P password --os_template local:vztmpl/ubuntu-12.04-standard_12.04-1_i386.tar.gz \
    --bootstrap --runlist "recipe[ase-role-base], recipe[jenkins::server], recipe[jenkins::proxy]" -h jenkins.adamenger.com

### Create OpenVZ VM
    $  knife proxmox vm create --vm_type openvz --os_template local:vztmpl/ubuntu-12.04.tar.gz -h vm.test.com -z 2 -m 1024
    Creating VM 105...
    Starting VM 105 on node vm...

### Create QEMU VM
    $  knife proxmox vm create --vm_type qemu --cdrom local:iso/ubuntu-12.04.3-desktop-i386.iso -h vm.test.com -z 2 -m 1024
    Creating VM 105...
    Starting VM 105 on node vm...

### Starting a VM
    $ knife proxmox vm start -I 103
    Starting VM 103....

### Stopping a VM
    $ knife proxmox vm stop -I 103
    Stopping VM 103....

### Deleting a VM
    $ knife proxmox vm delete -I 103
	Stopping VM 103...
	Deleting VM 103...
