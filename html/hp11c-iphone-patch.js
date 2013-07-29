var avirgin = true;
var comma_status = 0;

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
var old_show = Hp12c_display.prototype.show;

Hp12c_dispatcher.prototype.dispatch = function (k)
{
  	old_dispatch.call(H.dispatcher, k);
	if (!avirgin) {
		H.storage.save();
	}
    if (comma_status != H.machine.comma) {
        comma_status = H.machine.comma;
        if (comma_status) {
            document.location = "epx11c:commaon:1";
        } else {
            document.location = "epx11c:commaoff:0";        
        }
        return;
    }
    if (dontclick) {
        dontclick = 0;
    } else {
        document.location = "epx11c:click:1";
    }
}

function ios_comma_on()
{
    if (!H.machine.comma) {
        H.machine.toggle_decimal_character();
    }
    comma_status = H.machine.comma;
}

function ios_comma_off()
{
    if (H.machine.comma) {
        H.machine.toggle_decimal_character();        
    }
    comma_status = H.machine.comma;    
}

Hp12c_display.prototype.show = function (s)
{
	old_show.call(H.display, s);
	if (!avirgin) {
		H.storage.save();
	}
}

/*
window.addEventListener("load",function() {
  // Set a timeout...
  setTimeout(function(){
    // Hide the address bar!
    window.scrollTo(0, 1);
  }, 0);
});
*/

/*
// Coords specified by another file
H.disp_theo_width = 1024.0;
H.disp_theo_height = 662.0;
H.disp_key_offset_x = 8.0;
H.disp_key_offset_y = 210.0;
H.disp_key_width = 79;
H.disp_key_height = 69;
H.disp_key_dist_x = (941.0 - 8.0) / 9;
H.disp_key_dist_y = (554.0 - 210.0) / 3;
*/
