var data = null;
try {
    data = JSON.parse(message.data);
} catch (error) {
    print("Failed to parse message:", message.data, error);
}

switch (data.type) {
    case "checkboxChanged":
        note.markTodo(data.todoId, data.checked);
        NotesStore.saveNote(note.guid);
        break;
}
