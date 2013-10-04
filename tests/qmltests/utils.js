.pragma library

function findChild(obj,objectName) {
    for (var i in obj.children) {
        var child = obj.children[i];
        if (child.objectName === objectName) return child;
        var subChild = findChild(child,objectName);
        if (subChild !== undefined) return subChild;
    }
    return undefined;
}
