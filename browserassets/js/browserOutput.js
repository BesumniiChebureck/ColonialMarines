/*****************************************
*
* FUNCTION AND VAR DECLARATIONS
* 
******************************************/

//DEBUG STUFF
var escaper = encodeURIComponent || escape;
var decoder = decodeURIComponent || unescape;
window.onerror = function(msg, url, line, col, error) {
	if (document.location.href.indexOf("proc=debug") <= 0) {
		var extra = !col ? '' : ' | column: ' + col;
		extra += !error ? '' : ' | error: ' + error;
		extra += !navigator.userAgent ? '' : ' | user agent: ' + navigator.userAgent;
		var debugLine = 'Error: ' + msg + ' | url: ' + url + ' | line: ' + line + extra;
		window.location = '?_src_=chat&proc=debug&param[error]='+escaper(debugLine);
	}
	return true;
};

//Globals
window.status = 'Output';
var $messages, $subOptions, $last_message;
var opts = {
	//General
	'messageCount': 0, //A count...of messages...
	'messageLimit': 2053, //A limit...for the messages...
	'scrollSnapTolerance': 5, //If within x pixels of bottom
	'clickTolerance': 10, //Keep focus if outside x pixels of mousedown position on mouseup
	'imageRetryDelay': 50, //how long between attempts to reload images (in ms)
	'imageRetryLimit': 50, //how many attempts should we make? 
	'popups': 0, //Amount of popups opened ever
	'chatMode': 'default', //The mode the chat is in
	'priorChatHeight': 0, //Thing for height-resizing detection
	'restarting': false, //Is the round restarting?

	//Options menu
	'subOptionsLoop': null, //Contains the interval loop for closing the options menu
	'suppressOptionsClose': false, //Whether or not we should be hiding the suboptions menu
	'highlightTerms': [],
	'highlightLimit': 5,
	'highlightColor': ['#FFFF00','#FFCC00','#FFAA00','#CCFF00','#AAFF00'], //The color of the highlighted message
	'pingDisabled': false, //Has the user disabled the ping counter

	//Ping display
	'lastPang': 0, //Last response from the server
	'pingLimit': 35000,
	'pingTime': 0, //Timestamp of when ping sent
	'pongTime': 0, //Timestamp of when ping received
	'noResponse': false, //Tracks the state of the previous ping request
	'noResponseCount': 0, //How many failed pings?

	//Clicks
	'mouseDownX': null,
	'mouseDownY': null,
	'preventFocus': false, //Prevents switching focus to the game window

	//Client Connection Data
	'clientDataLimit': 5,
	'clientData': [],
};

function outerHTML(el) {
    var wrap = document.createElement('div');
    wrap.appendChild(el.cloneNode(true));
    return wrap.innerHTML;
}

//Polyfill for fucking date now because of course IE8 and below don't support it
if (!Date.now) {
	Date.now = function now() {
		return new Date().getTime();
	};
}
//Polyfill for trim() (IE8 and below)
if (typeof String.prototype.trim !== 'function') {
	String.prototype.trim = function () {
		return this.replace(/^\s+|\s+$/g, '');
	};
}

//Shit fucking piece of crap that doesn't work god fuckin damn it
function linkify(text) {
	var rex = /((?:<a|<iframe|<img)(?:.*?(?:src="|href=").*?))?(?:(?:https?:\/\/)|(?:www\.))+(?:.*?\..*?)+[-A-Za-z0-9+&@#\/%?=~_|$!:,.;]+/ig;
	return text.replace(rex, function ($0, $1) {
		if(/^https?:\/\/.+/i.test($0)) {
			return $1 ? $0: '<a href="'+$0+'">'+$0+'</a>';
		}
		else {
			return $1 ? $0: '<a href="http://'+$0+'">'+$0+'</a>';
		}
	});
}

//Actually turns the highlight term match into appropriate html
function getHighlightMarkupFunction(highlightType) {
	return function(match){
		var extra = '';
		if (opts.highlightColor) {
			extra += ' style="background-color: '+opts.highlightColor[highlightType]+'"';
		}
		return '<span class="highlight"'+extra+'>'+match+'</span>';
	};
}

//Highlights words based on user settings
function highlightTerms(el) {
	if (el.children.length > 0) {
		for(var h = 0; h < el.children.length; h++){
			highlightTerms(el.children[h]);
		}
	}
	if (el.childNodes.length > 0 && typeof el.childNodes[0].data !== 'undefined' && el.childNodes[0].data.length > 0) { //If element actually has text
		var newText = '';
		for (var c = 0; c < el.childNodes.length; c++) { //Each child element
			if (el.childNodes[c].nodeType === 3) { //Is it text only?
				var words = el.childNodes[c].data.split(' ');
				for (var w = 0; w < words.length; w++) { //Each word in the text
					var newWord = null;
					for (var i = 0; i < opts.highlightTerms.length; i++) { //Each highlight term
						if (opts.highlightTerms[i] && words[w].toLowerCase().indexOf(opts.highlightTerms[i].toLowerCase()) > -1) { //If a match is found
							newWord = words[w].replace(new RegExp(opts.highlightTerms[i], 'gi'), getHighlightMarkupFunction(i));
							break;
						}
					}
					newText += newWord ? newWord : words[w];
					newText += w >= words.length ? '' : ' ';
				}
			} else { //Every other type of element
				newText += outerHTML(el.childNodes[c]);
			}
		}
		el.innerHTML = newText;
	}
}

function iconError(e) {
	var that = this;
	setTimeout(function() {
		var attempts = $(that).data('reload_attempts');
		if (typeof attempts === 'undefined' || !attempts) {
			attempts = 1;
		}
		if (attempts > opts.imageRetryLimit)
			return;
		var src = that.src;
		that.src = null;
		that.src = src+'#'+attempts;
		$(that).data('reload_attempts', ++attempts);
	}, opts.imageRetryDelay);
} 

//Send a message to the client. filterFlag is used to filter out specific messages depending on user settings.
function output(message, flag) {
	if(typeof message === 'undefined') {
		return;
	}
	if(typeof flag === 'undefined') {
		flag = '';
	}

	if(flag === 'internal') {
		escaper(message)
	} else {
		opts.lastPang = Date.now();
		var parsed = $.parseJSON(message)
		if(parsed)
			message = parsed.message.trim();
		message = message.replace("\t","&nbsp;&nbsp;&nbsp;&nbsp;").replace(/[^\x00-\x7F]/g, ""); // literally DIE UNICODE
	}

	//Stuff we do along with appending a message
	var atBottom = false;
	var bodyHeight = $('body').height();
	var messagesHeight = $messages.outerHeight();
	var scrollPos = $('body,html').scrollTop();

	//Should we snap the output to the bottom?
	if (bodyHeight + scrollPos >= messagesHeight - opts.scrollSnapTolerance) {
		atBottom = true;
		if ($('#newMessages').length) {
			$('#newMessages').remove();
		}
	//If not, put the new messages box in
	} else {
		if ($('#newMessages').length) {
			var messages = $('#newMessages .number').text();
			messages = parseInt(messages);
			messages++;
			$('#newMessages .number').text(messages);
			if (messages == 2) {
				$('#newMessages .messageWord').append('s');
			}
		} else {
			$messages.after('<a href="#" id="newMessages"><span class="number">1</span> new <span class="messageWord">message</span> <i class="icon-double-angle-down"></i></a>');
		}
	}
	
	/*
	//Url stuff
	if (message.length && flag != 'preventLink') {
		message = linkify(message);
	}*/

	opts.messageCount++;

	//Pop the top message off if history limit reached
	if (opts.messageCount >= opts.messageLimit) {
		$messages.children('div.entry:first-child').remove();
		opts.messageCount--; //I guess the count should only ever equal the limit
	}

	message = message.trim();
	var entry = document.createElement('div');
	entry.innerHTML = message;
	var trimmed_message = entry.textContent || entry.innerText || "";

	var handled = false;
	var lastmessages = $messages.children('div.entry:last-child').last();
	if(lastmessages.length && $last_message && $last_message == trimmed_message) {
		var combine = lastmessages.children('.combine').last();
		if (combine.length) {
			combine = combine.detach();
			combine.text(parseInt(combine.text()) + 1);
		} else {
			combine = $('<span/>', {'class': 'combine', 'text': 2});
		}
		var fontSize = parseInt(lastmessages.css("font-size"));
		if (fontSize < 17) {
			fontSize = fontSize + 1 + 'px';
			lastmessages.css({'font-size': fontSize});
			combine.css({'font-size': fontSize});
		}  
		message = message.replace(/^\s*<br\s*\/?>|<br\s*\/?>\s*$/g,'');
		lastmessages.html(message);
		lastmessages.append(combine);

		opts.messageCount--;
		handled = true;
	}

	if(!handled) {
		entry.className = 'entry';

		$last_message = trimmed_message;
		$messages[0].appendChild(entry);
		$(entry).find("img.icon").error(iconError);

		// Stuff we can do after the message shows can go here, in the interest of responsiveness
		if(opts.highlightTerms && opts.highlightTerms.length > 0) {
			highlightTerms(entry);
		}
	}

	//Actually do the snap
	if (atBottom) {
		$('body,html').scrollTop($messages.outerHeight());
	}
}

//Runs a route within byond, client or server side. Consider this "ehjax" for byond.
function runByond(uri) {
	window.location = uri;
}

function setCookie(cname, cvalue, exdays) {
	cvalue = escaper(cvalue);
	var d = new Date();
	d.setTime(d.getTime() + (exdays*24*60*60*1000));
	var expires = 'expires='+d.toUTCString();
	document.cookie = cname + '=' + cvalue + '; ' + expires + "; path=/";
}

function getCookie(cname) {
	var name = cname + '=';
	var ca = document.cookie.split(';');
	for(var i=0; i < ca.length; i++) {
	var c = ca[i];
	while (c.charAt(0)==' ') c = c.substring(1);
		if (c.indexOf(name) === 0) {
			return decoder(c.substring(name.length,c.length));
		}
	}
	return '';
}

function rgbToHex(R,G,B) {return toHex(R)+toHex(G)+toHex(B);}
function toHex(n) {
	n = parseInt(n,10);
	if (isNaN(n)) return "00";
	n = Math.max(0,Math.min(n,255));
	return "0123456789ABCDEF".charAt((n-n%16)/16) + "0123456789ABCDEF".charAt(n%16);
}

function changeMode(mode) {
	switch (mode) {
		case 'geocities':
			//switch in stylesheet
			opts.chatMode = mode;
			break;
		case 'console':

			opts.chatMode = mode;
			break;
		case 'default':
		default:
			//remove loaded stylesheet/s
			opts.chatMode = 'default';
	}
}

function handleClientData(ckey, ip, compid) {
	//byond sends player info to here
	var currentData = {'ckey': ckey, 'ip': ip, 'compid': compid};
	if (opts.clientData && !$.isEmptyObject(opts.clientData)) {
		runByond('?_src_=chat&proc=analyzeClientData&param[cookie]='+JSON.stringify({'connData': opts.clientData}));

		for (var i = 0; i < opts.clientData.length; i++) {
			var saved = opts.clientData[i];
			if (currentData.ckey == saved.ckey && currentData.ip == saved.ip && currentData.compid == saved.compid) {
				return; //Record already exists
			}
		}

		if (opts.clientData.length >= opts.clientDataLimit) {
			opts.clientData.shift();
		}
	} else {
		runByond('?_src_=chat&proc=analyzeClientData&param[cookie]=none');
	}

	//Update the cookie with current details
	opts.clientData.push(currentData);
	setCookie('connData', JSON.stringify(opts.clientData), 365);
}

//Server calls this on ehjax response
//Or, y'know, whenever really
function ehjaxCallback(data) {
	opts.lastPang = Date.now();
	if (data == 'softPang') {
		return;

	} else if (data == 'pang') {
		opts.pingCounter = 0; //reset
		opts.pingTime = Date.now();
		runByond('?_src_=chat&proc=ping');

	} else if (data == 'pong') {
		if (opts.pingDisabled) {return;}
		opts.pongTime = Date.now();
		var pingDuration = Math.ceil((opts.pongTime - opts.pingTime) / 2);
		$('#pingMs').text(pingDuration+'ms');
		pingDuration = Math.min(pingDuration, 255);
		var red = pingDuration;
		var green = 255 - pingDuration;
		var blue = 0;
		var hex = rgbToHex(red, green, blue);
		$('#pingDot').css('color', '#'+hex);
		
	} else if (data == 'roundrestart') {
		opts.restarting = true;
		output('<div class="connectionClosed internal restarting">The connection has been closed because the server is restarting. Please wait while you automatically reconnect.</div>', 'internal');
	} else if (data == 'stopaudio') {
		$('.dectalk').remove();
	} else if (data == 'white_skin') {
		opts.highlightColor = ['#FFFF00','#FFCC00','#FFAA00','#CCFF00','#AAFF00']
		document.getElementById("window_skin").href = "browserOutput.css";
	} else if (data == 'night_skin') {
		opts.highlightColor = ['#002fff', '#8c00ff', '#ff00d4','#ff0080','#ff0037']
		document.getElementById("window_skin").href = "browserOutput_night.css";
	} else {
		//Oh we're actually being sent data instead of an instruction
		var dataJ;
		try {
			dataJ = $.parseJSON(data);
		} catch (e) {
			//But...incorrect :sadtrombone:
			window.onerror('JSON: '+e+'. '+data, 'browserOutput.html', 327);
			return;
		}
		data = dataJ;

		if (data.clientData) {
			if (opts.restarting) {
				opts.restarting = false;
				$('.connectionClosed.restarting:not(.restored)').addClass('restored').text('The round restarted and you successfully reconnected!');
			}
			if (!data.clientData.ckey && !data.clientData.ip && !data.clientData.compid) {
				//TODO: Call shutdown perhaps
				return;
			} else {
				handleClientData(data.clientData.ckey, data.clientData.ip, data.clientData.compid);
			}
		} else if (data.modeChange) {
			changeMode(data.modeChange);
		} else if (data.firebug) {
			if (data.trigger) {
				output('<span class="internal boldnshit">Loading firebug console, triggered by '+data.trigger+'...</span>', 'internal');
			} else {
				output('<span class="internal boldnshit">Loading firebug console...</span>', 'internal');
			}
			var firebugEl = document.createElement('script');
			firebugEl.src = 'https://getfirebug.com/firebug-lite-debug.js';
			document.body.appendChild(firebugEl);
		} else if (data.dectalk) {
			var message = '<audio class="dectalk" src="'+data.dectalk+'" autoplay="autoplay"></audio>';
			if (data.decTalkTrigger) {
				message = '<a href="#" class="stopAudio icon-stack" title="Stop Audio" style="color: black;"><i class="icon-volume-off"></i><i class="icon-ban-circle" style="color: red;"></i></a> '+
				'<span class="italic">You hear a strange robotic voice...</span>' + message;
			}
			output(message, 'preventLink');
		}
	}
}

function createPopup(contents, width) {
	opts.popups++;
	$('body').append('<div class="popup" id="popup'+opts.popups+'" style="width: '+width+'px;">'+contents+' <a href="#" class="close"><i class="icon-remove"></i></a></div>');

	//Attach close popup event
	var $popup = $('#popup'+opts.popups);
	var height = $popup.outerHeight();
	$popup.css({'height': height+'px', 'margin': '-'+(height/2)+'px 0 0 -'+(width/2)+'px'});

	$popup.on('click', '.close', function(e) {
		e.preventDefault();
		$popup.remove();
	});
}


/*****************************************
*
* DOM READY
* 
******************************************/

if (typeof $ === 'undefined') {
	var div = document.getElementById('loading').childNodes[1];
	div += '<br><br>ERROR: Jquery did not load.';
}

$(function() {
	$messages = $('#messages');
	$subOptions = $('#subOptions');

	// Ping loop
	setInterval(function() {
		if (opts.lastPang + opts.pangLimit < Date.now() && !opts.restarting) { //Every pingLimit
				if (!opts.noResponse) { //Only actually append a message if the previous ping didn't also fail (to prevent spam)
					opts.noResponse = true;
					opts.noResponseCount++;
					output('<div class="connectionClosed internal" data-count="'+opts.noResponseCount+'">You are either AFK, experiencing lag or the connection has closed.</div>', 'internal');
				}
		} else if (opts.noResponse) { //Previous ping attempt failed ohno
				$('.connectionClosed[data-count="'+opts.noResponseCount+'"]:not(.restored)').addClass('restored').text('Your connection has been restored (probably)!');
				opts.noResponse = false;
		}
	}, 2000); //2 seconds

	
	/*****************************************
	*
	* LOAD SAVED CONFIG
	* 
	******************************************/
	var savedConfig = {
		'sfontSize': getCookie('fontsize'),
		'sfontType': getCookie('fonttype'),
		'spingDisabled': getCookie('pingdisabled'),
		'shighlightTerms': getCookie('highlightterms'),
		'sfireMessages': getCookie('firemessages'),
	};

	if (savedConfig.sfontSize) {
		$messages.css('font-size', savedConfig.sfontSize);
		output('<span class="internal boldnshit">Loaded font size setting of: '+savedConfig.sfontSize+'</span>', 'internal');
	}
	if (savedConfig.sfontType) {
		$messages.css('font-family', savedConfig.sfontType);
		output('<span class="internal boldnshit">Loaded font type setting of: '+savedConfig.sfontType+'</span>', 'internal');
	}
	if (savedConfig.spingDisabled) {
		if (savedConfig.spingDisabled == 'true') {
			opts.pingDisabled = true;
			$('#ping').hide();
		}
		output('<span class="internal boldnshit">Loaded ping display of: '+(opts.pingDisabled ? 'hidden' : 'visible')+'</span>', 'internal');
	}
	if (savedConfig.shighlightTerms) {
		var savedTerms = $.parseJSON(savedConfig.shighlightTerms);
		var actualTerms = '';
		for (var i = 0; i < savedTerms.length; i++) {
			if (savedTerms[i]) {
				actualTerms += savedTerms[i] + ', ';
			}
		}
		if (actualTerms) {
			actualTerms = actualTerms.substring(0, actualTerms.length - 2);
			output('<span class="internal boldnshit">Loaded highlight strings of: ' + actualTerms+'</span>', 'internal');
			opts.highlightTerms = savedTerms;
		}
	}
	if (savedConfig.sfireMessages) {
		opts.sfireMessages = savedConfig.sfireMessages;
		output('<span class="internal boldnshit">Loaded toggling of fire messages: '+savedConfig.sfireMessages+'</span>', 'internal');
	}

	(function() {
		var dataCookie = getCookie('connData');
		if (dataCookie) {
			var dataJ;
			try {
				dataJ = $.parseJSON(dataCookie);
			} catch (e) {
				window.onerror('JSON '+e+'. '+dataCookie, 'browserOutput.html', 434);
				return;
			}
			opts.clientData = dataJ;
		}
	})();


	/*****************************************
	*
	* BASE CHAT OUTPUT EVENTS
	* 
	******************************************/

	$('body').on('click', 'a', function(e) {
		e.preventDefault();
	});

	$('body').on('mousedown', function(e) {
		var $target = $(e.target);

		if ($target.is('a') || $target.parent('a').length || $target.is('input') || $target.is('textarea')) {
			opts.preventFocus = true;
		} else {
			opts.preventFocus = false;
			opts.mouseDownX = e.pageX;
			opts.mouseDownY = e.pageY;
		}
	});

	$messages.on('mousedown', function(e) {
		if ($subOptions && $subOptions.is(':visible')) {
			$subOptions.slideUp('fast', function() {
				$(this).removeClass('scroll');
				$(this).css('height', '');
			});
			clearInterval(opts.subOptionsLoop);
		}
	});

	$('body').on('mouseup', function(e) {
		if (!opts.preventFocus && 
			(e.pageX >= opts.mouseDownX - opts.clickTolerance && e.pageX <= opts.mouseDownX + opts.clickTolerance) &&
			(e.pageY >= opts.mouseDownY - opts.clickTolerance && e.pageY <= opts.mouseDownY + opts.clickTolerance)
		) {
			opts.mouseDownX = null;
			opts.mouseDownY = null;
			runByond('byond://winset?mapwindow.map.focus=true');
		}
	});

	$messages.on('click', 'a', function(e) {
		var href = $(this).attr('href');
		if (href[0] == '?' || (href.length >= 8 && href.substring(0,8) == 'byond://')) {
			runByond(href);
		} else {
			href = escaper(href);
			runByond('?action=openLink&link='+href);
		}
		runByond('byond://winset?mapwindow.map.focus=true');
	});

	//Fuck everything about this event. Will look into alternatives.
	$('body').on('keydown', function(e) {
		if (e.target.nodeName == 'INPUT' || e.target.nodeName == 'TEXTAREA') {
			return;
		}

		if (e.ctrlKey || e.altKey || e.shiftKey) { //Band-aid "fix" for allowing ctrl+c copy paste etc. Needs a proper fix.
			return;
		}

		e.preventDefault()

		var k = e.which;
		var command;
		switch (k) {
			case 8:
				command = 'Back';
			case 9:
				command = 'Tab';
			case 13:
				command = 'Enter';
			case 19:
				command = 'Pause';
			case 27:
				command = 'Escape';
			case 33: // Page up
				command = 'Northeast';
			case 34: // Page down
				command = 'Southeast';
			case 35: // End
				command = 'Southwest';
			case 36: // Home
				command = 'Northwest';
			case 37:
				command = 'West';
			case 38:
				command = 'North';
			case 39:
				command = 'East';
			case 40:
				command = 'South';
			case 45:
				command = 'Insert';
			case 46:
				command = 'Delete';
			case 113:
				runByond('byond://winset?screenshot=auto');
				internalOutput('Screenshot taken', 'internal');
			default:
				command = String.fromCharCode(k);
		}

		if (command.length == 0) {
			if (!e.shiftKey) {
				command = command.toLowerCase();
			}
			runByond('byond://winset?mapwindow.map.focus=true;mainwindow.input.text='+command);
			return false;
		} else {
			runByond('byond://winset?mapwindow.map.focus=true');
			return false;
		}
	});

	//Mildly hacky fix for scroll issues on mob change (interface gets resized sometimes, messing up snap-scroll)
	$(window).on('resize', function(e) {
		if ($(this).height() !== opts.priorChatHeight) {
			$('body,html').scrollTop($messages.outerHeight());
			opts.priorChatHeight = $(this).height();
		}
	});

	//Audio sound prevention
	$messages.on('click', '.stopAudio', function() {
		var $audio = $(this).parent().children('audio');
		if ($audio) {
			$audio.remove();
		}
	});


	/*****************************************
	*
	* OPTIONS INTERFACE EVENTS
	* 
	******************************************/

	$('body').on('click', '#newMessages', function(e) {
		var messagesHeight = $messages.outerHeight();
		$('body,html').scrollTop(messagesHeight);
		$('#newMessages').remove();
		runByond('byond://winset?mapwindow.map.focus=true');
	});

	$('#toggleOptions').click(function(e) {
		if ($subOptions.is(':visible')) {
			$subOptions.slideUp('fast', function() {
				$(this).removeClass('scroll');
				$(this).css('height', '');
			});
			clearInterval(opts.subOptionsLoop);
		} else {
			$subOptions.slideDown('fast', function() {
				var windowHeight = $(window).height();
				var toggleHeight = $('#toggleOptions').outerHeight();
				var priorSubHeight = $subOptions.outerHeight();
				var newSubHeight = windowHeight - toggleHeight;
				$(this).height(newSubHeight);
				if (priorSubHeight > (windowHeight - toggleHeight)) {
					$(this).addClass('scroll');
				}
			});
			opts.subOptionsLoop = setInterval(function() {
				if (!opts.suppressOptionsClose && $('#subOptions').is(':visible')) {
					$subOptions.slideUp('fast', function() {
						$(this).removeClass('scroll');
						$(this).css('height', '');
					});
					clearInterval(opts.subOptionsLoop);
				}
			}, 5000); //Every 5 seconds
		}
	});

	$('#subOptions, #toggleOptions').mouseenter(function() {
		opts.suppressOptionsClose = true;
	});

	$('#subOptions, #toggleOptions').mouseleave(function() {
		opts.suppressOptionsClose = false;
	});

	$('#decreaseFont').click(function(e) {
		var fontSize = parseInt($messages.css('font-size'));
		fontSize = fontSize - 1 + 'px';
		$messages.css({'font-size': fontSize});
		setCookie('fontsize', fontSize, 365);
		output('<span class="internal boldnshit">Font size set to '+fontSize+'</span>', 'internal');
	});

	$('#increaseFont').click(function(e) {
		var fontSize = parseInt($messages.css('font-size'));
		fontSize = fontSize + 1 + 'px';
		$messages.css({'font-size': fontSize});
		setCookie('fontsize', fontSize, 365);
		output('<span class="internal boldnshit">Font size set to '+fontSize+'</span>', 'internal');
	});

	$('#chooseFont').click(function(e) {
		if ($('.popup .changeFont').is(':visible')) {return;}
		var popupContent = '<div class="head">Change Font</div>' +
			'<div id="changeFont" class="changeFont">'+
				'<a href="#" data-font="\'Helvetica Neue\', Helvetica, Arial" style="font-family: \'Helvetica Neue\', Helvetica, Arial;">Arial / Helvetica (Default)</a>'+
				'<a href="#" data-font="Times New Roman" style="font-family: Times New Roman;">Times New Roman</a>'+
				'<a href="#" data-font="Georgia" style="font-family: Georgia;">Georgia</a>'+
				'<a href="#" data-font="Verdana" style="font-family: Verdana;">Verdana</a>'+
				'<a href="#" data-font="Courier New" style="font-family: Courier New;">Courier New</a>'+
				'<a href="#" data-font="Lucida Console" style="font-family: Lucida Console;">Lucida Console</a>'+
				'<a href="#" data-font="Comic Sans MS" style="font-family: Comic Sans MS;">Comic Sans</a>'+
			'</div>';
		createPopup(popupContent, 200);
	});

	$('body').on('click', '#changeFont a', function(e) {
		var font = $(this).attr('data-font');
		$messages.css('font-family', font);
		setCookie('fonttype', font, 365);
	});

	$('#togglePing').click(function(e) {
		if (opts.pingDisabled) {
			$('#ping').slideDown('fast');
			opts.pingDisabled = false;
		} else {
			$('#ping').slideUp('fast');
			opts.pingDisabled = true;
		}
		setCookie('pingdisabled', (opts.pingDisabled ? 'true' : 'false'), 365);
	});

	$('#toggleMessages').click(function(e) {
		opts.fireMessages = !opts.fireMessages 
		setCookie('firemessages', (opts.fireMessages ? 'true' : 'false'), 365);
	});

	$('#saveLog').click(function(e) {
		$.ajax({
			type: 'GET',
			url: 'browserOutput.css',
			success: function(styleData) {
				var win;

				try {
					win = window.open('', 'Chat Log', 'toolbar=no, location=no, directories=no, status=no, menubar=yes, scrollbars=yes, resizable=yes, width=780, height=600, top=' + (screen.height/2 - 635/2) + ', left=' + (screen.width/2 - 780/2));
				} catch (e) {
					return;
				}

				if (win) {
					win.document.head.innerHTML = '<title>Chat Log</title>';
					win.document.head.innerHTML += '<style>' + styleData + '</style>';
					win.document.body.innerHTML = $messages.html();
				}
			}
		});
	});

	$('#highlightTerm').click(function(e) {
		if ($('.popup .highlightTerm').is(':visible')) {return;}
		var termInputs = '';
		for (var i = 0; i < opts.highlightLimit; i++) {
			termInputs += '<div><input type="text" style="background-color: '+opts.highlightColor[i]+ '" name="highlightTermInput'+i+'" id="highlightTermInput'+i+'" class="highlightTermInput'+i+'" maxlength="255" value="'+(opts.highlightTerms[i] ? opts.highlightTerms[i] : '')+'" /></div>';
		}
		var popupContent = '<div class="head">String Highlighting</div>' +
			'<div class="highlightPopup" id="highlightPopup">' +
				'<div>Choose up to '+opts.highlightLimit+' strings that will highlight the line when they appear in chat.</div>' +
				'<form id="highlightTermForm">' +
					termInputs +
					'<div><input type="submit" name="highlightTermSubmit" id="highlightTermSubmit" class="highlightTermSubmit" value="Save" /></div>' +
				'</form>' +
			'</div>';
		createPopup(popupContent, 250);
	});

	$('body').on('submit', '#highlightTermForm', function(e) {
		e.preventDefault();

		var count = 0;
		while (count < opts.highlightLimit) {
			var term = $('#highlightTermInput'+count).val();
			if (term) {
				term = term.trim();
				if (term === '') {
					opts.highlightTerms[count] = null;
				} else {
					opts.highlightTerms[count] = term.toLowerCase();
				}
			} else {
				opts.highlightTerms[count] = null;
			}
			count++;
		}

		var $popup = $('#highlightPopup').closest('.popup');
		$popup.remove();

		setCookie('highlightterms', JSON.stringify(opts.highlightTerms), 365);
	});

	$('#clearMessages').click(function() {
		$messages.empty();
		opts.messageCount = 0;
	});

	$('img.icon').error(iconError);

	/*****************************************
	*
	* KICK EVERYTHING OFF
	* 
	******************************************/

	runByond('?_src_=chat&proc=doneLoading');
	if ($('#loading').is(':visible')) {
		$('#loading').remove();
	}
	$('#userBar').show();
	opts.priorChatHeight = $(window).height();
});