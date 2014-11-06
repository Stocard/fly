#!/bin/bash

set -eu

COMMAND=$1
SERVICE_NAME=${PWD##*/}
DIR=`pwd`
SRCDIR="$DIR"
CONTAINER_PORT=10000

create_upstart_config() {
  local env=$1
  local public_port=$2
  local image_name=$3
  local container_name=$4
  local logdir=$5
  local datadir=$6
  local configdir=$7

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
    HOME=$HOME exec docker run --rm -e PORT=$CONTAINER_PORT --env-file=$configdir/$env.env -v $datadir:/data -v $SRCDIR:/app -w /app -p $public_port:$CONTAINER_PORT --name=$container_name $image_name bash /app/run.sh 1>>"$logdir/stdout.log" 2>> "$logdir/stderr.log"
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
  local public_port=$2
  local configdir=$3
  local image_name=${SERVICE_NAME}.stocard:${env}
  local container_name=${env}.${SERVICE_NAME}.stocard
  local logdir="$HOME/logs/$SERVICE_NAME"
  local datadir="$HOME/data/$SERVICE_NAME"
  mkdir -p "$logdir"
  mkdir -p "$datadir"
  docker build --tag="$image_name" - < Dockerfile
  create_upstart_config $env $public_port $image_name $container_name $logdir $datadir $configdir > /etc/init/${SERVICE_NAME}.conf
}

test() {
  local test_image_name=${SERVICE_NAME}.stocard:test
  local container_name=test.${SERVICE_NAME}.stocard
  docker build --tag="$test_image_name" - < Dockerfile
  docker run -t -i --rm -v $SRCDIR:/app -w /app --name=$container_name $test_image_name npm test
}

upgrade() {
  local source_url='https://raw.githubusercontent.com/Stocard/fly/master/fly.sh'
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
    fetch $DIR
  ;;
  fetch-config)
    CONFIG_DIR=$2
    fetch $CONFIG_DIR
  ;;
  build)
    ENV=$2
    PUBLIC_PORT=$3
    CONFIG_DIR=$4
    build $ENV $PUBLIC_PORT $CONFIG_DIR
  ;;
  deploy)
    ENV=$2
    PUBLIC_PORT=$3
    CONFIG_DIR=$4
    fetch $DIR
    fetch $CONFIG_DIR
    build $ENV $PUBLIC_PORT $CONFIG_DIR
    service $SERVICE_NAME restart
  ;;
  test)
    test
  ;;
  upgrade)
    upgrade
  ;;
  *)
    echo "Sorry, I don't know $COMMAND"
  ;;
esac
