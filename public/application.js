$(document).ready(function() {
  
  $(document).on('click', '#hit_form input', function() {
  	// alert("Player Hits");
    $.ajax({
      type: 'POST',
      url: '/hit'     
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;	
  });

  $(document).on('click', '#stay_form input', function() {
  	// alert("Player Stays");
    $.ajax({
      type: 'POST',
      url: '/stay'     
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;	
  });

  $(document).on('click', '#dealerhit_form input', function() {
  	// alert("Dealer Hits");
    $.ajax({
      type: 'POST',
      url: '/stay'     
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;	
  });

});