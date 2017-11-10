$(function() {
	var socket = io.connect('http://' + location.hostname + ':8080'); 

	var roomEmpty = false;
	var inRoom = false;
	var roomTime = 0;
	var option;
	var theUser; 
	var currentUser;
	var reconnect = 0;
	const $enter = $('#enter');
	const $enterbtn  = $('#enter button');
	const $game = $('#game');
	const $counter = $('#counter');
	const $message = $('#message');
	const $waiting = $('#waiting');
	
	$message.html('<h2>Bienvenido!</h2> <p>Estamos cargando la plataforma...</p>');
	$enter.hide();
	$game.hide();
  	$counter.hide();
	
	socket.on('your user', (data)=>{
		theUser = data.user;
		console.log('Your user:' +theUser);
		//checkRoom(verifyRoomState);
	});
	
	socket.on('check room', function(data){
		roomEmpty = data.status;
		currentUser = data.user;
		console.log('room data obtained. Room is:'+ roomEmpty);
		verifyRoomState(data.status, data.user);
	})
	
	socket.on('disconnect', function () {
	    console.log('you have been disconnected');
	  });

	  socket.on('reconnect', function () {
		  console.log('you have been reconnected');
	  });

	  socket.on('reconnect_error', function () {
	    console.log('attempt to reconnect has failed');
		reconnect++;
		if(reconnect>3){
			socket.close();
			$('#content').html('<p>Por falta de conexión con el servidor se ha cerrado la sesión, vuelva a intentar más tarde.</p>');
		}
	  });
	  
		//kicks the user if receives message.
		socket.on('kick user', function(){
			if(inRoom == true) {
				exitRoom();
			}
		});
	
		// shows the timer
		socket.on('timer', (data)=>{
			if(inRoom == true) {
				$('#timer').html(Math.floor((data.countdown/60) << 0)+':'+data.countdown);
			}else{
				$counter.children('span').html(Math.floor((data.countdown/60) << 0)+':'+data.countdown);
			}
			// 
		});
		socket.on('waiting', (data)=>{
				$waiting.children('span').html(data.waiting);
		});
	
		
		// Adds selector functionality
   	  	$("#selector").change(function(){
			$("#selector").attr('disabled', true);
         	option = $('#selector option:selected').val();
		      $.post("/option",{option: option}, function(data){
					if(data.result.ok == 1){console.log('data sent');}
		      	})
				.done(function(data) {
					if(data.insertedCount == 1){console.log('data writen');}
					$("#selector").attr('disabled', false);
		 	 	  })
		  	 	.fail(function(err) {
		   			 console.log(err);
		  		});
    	});
		
function verifyRoomState(roomEmpty, currentUser){
	console.log('loading space...');
	console.log('Room is: '+ roomEmpty);
	if(roomEmpty == true){
		$enter.show();
		$counter.hide();
		$game.hide();
		$message.html('<p>Estamos Listos!</p> <p>Ahora podrás modificar el sistema desde el cuarto de control. Cuando estés listo presiona el botón.</p>');
		console.log('We are ready');
		enterRoom();
	}
	if(roomEmpty == false && currentUser != theUser){
	  	$game.hide();
	  	$enter.hide();
		$message.html('<p>Vaya!</p> <p>En este momento hay alguien en el cuarto de control. Mientras puedes disfrutar del espacio a tu alrededor.</p>');
		$counter.show();
		setInterval(checkRoom(), 3000);
	}
}

function enterRoom(){
	// room functionality
	$enterbtn.on('click',function(){
		$enterbtn.off('click');  // prevents double click :D 
			console.log('Start your engines...');
			//if user is not in the room
				socket.emit('enter user', { txt: 'User entered the room', user: theUser });		
				roomEmpty = false; 
				inRoom = true;
				$enter.hide();
				$game.show();
				$message.html('<p>Ahora estas en el cuarto de control.</p> <p>Puedes seleccionar diferentes modos y el espacio cambiará. </p>');
	
				// if press exit button disconnects the user
				$('#exit').click(function(){
					socket.emit('kick user', {user: theUser});
					return false;
				});
		
	});
}

function exitRoom(){
	//$counter.show();
	$game.hide();
	roomEmpty = true;
	inRoom = false;
	console.log('room closed');

	socket.emit('empty room', { user : theUser });
	
}

function checkRoom(){
	//replace with socket checking
	console.log('looking for room');
	socket.emit('check room');
	
}
});