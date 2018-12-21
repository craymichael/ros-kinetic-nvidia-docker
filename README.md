# ros-kinetic-nvidia-docker
Extends the `osrf/ros:kinetic-desktop-full` image by adding opengl, glvnd and
cuda 8.0. This makes opengl work from any docker environment when used with
[nvidia-docker2](https://github.com/NVIDIA/nvidia-docker). Thanks to
[phromo](https://github.com/phromo/ros-indigo-desktop-full-nvidia) for the
baseline. Note that this is currently supported for Linux systems only.

To extend the Dockerfile (e.g. to add more ROS packages or users), take a
look at the commented out lines at the end of file.

# Installation
1. Install docker
2. Install nvidia-docker using instructions
[here](https://github.com/NVIDIA/nvidia-docker).
3. After cloning this repo, run
`sudo docker build -t <image_name> ros-kinetic-nvidia-docker/`
4. Run the following commands to give docker permission to run on X:
```bash
xhost +local:docker
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
sudo touch $XAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH nmerge -
```
5. Start the container:
```bash
sudo nvidia-docker run -it --volume=$XSOCK:$XSOCK:rw
--volume=$XAUTH:$XAUTH:rw --env="XAUTHORITY=${XAUTH}"
--env="DISPLAY" <image_name>
```
