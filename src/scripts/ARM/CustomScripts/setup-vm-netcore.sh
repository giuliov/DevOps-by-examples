#!/bin/bash

echo "*** Get latest patches"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "*** Adding DEB keys"
sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt-get update

echo "*** Removing previous .NET Core installation"
sudo sh -c 'wget  -o /tmp/dotnet-uninstall.log -O - https://raw.githubusercontent.com/dotnet/cli/rel/1.0.0/scripts/obtain/uninstall/dotnet-uninstall-debian-packages.sh | bash'
cat /tmp/dotnet-uninstall.log
sudo rm /tmp/dotnet-uninstall.log

echo "*** Installing .NET Core"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install dotnet-dev-1.0.4

echo "*** Install nginx as a proxy, no firewall"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nginx

echo "*** Install supervisor to run app as daemon"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor

echo "*** Start nginx"
sudo service nginx start
