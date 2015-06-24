AbstractButton { 
                id: root; 
                property var components; 
                property var cardData; 
                property string artShapeStyle: "inset"; 
                property real fontScale: 1.0; 
                property var scopeStyle: null; 
                property int titleAlignment: Text.AlignLeft; 
                property int fixedHeaderHeight: -1; 
                property size fixedArtShapeSize: Qt.size(-1, -1); 
                readonly property string title: cardData && cardData["title"] || ""; 
                property bool asynchronous: true; 
                property bool showHeader: true; 
                implicitWidth: childrenRect.width; 
                enabled: true;

readonly property size artShapeSize: artShapeLoader.item ? Qt.size(artShapeLoader.item.width, artShapeLoader.item.height) : Qt.size(-1, -1);
Item  { 
                            id: artShapeHolder; 
                            height: root.fixedArtShapeSize.height > 0 ? root.fixedArtShapeSize.height : artShapeLoader.height; 
                            width: root.fixedArtShapeSize.width > 0 ? root.fixedArtShapeSize.width : artShapeLoader.width; 
                            anchors { horizontalCenter: parent.horizontalCenter; } 
                            Loader { 
                                id: artShapeLoader; 
                                objectName: "artShapeLoader"; 
                                active: cardData && cardData["art"] || false; 
                                asynchronous: root.asynchronous; 
                                visible: status == Loader.Ready; 
                                sourceComponent: Item {
                                    id: artShape;
                                    objectName: "artShape";
                                    readonly property bool doShadow: root.artShapeStyle === "shadow"; 
                                    readonly property bool doShapeItem: components["art"]["conciergeMode"] !== true;
                                    visible: image.status == Image.Ready;
                                    readonly property alias image: artImage.image;
                                    property alias borderSource: artShapeShape.borderSource;
                                    ShaderEffectSource {
                                        id: artShapeSource;
                                        sourceItem: artImage;
                                        anchors.centerIn: parent;
                                        width: 1;
                                        height: 1;
                                        hideSource: doShapeItem;
                                    }
                                    Shape {
                                        id: artShapeShape;
                                        image: artShapeSource;
                                        anchors.fill: parent;
                                        visible: doShapeItem;
                                        radius: "medium";
                                        borderSource: root.artShapeStyle === "inset" ? "radius_idle.sci" : "none"; 
                                    }
                                    readonly property real fixedArtShapeSizeAspect: (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) ? root.fixedArtShapeSize.width / root.fixedArtShapeSize.height : -1;
                                    readonly property real aspect: fixedArtShapeSizeAspect > 0 ? fixedArtShapeSizeAspect : components !== undefined ? components["art"]["aspect-ratio"] : 1; 
                                    Component.onCompleted: { updateWidthHeightBindings(); }
                                    Connections { target: root; onFixedArtShapeSizeChanged: updateWidthHeightBindings(); } 
                                    function updateWidthHeightBindings() { 
                                        if (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) { 
                                            width = root.fixedArtShapeSize.width; 
                                            height = root.fixedArtShapeSize.height; 
                                        } else { 
                                            width = Qt.binding(function() { return image.status !== Image.Ready ? 0 : image.width });
                                            height = Qt.binding(function() { return image.status !== Image.Ready ? 0 : image.height });
                                        } 
                                    } 
                                    CroppedImageMinimumSourceSize {
                                        id: artImage;
                                        objectName: "artImage"; 
                                        source: cardData && cardData["art"] || ""; 
                                        asynchronous: root.asynchronous; 
                                        width: root.width; 
                                        height: width / artShape.aspect; 
                                    } 
                                    Image { 
                                        anchors.centerIn: parent; 
                                        source: "shadow.png"; 
                                        width: parent.width + units.gu(1); 
                                        height: parent.height + units.gu(1); 
                                        fillMode: Image.PreserveAspectCrop; 
                                        visible: doShadow; 
                                        z: -1; 
                                    } 
                                    BorderImage { 
                                        anchors.centerIn: parent; 
                                        source: "bevel.png"; 
                                        width: parent.width; 
                                        height: parent.height; 
                                        visible: doShadow; 
                                        z: 1; 
                                    } 
                                    BrightnessContrast { 
                                        anchors.fill: artShapeShape; 
                                        source: artShapeShape; 
                                        brightness: doShadow && root.pressed ? 0.25 : 0; 
                                        Behavior on brightness { UbuntuNumberAnimation { duration: UbuntuAnimation.SnapDuration } } 
                                    } 
                                } 
                            } 
                        }
readonly property int headerHeight: titleLabel.height;
Label { 
                        id: titleLabel; 
                        objectName: "titleLabel"; 
                        anchors { right: parent.right;
                        left: parent.left;
                        top: artShapeHolder.bottom; 
                        topMargin: units.gu(1);
                        } 
                        elide: Text.ElideRight; 
                        fontSize: "small"; 
                        wrapMode: Text.Wrap; 
                        maximumLineCount: 2; 
                        font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                        color: root.scopeStyle ? root.scopeStyle.foreground : Theme.palette.normal.baseText;
                        visible: showHeader ; 
                        text: root.title; 
                        font.weight: cardData && cardData["subtitle"] ? Font.DemiBold : Font.Normal; 
                        horizontalAlignment: root.titleAlignment; 
                    }
UbuntuShape {
    id: touchdown;
    objectName: "touchdown";
    anchors { fill: artShapeHolder }
    visible: root.artShapeStyle != "shadow" && root.pressed;
    radius: "medium";
    borderSource: "radius_pressed.sci"
}
implicitHeight: titleLabel.y + titleLabel.height + units.gu(1);
}
