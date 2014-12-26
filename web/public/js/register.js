$('button').click(function(event){
    var postData = $('#reg-form').serializeArray();
    event.preventDefault();
    $.ajax({
        type: 'POST',
        url: '/register',
        data: postData
    })
    .done(function(data){
        var msg = JSON.parse(data)['message'];
        create_alert(msg, 'success');
        $('#reg-form')[0].reset();
    })
    .fail(function(data){
        var msgs = JSON.parse(data.responseText)['errors'];
        for (i = 0; i < msgs.length; i++){
            create_alert(msgs[i], 'danger');
        }
    });
});
