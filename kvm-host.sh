#!/bin/bash -ex

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
NAME="em1"
DEVICE="em1"
ONBOOT=yes
NETBOOT=no
IPV6INIT=no
TYPE=Ethernet
NM_CONTROLLED=no
BRIDGE=br-ex
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em2
NAME=em2
DEVICE=em2
ONBOOT=yes
NETBOOT=no
IPV6INIT=no
TYPE=Ethernet
NM_CONTROLLED=no
BRIDGE=br-ctlplane
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE=br-ex
TYPE=Bridge
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
IPADDR=10.10.0.1
NETWORK=10.10.0.0
NETMASK=255.255.255.0
ZONE=ex
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ctlplane
DEVICE=br-ctlplane
TYPE=Bridge
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
IPADDR=10.11.0.1
NETWORK=10.11.0.0
NETMASK=255.255.255.0
ZONE=ctlplane
EOF

systemctl disable iptables
systemctl stop iptables
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=external --change-interface=em4 --permanent
firewall-cmd --zone=external --add-service=ssh --permanent
firewall-cmd --new-zone=ex --permanent
firewall-cmd --zone=ex --change-interface=br-ex --permanent
firewall-cmd --new-zone=ctlplane --permanent
firewall-cmd --zone=ctlplane --change-interface=br-ctlplane --permanent
firewall-cmd --zone=ex  --add-service=ssh --permanent
firewall-cmd --zone=ctlplane  --add-service=ssh --permanent
firewall-cmd --zone=external --add-masquerade --permanent
firewall-cmd --zone=external --query-icmp-block=echo-reply
firewall-cmd --zone=ex --query-icmp-block=echo-reply
firewall-cmd --zone=ctlplane --query-icmp-block=echo-reply
firewall-cmd --zone=ex --add-source=10.10.0.0/24 --permanent
firewall-cmd --zone=ctlplane --add-source=10.11.0.0/24 --permanent
firewall-cmd --reload

subscription-manager register
POOL_ID=$(subscription-manager list --available --all | grep "Pool ID" | awk '{print $3}')
subscription-manager attach --pool=$POOL_ID

yum update -y
yum install -y libvirt-client libvirt-daemon qemu-kvm libvirt-daemon-driver-qemu libvirt-daemon-kvm virt-install bridge-utils rsync
reboot
