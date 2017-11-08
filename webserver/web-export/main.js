$(function() {
	var socket = io.connect('http://' + location.hostname + ':8080'); 

	var roomEmpty = false;
	var inRoom = false;
	var roomTime = 0;
	var option;
	var theUser; 
	var currentUser;
	var $enter = $('#enter');
	var $game = $('#game');
	var $counter = $('#counter');
	
	$enter.hide();
	$game.hide();
  	$counter.hide();
	
	socket.on('your user', (data)=>{
		theUser = data.user;
	});
		socket.on('check room', (data)=>{
				roomEmpty = data.status;
				currentUser = data.user;
				verifyRoomState(roomEmpty, currentUser);
			});
	
	
	
function verifyRoomState(roomEmpty, currentUser){
	if(roomEmpty){
		console.log('Control room is empty');
		$enter.show();
		$counter.hide();
		$game.hide();
		enterRoom();
	}
	if(!roomEmpty && currentUser != theUser){
		console.log('Control room is NOT empty');
	  	$game.hide();
	  	$enter.hide();
		$counter.show();
		socket.on('timer', (data)=>{
			$counter.children('span').html(Math.floor((data.countdown/1000/60) << 0)+':'+Math.floor((data.countdown/1000) % 60));
			//
		});
	}
}

function enterRoom(){
	$enter.children('button').on('click',function(){
		socket.emit('user connected', { txt: 'User entered the room' });		
		roomEmpty = false; inRoom = true;
		$enter.hide();
		$game.show();
		// if press exit button disconnects the user
		
		$('#exit').on('click', function(){
			//exitRoom(); 
			return false;
		});
		// muestra el timer
		socket.on('timer', (data)=>{
			$('#timer').html(Math.floor((data.countdown/1000/60) << 0)+':'+Math.floor((data.countdown/1000) % 60));
			//
		});
		socket.on('kick user', function(){
			exitRoom();
		});
		
	    $("#selector").change(function(){
	     $( "#selector option:selected" ).each(function() {
	         option = $(this).val();
	     });
	      $.post("/option",{option: option}, function(data){
	        if(data==='done')
	          {
	            console.log("sent success");
	          }
	      });
	    });
	});
}

function exitRoom(){
	$counter.show();
	$game.hide();
	roomEmpty = true;
	inRoom = false;
	//checkRoom(verifyRoomState);
}

function checkRoom(callback){
	//replace with socket checking
	//socket.emit('check room'); 
	console.log('checking room...');
	socket.on('check room', (data)=>{
		roomEmpty = data.status;
		console.log('room data obtained');
		return callback(data.status, data.user);
		
	});
}

});