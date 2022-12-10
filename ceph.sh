# Attach a new disk to the VM with size at least 5GB, see: https://docs.ceph.com/en/quincy/cephadm/services/osd/#cephadm-deploy-osds

#!/bin/bash

ZLOG_PATH=$PWD/zlog
IP_ADDRESS=10.2.0.4 # VM's private IP address
HOST_NAME=ceph-test # Ceph host name

sudo apt-get install librados-dev
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
sudo cmake -DWITH_CEPH=ON .
sudo make
sudo docker/build-ceph-plugin.sh -i ubuntu:bionic -c luminous
cd ..

git clone https://github.com/ceph/ceph.git
sudo ./ceph/src/cephadm/cephadm.py add-repo --release octopus
sudo ./ceph/src/cephadm/cephadm.py install
sudo cephadm install ceph-common

# Bootstrap reference: https://docs.ceph.com/en/quincy/cephadm/install/
sudo cephadm bootstrap --mon-ip ${IP_ADDRESS}

# Create OSDs: https://docs.ceph.com/en/quincy/cephadm/services/osd/#creating-new-osds
sudo ceph orch apply osd --all-available-devices
sudo ceph orch daemon add osd ${HOST_NAME}:/dev/sdb

# check the status, there should have one OSD created. 
# sudo ceph status 