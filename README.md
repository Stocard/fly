fly
===

a simple shell script for wrapping services as upstart-managed docker containers.


###Installation

Install the current master (as root):
```shell
mkdir /opt/fly
curl -sL 'https://raw.githubusercontent.com/Stocard/fly/master/fly.sh' > /opt/fly/fly.sh
chmod +x /opt/fly/fly.sh
ln -s /opt/fly/fly.sh /usr/local/bin/fly
```


###Commands

####`fly fetch`
Performs `git fetch` in the current directory and resets to origin/master.

####`fly fetch-config DIRECTORY`
Performs `git fetch` in the given DIRECTORY and resets to origin/master.

####`fly build ENVIRONMENT PUBLIC_PORT CONFIG_DIRECTORY`
Builds a container using the given parameters and creates an upstart config.

####`fly run [command]`
Builds and starts a container and runs `[command]` in it.

####`fly deploy ENVIRONMENT PUBLIC_PORT CONFIG_DIRECTORY`
Performs `fly fetch`, `fly fetch-config`, `fly build` and `service <SERVICE_NAME> restart`.

####`fly upgrade`
Upgrades fly to the latest version.