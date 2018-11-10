FROM osrf/ros:kinetic-desktop-full

RUN rm -rf /var/lib/apt/lists/*

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

#RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# ==================
# below sourced from https://gitlab.com/nvidia/opengl/blob/ubuntu16.04/base/Dockerfile

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        libxau6 libxau6:i386 \
        libxdmcp6 libxdmcp6:i386 \
        libxcb1 libxcb1:i386 \
        libxext6 libxext6:i386 \
        libx11-6 libx11-6:i386 && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# ==================
# below sourced from https://gitlab.com/nvidia/opengl/blob/ubuntu14.04/1.0-glvnd/runtime/Dockerfile

RUN apt-get update && apt-get install -y --no-install-recommends \
        apt-utils && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        automake \
        autoconf \
        libtool \
        pkg-config \
        python \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/libglvnd

RUN git clone --branch=v1.0.0 https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gcc-multilib \
        libxext-dev:i386 \
        libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*

# 32-bit libraries
RUN make distclean && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/i386-linux-gnu --host=i386-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/i386-linux-gnu -type f -name 'lib*.la' -delete

COPY 10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# ==================
# below sourced from https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/8.0/runtime/Dockerfile

RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

ENV CUDA_VERSION_MAJOR=8.0 \
    CUDA_VERSION_MINOR=61 \
    CUDA_PKG_EXT=8-0
ENV CUDA_VERSION=$CUDA_VERSION_MAJOR.$CUDA_VERSION_MINOR
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-nvrtc-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-nvgraph-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cusolver-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cublas-dev-$CUDA_PKG_EXT=$CUDA_VERSION.2-1 \
        cuda-cufft-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-curand-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cusparse-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-npp-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-cudart-dev-$CUDA_PKG_EXT=$CUDA_VERSION-1 \
        cuda-misc-headers-$CUDA_PKG_EXT=$CUDA_VERSION-1 && \
    ln -s cuda-$CUDA_VERSION_MAJOR /usr/local/cuda && \
    ln -s /usr/local/cuda-8.0/targets/x86_64-linux/include /usr/local/cuda/include && \
    rm -rf /var/lib/apt/lists/*

# nvidia-docker 1.0
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# nvidia-container-runtime
ENV NVIDIA_REQUIRE_CUDA="cuda>=$CUDA_VERSION_MAJOR"

# Caffe...
RUN apt-get update && apt-get install -y \
        libprotobuf-dev \
        libleveldb-dev \
        libsnappy-dev \
        libopencv-dev \
        libhdf5-serial-dev \
        protobuf-compiler \
        libatlas-base-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        liblmdb-dev && \
    apt-get install -y --no-install-recommends \
        libboost-all-dev

# ROS Stuff
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
    apt-get update

RUN apt-get update && apt-get install -y \
        ros-kinetic-ackermann-msgs \
        ros-kinetic-actionlib \
        ros-kinetic-actionlib-msgs \
        ros-kinetic-actionlib-tutorials \
        ros-kinetic-amcl \
        ros-kinetic-angles \
        ros-kinetic-base-local-planner \
        ros-kinetic-bfl \
        ros-kinetic-bond \
        ros-kinetic-bond-core \
        ros-kinetic-bondcpp \
        ros-kinetic-bondpy \
        ros-kinetic-camera-calibration \
        ros-kinetic-camera-calibration-parsers \
        ros-kinetic-camera-info-manager \
        ros-kinetic-carrot-planner \
        ros-kinetic-catkin \
        ros-kinetic-class-loader \
        ros-kinetic-clear-costmap-recovery \
        ros-kinetic-cmake-modules \
        ros-kinetic-collada-parser \
        ros-kinetic-collada-urdf \
        ros-kinetic-common-msgs \
        ros-kinetic-control-msgs \
        ros-kinetic-costmap-2d \
        ros-kinetic-costmap-converter \
        ros-kinetic-cpp-common \
        ros-kinetic-csm \
        ros-kinetic-cv-bridge \
        ros-kinetic-diagnostic-aggregator \
        ros-kinetic-diagnostic-analysis \
        ros-kinetic-diagnostic-common-diagnostics \
        ros-kinetic-diagnostic-msgs \
        ros-kinetic-diagnostic-updater \
        ros-kinetic-diagnostics \
        ros-kinetic-dwa-local-planner \
        ros-kinetic-dynamic-reconfigure \
        ros-kinetic-eigen-conversions \
        ros-kinetic-eigen-stl-containers \
        ros-kinetic-executive-smach \
        ros-kinetic-fake-localization \
        ros-kinetic-filters \
        ros-kinetic-gazebo-msgs \
        ros-kinetic-gencpp \
        ros-kinetic-geneus \
        ros-kinetic-genlisp \
        ros-kinetic-genmsg \
        ros-kinetic-gennodejs \
        ros-kinetic-genpy \
        ros-kinetic-geographic-msgs \
        ros-kinetic-geometric-shapes \
        ros-kinetic-geometry \
        ros-kinetic-geometry-msgs \
        ros-kinetic-geometry-tutorials \
        ros-kinetic-gl-dependency \
        ros-kinetic-global-planner \
        ros-kinetic-gmapping \
        ros-kinetic-image-common \
        ros-kinetic-image-geometry \
        ros-kinetic-image-transport \
        ros-kinetic-interactive-marker-tutorials \
        ros-kinetic-interactive-markers \
        ros-kinetic-joint-state-publisher \
        ros-kinetic-kdl-conversions \
        ros-kinetic-kdl-parser \
        ros-kinetic-laser-assembler \
        ros-kinetic-laser-filters \
        ros-kinetic-laser-geometry \
        ros-kinetic-laser-pipeline \
        ros-kinetic-laser-proc \
        ros-kinetic-laser-scan-matcher \
        ros-kinetic-libg2o \
        ros-kinetic-map-msgs \
        ros-kinetic-map-server \
        ros-kinetic-media-export \
        ros-kinetic-message-filters \
        ros-kinetic-message-generation \
        ros-kinetic-message-runtime \
        ros-kinetic-mk \
        ros-kinetic-move-base \
        ros-kinetic-move-base-msgs \
        ros-kinetic-move-slow-and-clear \
        ros-kinetic-nav-core \
        ros-kinetic-nav-msgs \
        ros-kinetic-navfn \
        ros-kinetic-navigation \
        ros-kinetic-nodelet \
        ros-kinetic-nodelet-core \
        ros-kinetic-nodelet-topic-tools \
        ros-kinetic-octomap \
        ros-kinetic-opencv3 \
        ros-kinetic-openslam-gmapping \
        ros-kinetic-orocos-kdl \
        ros-kinetic-pcl-conversions \
        ros-kinetic-pcl-msgs \
        ros-kinetic-pcl-ros \
        ros-kinetic-pluginlib \
        ros-kinetic-pluginlib-tutorials \
        ros-kinetic-pointcloud-to-laserscan \
        ros-kinetic-polled-camera \
        ros-kinetic-python-orocos-kdl \
        ros-kinetic-python-qt-binding \
        ros-kinetic-qt-dotgraph \
        ros-kinetic-qt-gui \
        ros-kinetic-qt-gui-cpp \
        ros-kinetic-qt-gui-py-common \
        ros-kinetic-qwt-dependency \
        ros-kinetic-random-numbers \
        ros-kinetic-resource-retriever \
        ros-kinetic-robot \
        ros-kinetic-robot-model \
        ros-kinetic-robot-pose-ekf \
        ros-kinetic-robot-state-publisher \
        ros-kinetic-ros \
        ros-kinetic-ros-base \
        ros-kinetic-ros-comm \
        ros-kinetic-ros-core \
        ros-kinetic-ros-environment \
        ros-kinetic-ros-tutorials \
        ros-kinetic-rosbag \
        ros-kinetic-rosbag-migration-rule \
        ros-kinetic-rosbag-storage \
        ros-kinetic-rosbash \
        ros-kinetic-rosboost-cfg \
        ros-kinetic-rosbuild \
        ros-kinetic-rosclean \
        ros-kinetic-rosconsole \
        ros-kinetic-rosconsole-bridge \
        ros-kinetic-roscpp \
        ros-kinetic-roscpp-core \
        ros-kinetic-roscpp-serialization \
        ros-kinetic-roscpp-traits \
        ros-kinetic-roscpp-tutorials \
        ros-kinetic-roscreate \
        ros-kinetic-rosgraph \
        ros-kinetic-rosgraph-msgs \
        ros-kinetic-roslang \
        ros-kinetic-roslaunch \
        ros-kinetic-roslib \
        ros-kinetic-roslint \
        ros-kinetic-roslisp \
        ros-kinetic-roslz4 \
        ros-kinetic-rosmake \
        ros-kinetic-rosmaster \
        ros-kinetic-rosmsg \
        ros-kinetic-rosnode \
        ros-kinetic-rosout \
        ros-kinetic-rospack \
        ros-kinetic-rosparam \
        ros-kinetic-rospy \
        ros-kinetic-rospy-tutorials \
        ros-kinetic-rosservice \
        ros-kinetic-rostest \
        ros-kinetic-rostime \
        ros-kinetic-rostopic \
        ros-kinetic-rosunit \
        ros-kinetic-roswtf \
        ros-kinetic-rotate-recovery \
        ros-kinetic-rqt-action \
        ros-kinetic-rqt-bag \
        ros-kinetic-rqt-bag-plugins \
        ros-kinetic-rqt-console \
        ros-kinetic-rqt-dep \
        ros-kinetic-rqt-graph \
        ros-kinetic-rqt-gui \
        ros-kinetic-rqt-gui-py \
        ros-kinetic-rqt-launch \
        ros-kinetic-rqt-logger-level \
        ros-kinetic-rqt-moveit \
        ros-kinetic-rqt-msg \
        ros-kinetic-rqt-nav-view \
        ros-kinetic-rqt-plot \
        ros-kinetic-rqt-pose-view \
        ros-kinetic-rqt-publisher \
        ros-kinetic-rqt-py-common \
        ros-kinetic-rqt-py-console \
        ros-kinetic-rqt-robot-dashboard \
        ros-kinetic-rqt-robot-monitor \
        ros-kinetic-rqt-robot-steering \
        ros-kinetic-rqt-runtime-monitor \
        ros-kinetic-rqt-service-caller \
        ros-kinetic-rqt-shell \
        ros-kinetic-rqt-srv \
        ros-kinetic-rqt-tf-tree \
        ros-kinetic-rqt-top \
        ros-kinetic-rqt-topic \
        ros-kinetic-rqt-web \
        ros-kinetic-rviz \
        ros-kinetic-self-test \
        ros-kinetic-sensor-msgs \
        ros-kinetic-shape-msgs \
        ros-kinetic-slam-gmapping \
        ros-kinetic-smach \
        ros-kinetic-smach-msgs \
        ros-kinetic-smach-ros \
        ros-kinetic-smclib \
        ros-kinetic-stage \
        ros-kinetic-stage-ros \
        ros-kinetic-std-msgs \
        ros-kinetic-std-srvs \
        ros-kinetic-stereo-msgs \
        ros-kinetic-teb-local-planner \
        ros-kinetic-tf \
        ros-kinetic-tf-conversions \
        ros-kinetic-tf2 \
        ros-kinetic-tf2-eigen \
        ros-kinetic-tf2-geometry-msgs \
        ros-kinetic-tf2-kdl \
        ros-kinetic-tf2-msgs \
        ros-kinetic-tf2-py \
        ros-kinetic-tf2-ros \
        ros-kinetic-tf2-sensor-msgs \
        ros-kinetic-topic-tools \
        ros-kinetic-trajectory-msgs \
        ros-kinetic-turtle-actionlib \
        ros-kinetic-turtle-tf \
        ros-kinetic-turtle-tf2 \
        ros-kinetic-turtlesim \
        ros-kinetic-urdf \
        ros-kinetic-urdf-parser-plugin \
        ros-kinetic-urg-c \
        ros-kinetic-urg-node \
        ros-kinetic-uuid-msgs \
        ros-kinetic-velodyne \
        ros-kinetic-velodyne-driver \
        ros-kinetic-velodyne-laserscan \
        ros-kinetic-velodyne-msgs \
        ros-kinetic-velodyne-pointcloud \
        ros-kinetic-vision-opencv \
        ros-kinetic-visualization-marker-tutorials \
        ros-kinetic-visualization-msgs \
        ros-kinetic-voxel-grid \
        ros-kinetic-webkit-dependency \
        ros-kinetic-xacro \
        ros-kinetic-xmlrpcpp \
        ros-kinetic-robot-self-filter \
        vim nano pciutils wget && \
    rm -rf /var/lib/apt/lists/*

ENV TT_ROOT=/home/rosmaster/TigerTaxi \
    USERNAME=rosmaster

# User setup (and misc. packages)
RUN apt-get update && apt-get install -y sudo gnome-terminal gdb python-gi python-pip && rm -rf /var/lib/apt/lists/*
RUN pip install -U playsound
# Add new sudo user
RUN useradd -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo $USERNAME && \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
        chmod 0440 /etc/sudoers.d/$USERNAME && \
        usermod  --uid 1000 $USERNAME && \
        groupmod --gid 1000 $USERNAME

RUN echo "source /opt/ros/kinetic/setup.bash" >> /home/rosmaster/.bashrc && \
    echo "source /home/rosmaster/TigerTaxi/tt_core/catkin_ws/devel/setup.bash" >> /home/rosmaster/.bashrc && \
    echo "alias tt_start='/home/rosmaster/TigerTaxi/tt_start.sh'" >> /home/rosmaster/.bashrc

USER rosmaster

WORKDIR /home/rosmaster/

