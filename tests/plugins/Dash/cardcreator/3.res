AbstractButton { 
                id: root; 
                property var template; 
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
                enabled: root.template == null ? true : (root.template["non-interactive"] !== undefined ? !root.template["non-interactive"] : true);

onArtShapeStyleChanged: { if (artShapeLoader.item) artShapeLoader.item.artShapeStyle = artShapeStyle; } 
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
                                sourceComponent: UbuntuShape { 
                                    id: artShape; 
                                    objectName: "artShape"; 
                                    radius: "medium"; 
                                    aspect: root.artShapeStyle === "inset" ? UbuntuShape.Inset : UbuntuShape.Flat; 
                                    visible: source.status == Image.Ready; 
                                    readonly property real fixedArtShapeSizeAspect: (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) ? root.fixedArtShapeSize.width / root.fixedArtShapeSize.height : -1; 
                                    readonly property real artAspect: fixedArtShapeSizeAspect > 0 ? fixedArtShapeSizeAspect : 0.75;
                                    Component.onCompleted: { updateWidthHeightBindings(); } 
                                    Connections { target: root; onFixedArtShapeSizeChanged: updateWidthHeightBindings(); } 
                                    function updateWidthHeightBindings() { 
                                        if (root.fixedArtShapeSize.height > 0 && root.fixedArtShapeSize.width > 0) { 
                                            width = root.fixedArtShapeSize.width; 
                                            height = root.fixedArtShapeSize.height; 
                                        } else { 
                                            width = Qt.binding(function() { return source.status !== Image.Ready ? 0 : source.width });
                                            height = Qt.binding(function() { return source.status !== Image.Ready ? 0 : source.height });
                                        }
                                    } 
                                    CroppedImageMinimumSourceSize {
                                        id: artImage;
                                        objectName: "artImage";
                                        source: cardData && cardData["art"] || ""; 
                                        asynchronous: root.asynchronous;
                                        visible: false;
                                        width: root.width;
                                        height: width / artShape.artAspect;
                                    }
                                    source: artImage.image; 
                                    sourceFillMode: UbuntuShape.PreserveAspectCrop; 
                                } 
                            } 
                            BorderImage { 
                                id: itemGlow 
                                anchors.centerIn: artShapeLoader; 
                                source: "shadow.png"; 
                                width: artShapeLoader.width + units.gu(0.5); 
                                height: artShapeLoader.height + units.gu(0.5); 
                                visible: root.artShapeStyle === "shadow"; 
                                z: -1; 
                            } 
                            BorderImage { 
                                id: bevel 
                                anchors.centerIn: artShapeLoader; 
                                source: "bevel.png"; 
                                width: artShapeLoader.width; 
                                height: artShapeLoader.height; 
                                visible: root.artShapeStyle === "shadow"; 
                                z: 1; 
                            } 
                        }
readonly property int headerHeight: titleLabel.height + subtitleLabel.height + subtitleLabel.anchors.topMargin;
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
                        color: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText;
                        visible: showHeader ; 
                        text: root.title; 
                        font.weight: cardData && cardData["subtitle"] ? Font.DemiBold : Font.Normal; 
                        horizontalAlignment: root.titleAlignment; 
                    }
Label { 
                            id: subtitleLabel; 
                            objectName: "subtitleLabel"; 
                            anchors { left: titleLabel.left; 
                            leftMargin: titleLabel.leftMargin; 
                            right: titleLabel.right; 
                            top: titleLabel.bottom; 
                            } 
                            anchors.topMargin: units.dp(2);
                            elide: Text.ElideRight; 
                            maximumLineCount: 1; 
                            fontSize: "x-small"; 
                            font.pixelSize: Math.round(FontUtils.sizeToPixels(fontSize) * fontScale); 
                            color: root.scopeStyle ? root.scopeStyle.foreground : theme.palette.normal.baseText;
                            visible: titleLabel.visible && titleLabel.text; 
                            text: cardData && cardData["subtitle"] || ""; 
                            font.weight: Font.Light; 
                        }
UbuntuShape {
    id: touchdown;
    objectName: "touchdown";
    anchors { fill: artShapeHolder }
    visible: root.pressed;
    radius: "medium";
    borderSource: "radius_pressed.sci"
}
implicitHeight: subtitleLabel.y + subtitleLabel.height + units.gu(1);
}
