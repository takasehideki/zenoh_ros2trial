# zenoh_ros2trial

Quick trial a.k.a practice to learn the marriage of ROS 2 and Zenoh :D

This repository provides the instructions for demonstrations presented in [ROSJP#54](https://rosjp.connpass.com/event/304753/) ([SpkearDeck (T.B.A)](https://speakerdeck.com/takasehideki/)).
The operation of this repository is mainly confirmed on my M1 Mac (arm64) machine.
Please let me know if anyone has managed to get it to work on an x64 (amd64) machine.
Also, if you have any problems (especially on x64 (amd64) machines), please feel free to let me know via [Issues](https://github.com/takasehideki/zenoh_trial/issues).

In a nutshell, I hope you will reproduce them and confirm the awesome power of Zenoh for ROS 2 ecosystem ASAP!

## Demo 1: Review of FA_Study#18

The first demonstration is to be amazed at how easy Zenoh is to connect in various programming languages and network configurations, which has been presented at FA_Study#18 ([connpass](https://fa-study.connpass.com/event/301303/) | [SpeakerDeck](https://speakerdeck.com/takasehideki/nansikairoirotunagaruzenohnoshao-jie)).

### Preliminary

Clone the repository for FA_Study#18, deploy the Docker container, and compile each node. 

```
git clone https://github.com/takasehideki/zenoh_trial
cd zenoh_trial
docker run -it --rm -v `pwd`:/zenoh_trial -w /zenoh_trial --name zenoh_bridge takasehideki/zenoh_trial
# continue in the container
cd zenoh_native
cargo build
cd ../zenoh_elixir
mix deps.get
mix compile
exit
```

### Operation

Operate Zenoh nodes implemented in various languages.

- 1st terminal: Rust publisher
```
docker run -it --rm -v `pwd`:/zenoh_trial -w /zenoh_trial --name zenoh_bridge takasehideki/zenoh_trial
./zenoh_native/target/debug/pub
```
- 2nd terminal: Rust subscriber
```
docker exec -it zenoh_bridge /bin/bash
./zenoh_native/target/debug/sub
```
- 3rd terminal: Python publisher
```
docker exec -it zenoh_bridge /bin/bash
python3 zenoh_python/pub.py
```
- 4th terminal: Elixir publisher
```
docker exec -it zenoh_bridge /bin/bash
cd zenoh_elixir
iex -S mix
iex()> ZenohElixir.Pub.main
```

Then, also operate MQTT and DDS nodes along with awesome Zenoh bridges!

- 5th terminal: Zenoh bridge for MQTT
```
docker exec -it zenoh_bridge /bin/bash
zenoh-bridge-mqtt
```
- 6th terminal: MQTT subscriber
```
docker exec -it zenoh_bridge /bin/bash
mosquitto_sub -d -t key/expression
```
- 7th terminal: Zenoh bridge for DDS
```
docker exec -it zenoh_bridge /bin/bash
zenoh-bridge-dds
```
- 8th terminal: DDS publisher
```
docker exec -it zenoh_bridge /bin/bash
python3 zenoh_dds/pub.py
```

And one more thing, if you have already installed `zenohd` on the host, try subscribing to them!!

- 9th terminal: Zenoh subscriber on the **host**
```
python3 zenoh_python/sub.py
```
- 10th terminal: Zenoh router in the _container_
```
docker exec -it zenoh_bridge /bin/bash
zenohd -e tcp/<host_ip>:7447
```
- 11th terminal: Zenoh router on the **host**
```
docker exec -it zenoh_bridge /bin/bash
zenohd
```

## Demo 2: rmw_zenoh_cpp

The second demonstration is to observe the development status of [rmw_zenoh_cpp](https://github.com/ros2/rmw_zenoh), that is a promising alternative RMW implementation based on [Zenoh](https://zenoh.io/).

### Preliminary

Pre-built Docker image has been published on [Docker Hub](https://hub.docker.com/repository/docker/takasehideki/zenoh_ros2trial)

```
docker run -p 6080:80 --security-opt seccomp=unconfined --shm-size=512m takasehideki/zenoh_ros2trial
```

After that, browse http://127.0.0.1:6080/.

The Dockerfile is based on [Tiryoh/docker-ros2-desktop-vnc:rolling](https://github.com/Tiryoh/docker-ros2-desktop-vnc/blob/master/rolling/Dockerfile) which is released under the Apache-2.0 license.
Thank you so much @Tiryoh for maintaining a wonderful Docker solution!

#### Build the image and use it locally

Please enjoy the coffee break because building the image may take too long time :-

```
cd <git_cloned_dir>
docker build -t zenoh_ros2trial .
docker run -p 6080:80 --security-opt seccomp=unconfined --shm-size=512m zenoh_ros2trial
```

#### MEMO for ME: build and push the image to Docker Hub

The following operation has been confirmed on my M1Mac.

```
docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx build --platform linux/amd64,linux/arm64 -t takasehideki/zenoh_ros2trial . --push
```
