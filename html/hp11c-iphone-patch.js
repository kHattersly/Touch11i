var avirgin = true;
var separator_status = 0;
var fb_status = 1;
var request_settings = 0;

Hp12c_storage.prototype.save = function() {
	localStorage.setItem('EPX11C', H.storage.save_memory2(H.machine));
};

Hp12c_storage.prototype.load = function() {
	var sserial = "" + localStorage.getItem('EPX11C');
  	if (sserial && sserial.length > 0) {
		H.storage.recover_memory2(H.machine, sserial);
	}
	avirgin = false;
};

var dontclick = 0;

Hp12c_machine.prototype.apocryphal = function (i)
{
    document.location = "epx11c:tclick:1";
    dontclick = 1;
};

var old_dispatch = Hp12c_dispatcher.prototype.dispatch;
var old_show = Hp12c_display.prototype.private_show;

Hp12c_dispatcher.prototype.dispatch = function (k)
{
  	old_dispatch.call(H.dispatcher, k);
	if (!avirgin) {
		H.storage.save();
	}
    if (request_settings) {
        request_settings = 0;
        document.location = "epx11c:settings:1";
        return;
    }
    if (fb_status != H.machine.fb) {
        fb_status = H.machine.fb;
        if (fb_status) {
            document.location = "epx11c:fbon:1";
        } else {
            document.location = "epx11c:fboff:0";
        }
        return;
    }
    if (dontclick) {
        dontclick = 0;
    } else {
        document.location = "epx11c:click:1";
    }
}

// disables ON as decimal separator toggler
Hp12c_dispatcher.prototype.functions[41][0] = function () {
    request_settings = 1;
};
Hp12c_dispatcher.prototype.functions[41][0].no_pgrm = 1;

function ios_separator(sep)
{
    while (H.machine.comma !== sep) {
        H.machine.toggle_decimal_character();
    }
    separator_status = H.machine.comma;
}

function ios_fb_on()
{
    if (!H.machine.fb) {
        H.machine.toggle_feedback();
    }
    fb_status = H.machine.fb;
}

function ios_fb_off()
{
    if (H.machine.fb) {
        H.machine.toggle_feedback();
    }
    fb_status = H.machine.fb;
}

Hp12c_display.prototype.private_show = function (s)
{
	old_show.call(H.display, s);
	if (!avirgin) {
		H.storage.save();
	}
}

  
Hp12c_dispatcher.prototype.functions[16][44] = function () {
    dontclick = 1;
    document.location = "epx11c:savemem:" + H.storage.save_memory2(H.machine);
};

Hp12c_dispatcher.prototype.functions[16][44].no_pgrm = 1;

Hp12c_dispatcher.prototype.functions[26][45] = function () {
    dontclick = 1;
    document.location = "epx11c:loadmem:1"
};

Hp12c_dispatcher.prototype.functions[26][45].no_pgrm = 1;

Hp12c_dispatcher.prototype.functions[26][4543] = function () {
    dontclick = 1;
    document.location = "epx11c:delmem:1"
};

Hp12c_dispatcher.prototype.functions[26][4543].no_pgrm = 1;

function loadmem(sserial)
{
    if (sserial && sserial.length > 0) {
        H.storage.recover_memory2(H.machine, sserial);
        H.machine.display_all();
    }
    avirgin = false;
}

Hp12c_machine.prototype.easter_egg = function () {};

function ios_set_rapid(is_rapid)
{
    if (is_rapid) {
            H.machine.rapid_on();
    } else {
            H.machine.rapid_off();
    }
}

Hp12c_dispatcher.prototype.lcd_left = function ()
{
    if (!window.ipad_canary) {
        show_back();
    }
}

Hp12c_dispatcher.prototype.lcd_right = function ()
{
    if (!window.ipad_canary) {
        show_back();
    }
}

function show_back()
{
    var img = "back.png";
    if (H.vertical_layout) {
        img = "backv.png";
    }
    
    var div = document.createElement('back');
    div.style.position = "fixed";
    div.style.left = "0px";
    div.style.top = "0px";
    div.style.width = "100%";
    div.style.opacity = "0.8";
    div.style.zIndex = 100;
    div.innerHTML = '<img src=' + img + ' style="width: 100%">';
    div.ontouchstart = function () {
        div.parentNode.removeChild(div);
    };
    document.body.appendChild(div); // append to main body
}