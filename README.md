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

