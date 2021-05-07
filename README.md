# Development environment for [gem5](http://gem5.org) ALPHA.
The Dockerfile in this repository creates the gem5-dev docker image that
includes the build environment necessary to compile and run the gem5 ALPHA
simulator. The image is structured in such a way that it assumes
the user mounts a gem5 working directory residing on the host machine into
the container running the gem5-dev image. The docker image hosts the full
build environment, whereas the gem5 working directory holds the gem5 source
code, compile artifacts, and the image files for full system simulation if
desired.

The gem5-dev docker image is structured to run as a binary supporting several
commands:
  * **install-source**: installs the gem5 sources from git in the working
     directory
  * **update-source**: updates the gem5 sources
  * **build**: builds the gem5 ALPHA binary
  * **shell**: enters into an interactive shell in the container running the
    gem5-dev image in which the developer can work within the build
    environment; above commands are also available within this shell as
    commands to the gem5-dev tool

## How to build the docker image
Build the gem5-dev image like this:
```
docker build -t gem5-dev docker
```
This creates the docker image called gem5-dev.
Docker hub also holds a pre-built image under [arturklauser/gem5-dev](https://hub.docker.com/r/arturklauser/gem5-dev/). To use this image simply use `docker pull arturklauser/gem5-dev` or use it in your own Dockerfile:
```
FROM arturklauser/gem5-dev
...
```

## How to use the docker image
### Setting up the gem5 working directory
Create a directory on the host system which you'd like to use as gem5
working directory. It will contain the sources and build artifacts (e.g.
.o and binary files) You'll need several GBs of
space for this (currently about 6 GB, but it depends on your builds).
Let's call that directory $GEM5_WORKDIR.

### Installing and building gem5
Now you can run the gem5-dev docker image and use it to get the gem5 source
and compile it:
```sh
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev install-source
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev build
```
Note that the gem5 sources will be installed into a directory called
'source' inside $GEM5_WORKDIR.

### Running gem5
Once you built gem5, to run it inside the container you need to do the following:
```sh
# on the host
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev shell
# now in the docker container
cd source
build/ALPHA/gem5.opt configs/learning_gem5/part1/simple.py # or any other script
```

### Modifying source code
The gem5-dev build environment doesn't contain any editor, so it's not a
convenient place to modify the gem5 sources. The method of development with
the gem5-dev docker image is that you edit the gem5 source files on your
host machine on which it is assumed you have already set up whatever source
code editing environment you prefer. Since all the source code lives in the
gem5 working directory on the host, your host editing environment has full
native access to the source files. Once you're done with a modification and
want to test it, simply run the compile step inside the gem5-dev container.
Here is a sample development cycle:
```sh
# on the host
vim $GEM5_WORKDIR/source/src/arch/some_file.cc
# edit that file, then compile it
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev build
```

Alternatively, you could also use a second terminal in which you keep a
shell open in the gem5-dev container and perform your compiles there:

*Terminal 1:*
```sh
# on the host
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev shell
# now in the docker container
cd source
```
*Terminal 2:*
```sh
# on the host
edit $GEM5_WORKDIR/source/src/arch/some_file.cc
# editing that file ...
```
*Terminal 1:*
```sh
# still in the docker container
scons -j $(nproc) build/ALPHA/gem5.opt
# if it compiles, run it, otherwise back to editing on the host
build/ALPHA/gem5.opt configs/learning_gem5/part1/simple.py
```
