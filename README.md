# Config Your Docker In The Efficient Way

# Table of Contents
* Docker
* Dpcker Composer
* Docker Swarm
* Docker Kubernetes

# Docker

## What is a container

1. Container is not a VM, it is a process that runs in an isolated environment.
2. The process inside the container is isolated from the host machine and other containers. And it be limited to the resources(CPU, memory, storage) that it can use.

## How the Docker works internally (background knowledge)

### Docker Engine

* Docker Daemon
* Docker Client
* Docker REST API
* Docker CLI

### Container runtimes concepts

* Namespace
* Control Groups
* Union file systems

### Namespace

* PID Namespace
    * Each container has its own PID namespace, which means that the process inside the container can only see the processes that are running inside the container.
* Network Namespace
    * Each container has its own network namespace, which means that the network interfaces, routing tables, and firewall rules are isolated from the host machine and other containers.
* Mount Namespace
    * Each container has its own mount namespace, which means that the file system is isolated from the host machine and other containers.
* IPC Namespace
    * Each container has its own IPC namespace, which means that the inter-process communication is isolated from the host machine and other containers.
* UTS Namespace
    * Each container has its own UTS namespace, which means that the hostname and domain name are isolated from the host machine and other containers.

### Control Groups (cgroups)
* Cgroups are used to,
    * **limit the resources**
    * **prioritize the resources**
    * **monitor the resources**
* The resources that can be limited, prioritized, and monitored using cgroups are,
    * CPU
    * Memory
    * Storage
    * Network
    * Devices

### Union File Systems

* Union file systems are used to create a layered file system for the container.
* The layered file system is created by stacking multiple file systems on top of each other.
* The layered file system is created using the following layers,
    * Read-only layer
    * Read-write layer
    * Container layer
* only the container layer(top layer) is writable, the other layers are read-only.

## Networking

* Bridge Network
    * Default network in Docker, each container is connected to a bridge network then all the containers are connected to the host machine.
* Host Network
    * The container is connected to the host network, which means that the container can access the host machine's network interfaces, routing tables, and firewall rules.
    * Performance is better than the bridge network because there is no overhead of the bridge network, but it is less secure because the container can access the host machine's network interfaces, routing tables, and firewall rules.
* None Network
    * The container is not connected to any network, which means that the container cannot access the network.
* Overlay Network
    * The container is connected to an overlay network, which means that the container can communicate with other containers that are connected to the same overlay network.

## Docker Storage


## Commands

### Entrypoint
Specifies the command that will be executed when the container starts. The `ENTRYPOINT` instruction can be overridden by passing a command to the `docker run` command.

```Dockerfile
ENTRYPOINT ["executable", "param1", "param2"]
```

### Expose

The container listens on the specified network ports at runtime. The `EXPOSE` instruction does not actually publish the port. It functions as a type of documentation between the person who builds the image and the person who runs the container, about which ports are intended to be published.

```Dockerfile
EXPOSE <port>
```

### CMD

`CMD` is used to provide default arguments for the `ENTRYPOINT` instruction.
If no `ENTRYPOINT` is specified, the `CMD` instruction will be the command that is run when the container starts.

```Dockerfile
CMD ["executable","param1","param2"]
```

### Dockerfile `ENTRYPOINT` vs Docker-Composer `command`

* We can config the `ENTRYPOINT` in the Dockerfile and the `command` in the Docker-Composer for the further configuration.
* It can make the Dockerfile more reusable and **flexible**.

```Dockerfile
# Dockerfile
# ...
ENTRYPOINT ["ngrok"]
```

```yaml
# docker-compose.yml
services:
  my-service:
    command: ["start", "--all", "--config", "/etc/ngrok.yml"]
# ...
```

* In this example, the `ENTRYPOINT` is set to `ngrok` in the Dockerfile, and the `command` is set for the start command in the Docker-Compose file.

* Conclusion
    * `ENTRYPOINT` is used to define the default executable for the container and it is fixed.
    * `command` is used to provide additional arguments to the `ENTRYPOINT` instruction and it is flexible.
    * **When we need to change the parameters we don't need to rebuild the image.**

### Image
### Container

# What need to be considered when designing a Dockerfile

## CPU

### Why CPU limit is important

* To prevent one container from consuming all the CPU resources on the host machine.
* To ensure that all containers have a fair share of CPU resources.
* To prevent one container from affecting the performance of other containers.

### How to set CPU limit

Docker allows you to set CPU limits for containers using the `--cpus` flag when running the container.

* The `--cpus` flag specifies the maximum number of CPU cores that the container can use.
* The `--cpuset-cpus` flag specifies the specific CPU cores that the container can use.
    * Reserved CPU cores for the service
    * Avoid processed bouncing between CPU

```bash
docker run --cpus 0.5 my-image
```
* 0.5 means that the container can use 50% of the CPU core.

```bash
docker run --cpuset-cpus 0,1 my-image
```
* 0,1 means that the container can use CPU cores 0 and 1.


### CPU Limits and Container Performance
While CPU limits offer benefits in containerized environments, they can also impact container performance in some scenarios. Let's delve deeper into this with an explanation and an example.

#### Performance Impact of CPU Limits

Throttling and Reduced Frequency: Setting a CPU limit to N% allocates CPU resources proportionally. If a container demands more, it experiences throttling, lowering the CPU's operating frequency. This reduced frequency translates to less work done per clock cycle, hindering the container's overall performance.

Context Switching: Containerized environments involve the OS managing multiple containers on the same host, leading to frequent context switching. When a container's CPU usage is limited, tasks take longer, resulting in more context switching and further impacting performance.

Example: CPU Limit Impact

Imagine a dual-core CPU host running a single container with a 50% CPU limit.

Normal Operation: At full capacity, the container utilizes one entire CPU core, performing well.

Limit Impact: With a 50% limit, even if the container needs more CPU, it's restricted to half the processing power. The system throttles the CPU, reducing work done per clock cycle. Additionally, limited CPU resources lead to longer task execution times and more context switching, further hindering performance.

Conclusion

CPU limits prevent containers from monopolizing resources and impacting other programs. However, they can affect container performance under certain conditions. The decision to set CPU limits and their values depends on your specific needs and performance requirements.



## Memory

### About out-of-memory issue

Each service should have its own container to avoid one of service out-of-memory issue affect other services.

- Soft limit:
    - The OS will look at the memory usage of the container(Cgroup) and if it exceeds the soft limit, the OS will start to reclaim memory from it, which can cause the container to slow down due to page faults.
    - If the container continues to consume memory beyond acceptable limits, the following steps will be taken:
        1. The container will be sent a `SIGKILL` signal to terminate it.
        2. The container will be given 30 seconds to shut down gracefully

- Hard limit:
    - Will trigger per-group OOM killer, which will kill the container that exceeds the hard limit.
    - The container will be sent a `SIGKILL` signal immediately when it exceeds the hard limit.

- Instead of randomly killing something inside the cgroup,
    * Setup oom-notifier
    * When the hard limit is reached
        * freeze all the processes in the cgroup
        * notify the user space, instead of going rampage and killing something
            * The user space can decide what to do
                * kill something
                * increase the memory limit
                * mirgate the container to another host
            * Then unfreeze the processes

### How to set memory limit

Docker allows you to set memory limits for containers using the `--memory` flag when running the container.

soft limit

```bash
docker run --memory 125m --memory-reservation=400m --memory-swap 1g my-image
```
* The `--memory` flag specifies the maximum amount of memory that the container can use in **hard limit**.
* The `--memory-reservation` flag specifies the minimum amount of memory that the container can use in **soft limit**.
* The `--memory-swap` flag specifies the maximum amount of memory and swap space that the container can use.

# Docker Composer

* Docker Compose is a tool that is used to define and run multi-container Docker applications.

## What is composer version

* The version of the Docker Compose file format that is used in the `docker-compose.yml` file.
* Most of time just use the latest version to have the latest features and avoid the deprecated features.

### What is the different between version 2 and 3

* Versions 2 and 3 have some minor differences especially around resource constraints
* version 2 generally directly mirrors docker run options and version 3 has some options that are compatible with Swarm but are ignored if you aren't using it.
* Generally been to use version: `3.8`, which is the most recent version of the file format that both Compose implementations support. If I need the resource constraints then I'll use version: `2.4` instead

```yaml
version: '3.8'
...
```

> [!TIP]
> The `version` key is not required in the `docker-compose.yml` file. If the `version` key is not specified, Docker Compose will use the latest version of the Docker Compose file format.

> [!TIP]
> Docker is planning to desupport the Python version of Compose by the end of June 2023, which will reduce the number of options in this matrix. In particular, this will mean the version: line is ignored always, and any file will be interpreted as per the Compose Specification and not one of the older file formats.

## How to setup service in Docker Compose

### Setup service from official image

```yaml
services:
  nginx-service:
    image: nginx:latest
```

### Setup service from your own image

```yaml
services:
  my-service:
    context: ./<path-to-dockerfile>
    dockerfile: Dockerfile
```

## How to config ports in Docker Compose

* The `ports` key is used to specify the ports that are exposed by the service.
* The format of the `ports` key is `<host-port>:<container-port>`.
* In the example below, the service is exposed on port `8080` on the host machine and port `80` in the container.

```yaml
services:
  my-service:
    ports:
      - "8080:80"
```

## How to setup networking

* The `networks` key is used to specify the networks that the service is connected to.
* The default network is the bridge network
* The `driver` key is used to specify the driver that is used to create the network.
    * The default driver is the bridge driver
    * other drivers are `overlay`, `macvlan`, `none`, `host`

```yaml
services:
  my-service:
    networks:
      <network-name>:
        aliases:
          - <alias-name>
        driver: <driver-name>
```

## How to setup environment variables

* The `environment` key is used to specify the environment variables that are passed to the container.
* The format of the `environment` key is `<key>=<value>`.
* The benefit of using environment variables is that they can be used to configure the container at runtime without modifying the Dockerfile.

```yaml
services:
  my-service:
    environment:
      - MY_ENV_VAR=my-value
```

## Volume

* volume is used to persist data between container restarts.
* The benefit of using volumes is that they can be used to persist data between container restarts.
* Tpyes of volumes
    * Anonymous volume
    * Named volume
    * Host volume

### Named volume

* Named volumes are created by Docker and can be reused by multiple containers.

```yaml
services:
  my-service:
    volumes:
      - <volume-name>:<container-path>
```

### Bind Mounts

* Bind mounts are used to mount a directory on the host machine to a directory in the container.

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

* In the example above, the `./html` directory on the host machine is mounted to the `/usr/share/nginx/html` directory in the container.

### Sharing Volumes Between Services

* Volumes can be shared between services by using the same volume name in the `volumes` key of each service.

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - shared-data:/usr/share/nginx/html

  db:
    image: mysql:latest
    volumes:
      - shared-data:/app/data
```

* In this example:
    * A named volume shared-data is defined and shared between web and db services.
    * This configuration allows both services to read from and write to the same volume, facilitating data sharing.

## Exception handling

* The `restart` key is used to specify the restart policy for the service.
  * The `no` option specifies that the container should not be restarted if it stops.
    * Suitable for services that are not critical and not required to be running all the time.
  * The `always` option specifies that the container should always be restarted if it stops.
    * Suitable for critical services that need to be running all the time.
  * The `on-failure` option specifies that the container should be restarted if it stops with a non-zero exit code.
  * The `unless-stopped` option specifies that the container should always be restarted unless it is explicitly stopped by the user.
    * Suitable for services that need to be running all the time but can be stopped by the user.

```yaml
services:
  my-service:
    restart: [always|no|on-failure|unless-stopped]
```

# Docker Swarm
* Docker Swarm is a tool that is used to create and manage a cluster of Docker nodes.

# Docker Kubernetes
* Kubernetes is a container orchestration tool that is used to deploy, scale, and manage containerized applications.

## What is the difference between Docker Swarm and Kubernetes

# References
[Memeory Cgroup concepts](https://github.com/LeaYeh/wild_notes/blob/main/kernel/cgroup.md)

