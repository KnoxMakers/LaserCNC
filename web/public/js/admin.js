$('input[type="checkbox"]').click(function(event){
    event.preventDefault();
    var matches = this.name.match(/([a-zA-Z]+)_(\d+)/);
    var action = matches[1];
    var id = matches[2];
    var check_status = this.checked
    var that = this;
    $.ajax({
        type: 'PUT',
        url: '/users/'+id+'/'+action,
        data: {status: check_status}
    })
    .done(function(){
        that.checked = check_status
    })
    .fail(function(){
        $('#message').text('Error trying to change user '+action+' state');
    });
});

$('.delete-user').click(function(event){
    event.preventDefault();
    var url = $(this).attr('href');
    var that = this;
    $.ajax({
        type: 'DELETE',
        url: url
    })
    .done(function(){
        $(that).closest('tr').remove(); 
    })
    .fail(function(){
        create_alert('Could not delete user', 'danger');
    });
});

$('#post-form').click(function(event){
    event.preventDefault();
    var postData = $('#post-form').serializeArray();
    $.ajax({
        type: 'POST',
        url: '/post_message',
        data: postData
    })
    .done(function(data){
        var msg = JSON.parse(data)['message'];
        console.log(data);
        create_alert(msg, 'success');
        $('#reg-form')[0].reset();
    })
    .fail(function(data){
        console.log(data);
        var msgs = JSON.parse(data.responseText)['errors'];
        for (i = 0; i < msgs.length; i++){
            create_alert(msgs[i], 'danger');
        }
    });
});
