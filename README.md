# TigerTaxi-Docker
Extends the `osrf/ros:kinetic-desktop-full` image by adding opengl, glvnd and
cuda 8.0. This makes opengl work from any docker environment when used with
[nvidia-docker2](https://github.com/NVIDIA/nvidia-docker).

# Installation
1. Install docker
2. Install nvidia-docker using instructions
[here](https://github.com/NVIDIA/nvidia-docker).
3. After cloning this repo, run
`sudo docker build -t tiger_taxi tigertaxi-docker/`
4. Run the following commands (to give docker permission to do X stuff):
```bash
xhost +local:docker
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
sudo touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH nmerge -
```
5. Start the container:
```bash
sudo nvidia-docker run -it -v </path/to/TigerTaxi>/:/home/rosmaster/TigerTaxi
--volume=$XSOCK:$XSOCK:rw --volume=$XAUTH:$XAUTH:rw --env="XAUTHORITY=${XAUTH}"
--env="DISPLAY" --user rosmaster tiger_taxi
```
Take care to replace `</path/to/TigerTaxi>` with the path where you have
cloned the TigerTaxi repo.

6. (First launch only) After entering container as rosmaster,
install caffe-enet:
```bash
cd TigerTaxi/tt_core/ENet/caffe-enet
./install.sh
```
