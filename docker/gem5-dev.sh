#!/bin/bash
#
# This script is the front-end execution script for using the gem5-dev
# docker image. To use it, you would run a command like this:
#   docker run -v $GEM5_HOST_WORKDIR:/gem5 -it gem5-dev [<cmd>]
#
# Author: Artur Klauser

#MOUNTDIR#  # substituted during docker build
mountdir=${mountdir:-'/gem5'}
readonly sourcedir="${mountdir}/source"
readonly systemdir="${mountdir}/system"

print_usage() {
  cat << EOF
Usage: gem5-dev <cmd>
Where <cmd> is one of:
  help ............. prints this help message
  install-source ... installs the gem5 git source repository into ${sourcedir}
  install-gcc ...... installs the ALPHA compiler into ${sourcedir}
  update-source .... updates the gem5 git source repository in ${sourcedir}
  install-system ... installs the gem5 ALPHA system images in ${systemdir}
  build ............ builds gem5 ALPHA binary
  shell | bash ..... enters into an interactive shell
EOF
}

check_hostdir_mounted() {
  # The docker image contains a watermark file in ${mountdir} which will
  # only be visible when no volume is mounted.
  if [[ -e "${mountdir}/.in-docker-container" ]]; then
    cat << EOF
No host volume mounted to container's ${mountdir} directory.
Run:
  docker run -v \$GEM5_HOST_WORKDIR:${mountdir} -it gem5-dev [<cmd>]
EOF
    exit 1
  fi
}

# Clone gem5 source repository into ${sourcedir} if it isn't already there.
install_source() {
  check_hostdir_mounted
  if [ ! -e "${sourcedir}/.git" ]; then
    echo "installing gem5 source repository into ${sourcedir} ..."
    git clone https://gem5.googlesource.com/public/gem5 "${sourcedir}"
    cd "${sourcedir}"
    git checkout v19.0.0.0 # Last release that contains ALPHA
  else
    echo "gem5 source repository is already installed."
  fi
}

# Install an ALPHA compiler suitable for gem5
install_gcc() {
  check_hostdir_mounted
  if [ ! -e "${sourcedir}/alphaev67-unknown-linux-gnu" ]; then
    echo "downloading ALPHA compiler into ${sourcedir} ..."
    wget http://www.m5sim.org/dist/current/alphaev67-unknown-linux-gnu.tar.bz2
    tar -xjvf alphaev67-unknown-linux-gnu.tar.bz2
    rm alphaev67-unknown-linux-gnu.tar.bz2
  else
    echo "gcc (alphaev67-unknown-linux-gnu) is already installed."
  fi
}

# Pull updates from gem5 source repository.
update_source() {
  check_hostdir_mounted
  if [[ -e "${sourcedir}/.git" ]]; then
    echo "updating gem5 source repository at ${sourcedir} ..."
    cd "${sourcedir}" || exit 1
    git pull
  else
    echo "gem5 source repository not found at ${sourcedir}."
  fi
}

# Builds the gem5 ALPHA binary.
build() {
  check_hostdir_mounted
  if [[ ! -e "${sourcedir}" ]]; then
    echo "gem5 source repository not found at ${sourcedir}."
    exit 1
  fi

  echo "building gem5 ALPHA binary ..."
  cd "${sourcedir}" || exit 1
  cmd="scons -j $(nproc) build/ALPHA/gem5.opt"
  echo "${cmd}"
  ${cmd}
}

# Starts an interactive shell.
run_shell() {
  check_hostdir_mounted
  echo "To build gem5, run: "
  echo "  cd ${sourcedir}; scons -j \$(nproc) build/ALPHA/gem5.opt"
  cd "${mountdir}" || exit 1
  exec /bin/bash -l
}

main() {
  local cmd
  local -r initial_dir="${PWD}"
  for cmd in "$@"; do
    case "${cmd}" in
      'help') print_usage ;;
      'install-source') install_source ;;
      'install-gcc') install_gcc ;;
      'update-source') update_source ;;
      'build') build ;;
      'shell' | 'bash') run_shell ;;
      -* | +*) set "${cmd}" ;; # pass +/-flags to shell's set command.
      *)
        echo "unkown command '${cmd}'"
        echo
        print_usage
        exit 1
        ;;
    esac
    cd "${initial_dir}" || exit 1
  done
}

main "$@"
