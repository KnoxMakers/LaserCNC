$(document).ready(function(){
  function create_alert(type, msg){
    var $alrt = $("<div>", {class: "alert alert-dismissible"});
    var $btn = $("<button>", {class: "close", "data-dismiss": 'alert', "aria-hidden": "true"}).text("x");
    $alrt.addClass('alert-' + type);
    return $alrt.append($btn).append(msg);
  }

  $('#userfile').fileinput({
       'showPreview': false, 
       'allowedFileExtensions': ['ngc'], 
       'maxFileCount': 1, 
       'msgInvalidFileExtension': 'Invalid File Type.  Only .ngc files should be uploaded'});
  
  $('a.load').click(function(event){
    event.preventDefault(); 
    $.post(
      $(this).attr('href'),
      function(data){
	var d = $.parseJSON(data);
	var type = 'danger';
        console.log(d.msg);
	if(d.status == 'success'){
	  type = 'success';
	}
	$('#alert-wrapper').append(create_alert(type, d.msg));
      });
  });

  $('a.public').click(function(event){
    event.preventDefault();
    var that = this;
    $.post(
      $(that).attr('href'),
      function(data){
	var d = $.parseJSON(data);
        console.log(d.msg);
	if(d.status == 'success'){
	  $(that).closest('tr').find('td.public').text(d.msg);
	} else {
	  $('#alert-wrapper').append(create_alert(d.status, d.msg));
	}
      });
  });

  $('a.delete').click(function(event){
    event.preventDefault();
    var that = this;
    $.ajax({
      url: $(this).attr('href'),
      type: 'DELETE',
      success: function(data){
	var d = $.parseJSON(data);
        console.log(data);
	if (d.status == 'success'){
	  $(that).closest('tr').remove();
	} else {
	  $('#alert-wrapper').append(create_alert('danger', d.msg));
	}
      }
    });
  });
});
