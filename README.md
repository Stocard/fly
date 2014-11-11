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

####`fly fetch-config`
Performs `git fetch` in directory given as environment variable `FLY_CONFIG_DIR` and resets to origin/master.

####`fly build ENVIRONMENT`
Builds a container using the given parameters and creates an upstart config.  
Requires `FLY_CONFIG_DIR` as an environment variable.

####`fly run [command]`
Builds and starts a container and runs `[command]` in it.

####`fly deploy ENVIRONMENT`
Performs `fly fetch`, `fly fetch-config`, `fly build` and `service <SERVICE_NAME> restart`.  
Requires `FLY_CONFIG_DIR` as an environment variable.

####`fly upgrade [github_user/repo] [git_ref]`
Upgrades fly to the latest version.  
Example: `fly upgrade mirkokiefer/fly`  
Defaults to `fly upgrade Stocard/fly master`