var express = require('express');
var app = express();
var clientSessions = require("client-sessions");
var crypto = require('crypto');
var server = require('http').Server(app);
var io = require('socket.io')(server);
var schedule = require('node-schedule');
var bodyParser = require('body-parser');
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({ extended: true })); 


var maxUsers = 1; // Quantity of users allowed in the room (not in use, to be implemented)
var numUsers = 0; // Quantity of users in the room
var waitinglist = 0; // Quantity of users connected and waiting for enter the room
var theUser; // the user session to save in db
var theRoom = 'control room'; // the control room
var roomEmpty = true; // if the room is empty, used to check before allow access
var roomUser = {userid: '', socketid: ''}; // Who is in the room
var maxTime = 200; //set maximum seconds of practice 60 = 1m
var countdown = maxTime;  // the countdown that is send to 
var countLive = false; // if it is counting
var inter; // the count interval (unique for all the interface)
var theOption; //the current option running
var energySaver = 0; // Energy Saving mode (between around 23:30 and 17hs) if 1 thet system will be off. 
 
// *** NODE-OSC Connection ***
//using node-osc library: 'npm install node-osc'
//this will also install 'osc-min'
var osc = require('node-osc');
//listening to OSC msgs to pass on to the web via nodejs
var oscServer = new osc.Server(3334, '127.0.0.1');
//sending OSC msgs to a client
var oscClient = new osc.Client('127.0.0.1', 3333);

// *** SESSIONS ***
// Initiate sessions
app.use(clientSessions({
  secret: 'oiUTERDLdTVuru3BRFaPt9rLZ' // CHANGE THIS!
}));
//connect to mongodb for log users
var MongoClient = require('mongodb').MongoClient
  , assert = require('assert');
var MongoUrl = 'mongodb://localhost:27017/atmospheric-light-controller';
// ** DELETE IF IT IS NOT NECESSARY ** 
MongoClient.connect(MongoUrl, function(err, db) {
  assert.equal(null, err);
  console.log("Connected successfully to mongodb server");
        
	  db.createCollection("vals", function(err, res) {
	      if (err) console.log(err);
	    });
	  db.createCollection("logs", function(err, res) {
	        if (err) console.log(err);
	     });
	 db.createCollection("energysaver", function(err, res) {
		  if (err) console.log(err);
		  });
		  
  

  db.close();
});

//  ***  Energy Saver mode settings (node-schedule)*** 
// START
var sRule = new schedule.RecurrenceRule();
sRule.dayOfWeek = [0, new schedule.Range(0, 5)]; // 0 (MONDAY) to 5(SATURDAY)
sRule.hour = 17; //17hs
sRule.minute = 0;
 
var sES = schedule.scheduleJob(sRule, function(){
 	var time = new Date(Date.now());
  	energySaver = 0;
  	var tMsg = 'Energy Saver is off at '+ time;
 	saveDb('energysaver', {status: energySaver, timestamp: time}, tMsg);
	
	theOption = 'C';
	// sending the variable to Processing
	var msg =  new osc.Message('/clientMsg')
	msg.append(theOption)
	oscClient.send(msg)
});

// END
var fRule = new schedule.RecurrenceRule();
fRule.dayOfWeek = [0, new schedule.Range(0, 5)]; // 0 (MONDAY) to 5(SATURDAY)
fRule.hour = 23; //23:30hs
fRule.minute = 30;
 
var fES = schedule.scheduleJob(fRule, function(){
	 var time = new Date(Date.now());
	 energySaver = 1;
 	 var tMsg = 'Energy Saver is on at '+ new Date(Date.now());
  	saveDb('energysaver', {status: energySaver, timestamp: time}, tMsg);
	
		theOption = 'X';
		// sending the variable to Processing
		var msg =  new osc.Message('/clientMsg')
 		msg.append(theOption)
 		oscClient.send(msg)
	
});

// *** App Route settings *** //
app.use('/static', express.static(__dirname + '/web-export'));
app.get('/',function(req, res) {	
		
	   //check if cookie session is already set
	   if (req.session_state.username) { 
		   console.log('User connected:'+req.session_state.username);
		   theUser = req.session_state.username;
	     } else { //if not cookie found, assigns new token as username
			 var token = crypto.randomBytes(24).toString('hex');
		     req.session_state.username = token;
		     console.log('User created:'+req.session_state.username);
			theUser = req.session_state.username;
	     }
	  		// load form
   	  	 if(theUser){
			 res.sendFile(__dirname +"/web-export/index.html");
		 }else{
			 res.send('Hubo un problema cargando el sitio. Lo sentimos!');
   	  	 }	 
	});
app.post('/option',function(req, res) {
	var option = req.body.option; //get option from form	
	theOption = option;	
		// save selected option in database
	console.log('option received: '+option);
		MongoClient.connect(MongoUrl, function(err, db) {
		  assert.equal(null, err);
		  var MongoCollection = db.collection('logs');
		  
		  var tempOption = {  user: req.session_state.username , option: option, timestamp: new Date(Date.now()) };
		  MongoCollection.insert(tempOption, function(err, result) {
              if (!err) {
				  console.log(result);
                  return res.send(result);
              } else {
				  console.log(err);
				  return res.send(err);
              }
		    });
			console.log(option+' saved in db.');
		  db.close();

		});
		// sending the variable to Processing
		var msg =  new osc.Message('/clientMsg')
 		msg.append(req.body.option)
 		oscClient.send(msg)
    });
app.post('/poll', function(req, res){
	var pollVal = req.body.val;
	var pollEmo = req.body.emo;
	var option = req.body.option;
	console.log('Valoration received is  '+pollVal + ' with '+pollEmo+' emotion');
	
	
	MongoClient.connect(MongoUrl, function(err, db) {
	  assert.equal(null, err);
	  	var MongoCollection = db.collection('vals');
    	var tempOption = {  user: req.session_state.username, option: option, val: pollVal, emo: pollEmo, timestamp: new Date(Date.now()) };
		MongoCollection.insert(tempOption, function(err, result) {
          if (!err) {
			  console.log(result);
              return res.send(result);
          } else {
			  console.log(err);
			  return res.send(err);
          }
	    });
		console.log('Value saved in db.');
	  db.close();

	});
	
});
// deletes cokie session
app.get('/logout', function (req, res) {
console.log('User deleted:'+req.session_state.username);
  req.session_state.reset();
  res.redirect('/');
});

//nodejs server listens to msgs on port 80
var server = server.listen(80);

// *** //
// Socket configuration
// *** //

//some web-client connects
io.on('connection', function (socket) {
	// when connected sends first user information and room state
	socket.emit('your user', {user: theUser, socketid: socket.id});
	socket.emit('check room', {status: roomEmpty, user: roomUser.userid, option: theOption});
	socket.emit('energy saver',{energySaver: energySaver});
	waitinglist++;
	socket.emit('waiting',{waiting: waitinglist});
	socket.broadcast.emit('waiting',{waiting: waitinglist});
	//when user enters the control room
	  socket.on('enter user', function (data) {
		waitinglist--;	  
		numUsers++;
		roomEmpty = false;
		roomUser.userid = data.user;
		roomUser.socketid = socket.id;
		socket.emit('energy saver',{energySaver: energySaver});
		socket.emit('check room', {status: roomEmpty, user: roomUser.userid, option: theOption});
		socket.broadcast.emit('check room', {status: roomEmpty, user: roomUser.userid, option: theOption});
		socket.emit('waiting',{waiting: waitinglist});
		socket.broadcast.emit('waiting',{waiting: waitinglist});
		console.log('User entered the room - User socket: '+roomUser.socketid+' - Current socket: '+socket.id)
		countdown = maxTime;
		if(countLive == true){
			socket.emit('kick user');
			clearInterval(inter);
			console.log('another counter is happening');
		}else if(countLive == false){
			countTime(maxTime, function() {  
				// what happens every second
		  		  countdown--;
				  //console.log(countdown);
		  		  socket.broadcast.emit('timer', { countdown: countdown });
				  socket.emit('timer', { countdown: countdown });
			}, function(){
				// kick user
				socket.emit('kick user');
			});
		  
		}
		});
	
	//some client disconnects
	socket.on('disconnect', function (data) {
		console.log("user disconnected: " + data+' ('+theUser+') at '+ countdown+' miliseconds');
		if(socket.id == roomUser.socketid){
			roomEmpty = true;
			roomUser = {userid: '', socketid: ''};
			countLive = false;
			clearInterval(inter);
			socket.emit('kick user');
			numUsers--;
		}else{
			waitinglist--;
		}
	});
	// when client is kicked or press exit button
    socket.on('empty room', function (data) {
		waitinglist++;
		socket.emit('waiting',{waiting: waitinglist});
		socket.broadcast.emit('waiting',{waiting: waitinglist});
		console.log('User left the room: '+theUser+' - Current Socket: '+roomUser.socketid+' - Current socket: '+socket.id)
		if(socket.id == roomUser.socketid){
		  numUsers--;
	      roomEmpty = true;
	  	  roomUser = {userid: '', socketid: ''};
	  	  countLive = false;
	  	  clearInterval(inter);
	  	  socket.emit('check room',{status: roomEmpty, user: roomUser, option: theOption});
		}
    });
    socket.on('kick user', function (data) { // the client will response "empty room"
  	  socket.emit('kick user');
    });
		//when client ask for room status
  socket.on('check room', (data) =>  socket.emit('check room',{status: roomEmpty, user: roomUser.userid, option: theOption}));
	
});

//counter
function countTime(duration, action, callback) {
		countLive = true;
        var expected = 1;
        var secsLeft;
        var startT = new Date().getTime();

        inter = setInterval(function() {
            //change in seconds
            var sChange = Math.floor((new Date().getTime() - startT) / 1000);

            if (sChange === expected) {
                expected++;
                secsLeft = duration - sChange;
   			 console.log('Seconds left in room :'+secsLeft)
   			 action();
            }

            if (secsLeft === 0) {
                clearInterval(inter);
   			 	callback();
				countLive = false;
            }
        }, 100);
 }
 
 function saveDb(collection, options, msg){
	 
	MongoClient.connect(MongoUrl, function(err, db) {
	  assert.equal(null, err);
	  var MongoCollection = db.collection(collection);
	  MongoCollection.insert(options, function(err, result) {
           if (!err) {
			  console.log(result);
               return result;
           } else {
			  console.log(err);
			  return err;
           }
	    });
		console.log(msg+' saved in db.');
	  db.close();
	});	
 };
