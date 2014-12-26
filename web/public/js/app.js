function create_alert(msg, type) {
    var alert = $('<div class="alert alert-dismissable alert-'+type+'">'+
       '<a class="close" data-dismiss="alert">&times;</a>'+
       msg +
       '</div>');
    $('#flash').append(alert);
}
