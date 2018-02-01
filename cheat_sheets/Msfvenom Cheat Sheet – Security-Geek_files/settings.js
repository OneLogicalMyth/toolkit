jQuery(document).ready(function($){
	$('.sf-menu ul').supersubs({
	        minWidth: 12,
	        maxWidth: 27,
	        extraWidth: 0 // set to 1 if lines turn over
	    }).superfish({
    		delay: 200,
    		animation: {opacity:'show', height:'show'},
    		speed: 'fast',
    		autoArrows: false,
    		dropShadows: false
	});

	$('.carousel').carousel();

	$('.widget-tab-nav a').click(function (e) {
		e.preventDefault();
		$(this).tab('show');
	})

});