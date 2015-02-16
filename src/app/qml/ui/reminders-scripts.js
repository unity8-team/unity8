function handleClickEvent(event) {
    var todoTag = "en-todo";
    var attachmentTag = "en-attachment";

    var idFields = event.srcElement.id.split("/");
    if (idFields[0] === todoTag) {
        message = new Object;
        message.type = "checkboxChanged";
        message.todoId = idFields[1];
        message.checked = event.srcElement.checked;
        oxide.sendMessage('interaction', message);
    } else if (idFields[0] === attachmentTag) {
        message = new Object;
        message.type = "attachmentOpened";
        message.resourceHash = idFields[1];
        message.mediaType = idFields[2] + "/" + idFields[3]
        oxide.sendMessage('interaction', message);
    }

}

var doc = document.documentElement;
doc.addEventListener('click', handleClickEvent);
