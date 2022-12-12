#!/bin/bash

ZLOG_PATH=$PWD/zlog
IP_ADDRESS=10.2.0.4 # VM's private IP address
HOST_NAME=ceph-test # Ceph host name

sudo apt-get install librados-dev
sudo apt-get install libradospp-dev
sudo apt install cmake
sudo apt install liblmdb-dev
sudo apt-get install ceph-mon
sudo apt-get install ceph-osd
curl -sSL https://get.docker.com/ | sudo sh
sudo apt-get install libprotobuf-dev

git config --global url."https://github".insteadOf git://github
git clone --recursive https://github.com/illinoisdata/zlog.git
cd zlog
./install-deps.sh
sudo cmake -DWITH_CEPH=ON -DCMAKE_CXX_COMPILER=/usr/bin/g++ .
sudo make
sudo docker/build-ceph-plugin.sh -i ubuntu:bionic -c luminous
sudo cp -a libcls_zlog_ubuntu\:bionic.luminous/libcls_zlog.so* /usr/lib/rados-classes
cd ..

git clone https://github.com/ceph/ceph.git
sudo ./ceph/src/cephadm/cephadm.py add-repo --release octopus
sudo ./ceph/src/cephadm/cephadm.py install
sudo cephadm install ceph-common

# Bootstrap reference: https://docs.ceph.com/en/quincy/cephadm/install/
sudo cephadm bootstrap --config init-ceph.conf --mon-ip ${IP_ADDRESS}

# Create 3 new OSDs: https://docs.ceph.com/en/quincy/cephadm/services/osd/#creating-new-osds
# Before executing the following commands, attach a new disk to the VM with size at least 5GB, see: https://docs.ceph.com/en/quincy/cephadm/services/osd/#cephadm-deploy-osds
sudo ceph orch apply osd --all-available-devices
sudo ceph orch daemon add osd ${HOST_NAME}:/dev/sdb # Change /dev/sdb to other disk path if necessary
sudo ceph orch daemon add osd ${HOST_NAME}:/dev/sdc # Change /dev/sdc to other disk path if necessary
sudo ceph orch daemon add osd ${HOST_NAME}:/dev/sdd # Change /dev/sdd to other disk path if necessary

# check the status, there should have one OSD created. 
# sudo ceph status 
