$(document).ready(function(){    
	var playItem = 0;  
	var inlinePlaying = false;
	var mainVol = 80; // Default volume and global reference 

	// Local copy of jQuery selectors, for performance.
	var inlinePlayer = $("#jquery_jplayer_inline");
 
	// Second instance of jPlayer for 'in page listening'
	
	inlinePlayer.jPlayer({
	  swfPath: "/swf/jplayer_1_2_0"
	});
  // inlinePlayer.jPlayer({
  //  oggSupport: true,
  //  customCssIds: true
  // })
  //  
	// Inline player
	$(".play").click(function() {   
	  alert('Play');
		var self = $(this); 
		
    if (inlinePlaying){
      inlinePlayer.jPlayer("pause");       
    }
		
    var track = $(".play").attr("href");
    // $(".play").attr("href", '');
    // var track = "https://s3-eu-west-1.amazonaws.com/radiobox-caffeinated/soho-coffee-bars-1950s.mp3";
    alert(track);
		inlinePlayer.jPlayer("setFile", track, '').jPlayer("play");
		 
    // self.hide();
		inlinePlaying = true;
		
		return false;
	});
	
	$(".stop").live("click", function() { 
    var self = $(this);    
		inlinePlayer.jPlayer("pause").jPlayer("clearFile");
		inlinePlaying = false;
		return false;
	});
	
});