var express = require('express');
var app = express();
var clientSessions = require("client-sessions");
var crypto = require('crypto');
var server = require('http').Server(app);
var io = require('socket.io')(server);
var bodyParser = require('body-parser');
app.use(bodyParser.json()); 
app.use(bodyParser.urlencoded({ extended: true })); 


var maxUsers = 1;
var numUsers = 0;
var theUser;
var theRoom = 'control room';
var roomEmpty = true;
var roomUser = '';
var maxTime = 60000; //set maximum time of practice 60k = 1m
var countdown = maxTime; 

//using node-osc library: 'npm install node-osc'
//this will also install 'osc-min'
var osc = require('node-osc');
//listening to OSC msgs to pass on to the web via nodejs
var oscServer = new osc.Server(3334, '127.0.0.1');
//sending OSC msgs to a client
var oscClient = new osc.Client('127.0.0.1', 3333);

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
  db.close();
});



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
		// save selected option in database
		MongoClient.connect(MongoUrl, function(err, db) {
		  assert.equal(null, err);
		  var MongoCollection = db.collection('logs');
		  var tempOption = {  user: req.session_state.username , option: option, timestamp: new Date(Date.now()) };
		  MongoCollection.insert(tempOption, function(err, result) {
		      if(err) { throw err; }
		    });
			console.log(option+' saved in db.');
		  db.close();
		});
        //res.send('processing the login form!');
		// sending the variable to Processing
		var msg =  new osc.Message('/clientMsg')
 		msg.append(req.body.option)
 		oscClient.send(msg)
    });

// deletes cokie session
app.get('/logout', function (req, res) {
console.log('User deleted:'+req.session_state.username);
  req.session_state.reset();
  res.redirect('/');
});

//nodejs server listens to msgs on port 8080
var server = server.listen(8080);

//some web-client connects
io.on('connection', function (socket) {
	socket.emit('your user', {user: theUser});
	timer(3000,function() {  socket.emit('check room', {status: roomEmpty, user: roomUser}); });
	
	  socket.on('user connected', function (data) {
		roomEmpty = false;
		roomUser = theUser;
		console.log('Your user: '+theUser+' - Empty room:'+roomEmpty+' - Current User: '+roomUser)
		countdown = maxTime;
		var mainCounter = timer(1, function() {  
			if(countdown == 0){
				countdown = maxTime;
				roomEmpty = true;
				roomUser = '';
				//socket.disconnect(true);
				//socket.broadcast.emit('check room', {status: roomEmpty, user: roomUser});
				socket.emit('kick user');
				mainCounter.stop();
			}else{
	  		  countdown--;
			  console.log(countdown);
	  		  socket.broadcast.emit('timer', { countdown: countdown });
			  socket.emit('timer', { countdown: countdown });
			}
		});
	  });
	
	//some web-client disconnects
	socket.on('disconnect', function (data) {
		console.log("user disconnected: " + data+' ('+theUser+') at '+ countdown+' miliseconds');
		roomEmpty = true;
		roomUser = '';
		//socket.emit('check room', {status: roomEmpty, user: roomUser});
	});
    socket.on('empty room', function (data) {
  	  roomEmpty = true;
    });
  socket.on('check room', function (data) {
	  socket.emit('check room', {status: roomEmpty, user: roomUser});
    //console.log(data.txt+' ('+theUser+')');
  });
	
});

/**
 * A high resolution timer.
 */
function timer(delay, callback)
{
    // self-reference
    var self = this;

    // attributes
    var counter = 0;
    var start = new Date().getTime();

    /**
     * Delayed running of the callback.
     */
    function delayed()
    {
        callback(delay);
        counter ++;
        var diff = (new Date().getTime() - start) - counter * delay;
        setTimeout(delayed, delay - diff);
    }

    // start timer
    delayed();
    var timeout = setTimeout(delayed, delay);
	
	this.stop = function() {
	        clearTimeout(timeout);
	    }
}