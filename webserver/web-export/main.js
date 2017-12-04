$(function() {
	var socket = io.connect('http://' + location.hostname + ':80'); 
	var roomEmpty = false;
	var inRoom = false;
	var roomTime = 0;
	var option;
	var theUser; 
	var currentUser;
	var reconnect = 0;
	var theOption;
	const $enter = $('#enter');
	const $enterbtn  = $('#enter button');
	const $game = $('#game');
	const $counter = $('#counter');
	const $message = $('#message');
	const $waiting = $('#waiting');
	
	$message.html('<h2>Bienvenido!</h2> <p>Estamos cargando la plataforma...</p>');
	$enter.hide();
	$(".alert").hide();
	$game.hide();
	$counter.children('span').html('00:00');
	$('#poll-option').val('N');
	$('#current-option span').html('N');
	
	socket.on('your user', (data)=>{
		theUser = data.user;
		console.log('Your user:' +theUser);
		//checkRoom(verifyRoomState);
	});
	
	socket.on('check room', function(data){
		roomEmpty = data.status;
		currentUser = data.user;
		theOption = data.option;
		statusUpdate(data.status);
		$('#current-option span').html(data.option);
		$('#poll-option').val(data.option);
		console.log('room data obtained. Room is:'+ roomEmpty+ ' and option is '+theOption);
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
			$('#content').html('<h2>Ups!</h2><p>Por falta de conexión con el servidor se ha cerrado la sesión, vuelva a intentar más tarde.</p>');
		}
	  });
	  socket.on('energy saver', function (data) {
		if(data.energySaver == 1){
			socket.close();
			$('#content').html('<h2>Estamos en modo reposo para cuidar nuestro planeta!</h2><p> El horario de funcionamiento es de 17 a 23.30 horas. </p><p>Vuelve a jugar mas tarde ;)</p>');
		}
	  });
	
	  
		// kicks the user if receives message.
		socket.on('kick user', function(){
			if(inRoom == true) {
				exitRoom();
			}
		});
	
		// shows the timer
		socket.on('timer', (data)=>{
			//if(inRoom == true) {
				//$('#timer').html(Math.floor((data.countdown/60) << 0)+':'+data.countdown);
				//}else{

			$counter.children('p').children('span').html(Math.floor((data.countdown/60) << 0)+':'+data.countdown % 60);
				//}
			// 
		});
		
		// shows waiting list
		socket.on('waiting', (data)=>{
			var iswait = data.waiting;
			if(iswait < 0){iswait = 0;}
				$waiting.children('p').children('span').html(iswait);
		});
		
		
		// selector functionality
	   $('.selector-input').change(function(){
		   option = $(this).val();
		   var $label = $("label[for='"+$(this).attr('id')+"']");
		   $('.selector').removeClass('selected');
		   $label.addClass('selected');
		   $('#current-option span').html(option);
		   $('#poll-option').val(option);
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
	   
		//poll functionality
		$('#poll').submit(function(){
			var pollVal = $('#poll input[name="poll-value"]:checked').val();
			var pollEmo = $('#poll option:selected').val();
			var pollOpt = $('#poll input[name="poll-option"]').val();
			$('#poll input[name="poll-value"]:checked').attr('checked', false);
			$('#poll option:selected').attr('selected', false);
			$('#poll input[type="submit"]').attr('disabled', true).val('enviando...');
	  	      $.post("/poll",{val: pollVal, emo: pollEmo, option: pollOpt}, function(data){
	  				if(data.result.ok == 1){console.log('poll sent');}
				
	  	      	})
	  			.done(function(data) {
	  				if(data.insertedCount == 1){console.log('poll writen');}
	  				$('#poll input[type="submit"]').attr('disabled', false).val('Enviar');
					$(".alert").show();
					$('.alert .close').on('click', function(){
						$(".alert").hide();
					});
	  	 	 	  })
	  	  	 	.fail(function(err) {
	  	   			 console.log(err.statusText);
	  	  		}); 

			return false;
		});
		
function verifyRoomState(roomEmpty, currentUser){
	console.log('loading space...');
	console.log('Room is: '+ roomEmpty);
	if(roomEmpty == true){
		$enter.show();
		$game.hide();
		$message.html('<h2>Bienvenido!</h2> <p>La plataforma está libre, podrás modificar el sistema desde el cuarto de control. Cuando estés listo presiona el botón.</p>');
		console.log('We are ready');
		enterRoom();
	}
	if(roomEmpty == false && currentUser != theUser){
	  	$game.hide();
	  	$enter.hide();
		$message.html('<h2>Vaya!</h2> <p>En este momento hay alguien en el cuarto de control. Mientras puedes disfrutar del espacio a tu alrededor. Aprovecha a valorar la experiencia actual en la encuesta que encontrarás en el pie de esta página.</p>');
		setInterval(checkRoom(), 3000);
	}
}

function enterRoom(){
	// room functionality
	
	$enterbtn.on('click',function(){
			$enterbtn.off('click');  // prevents double click :D 
			console.log('Start your engines...');
			$('selector-input[id="selector'+theOption+'"]').prop("checked", true);
			$('#selector label[for="selector'+theOption+'"]')
			//if user is not in the room
				socket.emit('enter user', { txt: 'User entered the room', user: theUser });		
				roomEmpty = false; 
				inRoom = true;
				$enter.hide();
				$game.show();
				$message.html('<h2>En el cuarto de control</h2> <p>Puedes seleccionar diferentes modos y el espacio cambiará. </p>');
	
				// if press exit button disconnects the user
				$('#exit').click(function(){
					socket.emit('kick user', {user: theUser});
					return false;
				});
		
	});
}

function exitRoom(){
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
function statusUpdate(status){
	if(roomEmpty==true){
		$('#status').html('LIBRE');
		$('#welcome').removeClass('full');
		$('#counter span').html('00:00').css('background-color', '#CCC').css('color','#4A4A4A');
			
	}else if(roomEmpty==false){
		$('#status').html('OCUPADO');
		$('#welcome').addClass('full');
			$('#counter span').css('background-color', '#C02533').css('color','#FFF');
			
	}
};
});