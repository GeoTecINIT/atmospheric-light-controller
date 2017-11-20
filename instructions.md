# Atmospheric Light Controller (ALC)

Instructions for launching the installation

Processing controller: 
/virtual_light/launcher.pde (for now, the tester)

Mongodb: 
- Database: atmospheric-light-controller
- Collection: logs, vals, energysaver
>> To have launchd start mongodb now and restart at login:
  brew services start mongodb
>> Or, if you don't want/need a background service you can just run:
  mongod --config /usr/local/etc/mongod.conf

Nodejs server: 
	sudo service mongodb start
	node /webserver/server.js (OSC-NODE connector)
	DEBUG MODE: DEBUG=socket.io* node

MAX audio controller:
- Pendent

