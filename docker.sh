#!/bin/bash

## https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
docker search debian-stretch-slim
docker pull ehdevops/debian-stretch-slim
docker images
docker run --privileged --rm -it -v $(pwd):/home/$USER/ -e USER=$USER  -e USERID=$UID ehdevops/debian-stretch-slim
docker run --privileged --rm -it -v /dev:/dev -v  $(pwd):/home/$USER/   -e USER=$USER  -e USERID=$UID ehdevops/debian-stretch-slim



docker ps -l
docker commit bebfdd4805dc ehdevops/debian-stretch-slim

apt install xz-utils wget kpartx qemu-user-static qemu-utils rsync


## https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04
docker search debian
docker pull debian
docker images
docker run --privileged --rm -it -v /dev:/dev -v  $(pwd):/home/$USER/ -e USER=$USER  -e USERID=$UID debian
apt update
apt install xz-utils wget kpartx qemu-user-static qemu-utils rsync
apt-get install ca-certificates
apt -y install make gcc python gettext pkg-config

docker ps -l
docker commit x debian

docker images -a
docker rmi $(docker images -a -q)
docker rmi ehdevops/debian-stretch-slim
