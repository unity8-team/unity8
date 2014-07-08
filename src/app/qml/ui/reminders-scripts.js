function handleClickEvent(event) {
    var todoTag = "en-todo";
    if (event.srcElement.id.slice(0, todoTag.length) === todoTag) {
        message = new Object;
        message.type = "checkboxChanged";
        message.todoId = event.srcElement.id;
        message.checked = event.srcElement.checked;
        Oxide.sendMessage(JSON.stringify(message));
    }
}

var doc = document.documentElement;
doc.addEventListener('click', handleClickEvent);
