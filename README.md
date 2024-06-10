# Docker

## What is a container


### High level apporch
It seems like a lighting VM


### Low level apporch


## The building blocks


## Container runtimes

* Namespace
* Control Groups
* Union file systems

## Docker Networking (Bridge Network)
* Bridge Network
* Host Network
* None Network
* Overlay Network
* Macvlan Network
* Network Plugin

## Docker Storage

## Docker Volume



## Commands

### Image
### Container


# Docker Composer

# What need to be considered when designing a Dockerfile

## About out-of-memory issue

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