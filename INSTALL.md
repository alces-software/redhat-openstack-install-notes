# Hardware config

- 2 x Dell R430
  - `em1` configured as `ex` `10.10.0.0`
  - `em2` configured as `ctlplane` `10.11.0.0`
  - IPMI configured on both hosts

# On the director KVM host

- Install a clean copy of RHEL7.4
- Configure `em1` as `br-ex` with IP `10.10.0.1` and zone `external`
- Configure `em2` as `br-ctlplane` with IP `10.11.0.1` and zone `ctlplane`
- Configure `em4` as external network
- Configure `firewalld` to do firewall things:

```
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
```

- Register the RHEL subscription, disable and enable the correct repositories

```
subscription-manager register
# copy Pool ID from the following command
subscription-manager list --available --all --matches="Red Hat OpenStack"
subscription-manager attach --pool=<pool id>
```

- Install the required packages, upgrade and reboot

```
yum update -y
yum install -y libvirt-client libvirt-daemon qemu-kvm libvirt-daemon-driver-qemu libvirt-daemon-kvm virt-install bridge-utils rsync
reboot
```

- Download and copy the RHEL 7 DVD iso to `/var/lib/libvirt/images`

- Install the director, the default options can be used at configuration stage. The installer runs in GUI mode, so make sure you are connected with X forwarding enabled

```
virt-install --name director --memory 16384 --vcpus 4 --location /var/lib/libvirt/images/rhel-server-7.4-x86_64-dvd.iso --disk size=16 --network bridge=br-ex --network bridge=br-ctlplane --graphics vnc --hvm --os-variant=rhel7
```

# On the director

- Log in to the director and bring up both interfaces as:
  - `eth0` - `10.10.0.11` with DNS `8.8.8.8` and gateway `10.10.0.1`
  - `eth1` - `10.11.0.11`
- Register RHEL subscription as per the instructions used to register the KVM host
- Set the hostname to match KVM host hostname
