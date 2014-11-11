#!/bin/bash

set -eu

COMMAND=$1
SERVICE_NAME=${PWD##*/}
DIR=`pwd`
SRCDIR="$DIR"
CONTAINER_PORT=10000

create_upstart_config() {
  local config_file=$1
  local public_port=$2
  local image_name=$3
  local container_name=$4
  local logdir=$5
  local datadir=$6

  local config="
  description \"${SERVICE_NAME}\""

  config="$config"'
  start on filesystem and started docker
  stop on runlevel [!2345]
  respawn
  respawn limit 10 30
  limit nofile 32000 32000

  script
    # Wait for docker to finish starting up first.
    FILE=/var/run/docker.sock
    while [ ! -e $FILE ] ; do
      inotifywait -t 2 -e create $(dirname $FILE)
    done
  '
  config="$config""
    HOME=$HOME exec docker run --rm -e PORT=$CONTAINER_PORT --env-file=$config_file -v $datadir:/data -v $SRCDIR:/app -w /app -p $public_port:$CONTAINER_PORT --name $container_name $image_name bash /app/run.sh 1>>"$logdir/stdout.log" 2>> "$logdir/stderr.log"
  end script
  "
  
  echo "$config"
}

fetch() {
  local dir=$1
  (cd $dir && git fetch --all && git reset --hard origin/master)
}

build() {
  local env=$1
  local config_dir=$2
  local config_file="$config_dir/$SERVICE_NAME/$env.env"
  local public_port=$(grep -Po 'LOCAL_PORT=\K.*' $config_file)
  local image_name=${SERVICE_NAME}.stocard:${env}
  local container_id=$(uuidgen | md5sum | head -c6)
  local container_name=${env}.${SERVICE_NAME}.stocard-${container_id}
  local logdir="$HOME/logs/$SERVICE_NAME"
  local datadir="$HOME/data/$SERVICE_NAME"
  echo "Building $SERVICE_NAME with $config_file"
  mkdir -p "$logdir"
  mkdir -p "$datadir"
  docker build --tag="$image_name" - < Dockerfile
  create_upstart_config $config_file $public_port $image_name $container_name $logdir $datadir > /etc/init/${SERVICE_NAME}.conf
}

run() {
  local command="$@"
  echo "running command: $command"
  local test_image_name=${SERVICE_NAME}.stocard:test
  local container_name=test.${SERVICE_NAME}.stocard
  docker build --tag="$test_image_name" - < Dockerfile
  docker run -t -i --rm -v $SRCDIR:/app:rw -w /app $test_image_name $command
}

upgrade() {
  local github_source=$1
  local git_ref=$2
  local source_url="https://raw.githubusercontent.com/$github_source/$git_ref/fly.sh"
  mkdir -p /opt/fly
  echo "downloading latest version of fly from $source_url"
  curl -sL $source_url > /tmp/fly.sh
  mv /tmp/fly.sh /opt/fly/fly.sh
  chmod +x /opt/fly/fly.sh
  rm -f /usr/local/bin/fly
  ln -s /opt/fly/fly.sh /usr/local/bin/fly
  echo "fly upgraded"
}

case $COMMAND in
  fetch)
    echo "updating container"
    fetch $DIR
  ;;
  fetch-config)
    echo "updating config"
    fetch $CONFIG_DIR
  ;;
  build)
    ENV=$2
    build $ENV $FLY_CONFIG_DIR
  ;;
  deploy)
    ENV=$2
    fetch $DIR
    fetch $CONFIG_DIR
    build $ENV $FLY_CONFIG_DIR
    service $SERVICE_NAME restart
  ;;
  run)
    ARGS="${@:2}"
    run $ARGS
  ;;
  upgrade)
    GITHUB_SOURCE=Stocard/fly
    GIT_REF=master
    if [ $# -gt 1 ]; then
      GITHUB_SOURCE=$2
    fi
    if [ $# -gt 2 ]; then
      GIT_REF=$3
    fi
    upgrade $GITHUB_SOURCE $GIT_REF
  ;;
  *)
    echo "Sorry, I don't know $COMMAND"
  ;;
esac
