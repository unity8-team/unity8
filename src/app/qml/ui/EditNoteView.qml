/*
 * Copyright: 2013-2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Content 0.1
import Ubuntu.Components.Themes.Ambiance 1.1
import Evernote 0.1
import reminders 1.0
import "../components"

Item {
    id: root
    property var note

    onNoteChanged: {
        for (var i = 0; i < notebookSelector.values.count; i++) {
            if (notebookSelector.values.notebook(i).guid == note.notebookGuid) {
                notebookSelector.selectedIndex = i;
            }
        }
    }

    signal exitEditMode(var note)

    function saveNote() {
        var title = titleTextField.text ? titleTextField.text : i18n.tr("Untitled");
        var notebookGuid = notebookSelector.selectedGuid;
        var text = noteTextArea.text;

        if (note) {
            note.title = titleTextField.text;
            note.notebookGuid = notebookSelector.selectedGuid;
            note.richTextContent = noteTextArea.text;
            NotesStore.saveNote(note.guid);
        } else {
            NotesStore.createNote(title, notebookGuid, text);
        }
    }

    QtObject {
        id: priv
        property int insertPosition
        property var activeTransfer
    }

    ContentTransferHint {
        id: transferHint
        anchors.fill: parent
        activeTransfer: priv.activeTransfer
    }

    Connections {
         target: priv.activeTransfer ? priv.activeTransfer : null
         onStateChanged: {
             if (priv.activeTransfer.state === ContentTransfer.Charged) {
                 var file = priv.activeTransfer.items[0].url.toString()
                 print("attaching file", file, "on note", note)
                 note.attachFile(priv.insertPosition, file);
                 noteTextArea.insert(priv.insertPosition + 1, "<br>&nbsp;")
             }
         }
     }

    Connections {
        target: noteTextArea
        onWidthChanged: {
            note.richTextContent = noteTextArea.text;
            note.renderWidth = noteTextArea.width - noteTextArea.textMargin
        }
    }

    Column {
        anchors { left: parent.left; top: parent.top; right: parent.right; bottom: toolbox.top }

        Rectangle {
            anchors { left: parent.left; right: parent.right }
            height: parent.height - y
            color: "white"

            Flickable {
                 id: flick
                 anchors.fill: parent
                 contentWidth: parent.width
                 contentHeight: innerColumn.height
                 flickableDirection: Flickable.VerticalFlick
                 clip: true

                 function ensureVisible(r)
                 {
                     var staticHeight = titleTextField.height + notebookSelector.height
                     if (contentX >= r.x)
                         contentX = r.x;
                     else if (contentX +width <= r.x+r.width)
                         contentX = r.x+r.width-width;
                     if (contentY >= r.y)
                         contentY = r.y;
                     else if (contentY + height <= r.y + staticHeight + r.height) {
                         contentY = r.y + r.height - staticHeight;
                     }
                 }

                 Column {
                     id: innerColumn
                     width: parent.width
                     height: childrenRect.height

                     TextField {
                         id: titleTextField
                         height: units.gu(6)
                         width: parent.width
                         text: root.note ? root.note.title : ""
                         placeholderText: i18n.tr("Untitled")
                         font.pixelSize: units.gu(4)
                         style: TextFieldStyle {
                             background: null
                         }
                     }

                     ThinDivider {}

                     ValueSelector {
                         id: notebookSelector
                         width: parent.width
                         text: values.notebook(selectedIndex).name
                         property string selectedGuid: values.notebook(selectedIndex) ? values.notebook(selectedIndex).guid : ""
                         values: Notebooks {}

                         // The ValueSelector is not customizable enough, yet we wanna use the expanstion it provides. Let's just paint on top of it

                         Rectangle {
                             anchors { left: parent.left; right: parent.right; top: parent.top }
                             height: units.gu(6)
                             color: "white"

                             RowLayout {
                                 anchors.fill: parent
                                 anchors.margins: units.gu(1)

                                 Item {
                                     height: parent.height
                                     width: height
                                     Icon {
                                         anchors.fill: parent
                                         anchors.margins: units.gu(0.5)
                                         name: "notebook"
                                         color: preferences.colorForNotebook(notebookSelector.values.notebook(notebookSelector.selectedIndex).guid)
                                     }
                                 }

                                 Label {
                                     text: notebookSelector.values.notebook(notebookSelector.selectedIndex).name
                                     Layout.fillWidth: true
                                     color: preferences.colorForNotebook(notebookSelector.values.notebook(notebookSelector.selectedIndex).guid)
                                 }
                                 RtfButton {
                                     iconName: root.note && root.note.reminder ? "reminder" : "reminder-new"
                                     height: parent.height
                                     width: height
                                     iconColor: root.note && note.reminder ? UbuntuColors.blue : Qt.rgba(0.0, 0.0, 0.0, 0.0)
                                     onClicked: {
                                         Qt.inputMethod.hide();
                                         pageStack.push(Qt.resolvedUrl("SetReminderPage.qml"), { note: root.note});
                                     }
                                 }
                                 RtfButton {
                                     id: tagsButton
                                     iconSource: "../images/tags.svg"
                                     height: parent.height
                                     width: height
                                     onClicked: {
                                         Qt.inputMethod.hide();
                                         PopupUtils.open(tagsDialog)
                                     }
                                 }
                             }
                         }
                     }

                     ThinDivider {}

                     TextEdit {
                         id: noteTextArea
                         width: flick.width
                         height: Math.max(flick.height - notebookSelector.height - titleTextField.height, paintedHeight)
                         focus: true
                         wrapMode: TextEdit.Wrap
                         textFormat: TextEdit.RichText
                         text: root.note ? root.note.richTextContent : ""
                         onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                         selectByMouse: toolbox.charFormatExpanded
                         textMargin: units.gu(1)
                         selectionColor: UbuntuColors.blue

                         // Due to various things updating when creating the view,
                         // we need to set the focus in the next event loop pass
                         // in order to have any effect.
                         Timer {
                             id: setFocusTimer
                             interval: 1
                             repeat: false
                             onTriggered: {
                                 noteTextArea.cursorPosition = noteTextArea.length;
                                 noteTextArea.forceActiveFocus();
                             }
                         }
                     }
                 }
            }
        }
    }

    FormattingHelper {
        id: formattingHelper
        textDocument: noteTextArea.textDocument
        cursorPosition: noteTextArea.cursorPosition
        selectionStart: noteTextArea.selectionStart
        selectionEnd: noteTextArea.selectionEnd
    }

    Component {
        id: fontPopoverComponent
        Popover {
            id: fontPopover

            property int selectionStart: -1
            property int selectionEnd: -1

            ListView {
                width: parent.width - units.gu(2)
                height: Math.min(contentHeight, root.height / 2)
                model: formattingHelper.allFontFamilies
                clip: true
                delegate: Empty {
                    height: units.gu(6)
                    width: parent.width
                    Label {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        font.family: modelData
                    }
                    onClicked: {
                        noteTextArea.cursorPosition = fontPopover.selectionStart;
                        noteTextArea.moveCursorSelection(fontPopover.selectionEnd);
                        formattingHelper.fontFamily = modelData;
                        PopupUtils.close(fontPopover)
                    }
                }
            }
        }
    }
    Component {
        id: fontSizePopoverComponent
        Popover {
            id: fontSizePopover

            property int selectionStart: -1
            property int selectionEnd: -1

            ListView {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Math.min(contentHeight, root.height / 2)
                clip:true
                model: ListModel {
                    ListElement { modelData: "8" }
                    ListElement { modelData: "10" }
                    ListElement { modelData: "12" }
                    ListElement { modelData: "14" }
                    ListElement { modelData: "18" }
                    ListElement { modelData: "24" }
                    ListElement { modelData: "36" }
                }

                delegate: Empty {
                    Label {
                        anchors.fill: parent
                        anchors.margins: units.gu(1)
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        font.family: modelData
                    }
                    onClicked: {
                        noteTextArea.cursorPosition = fontSizePopover.selectionStart;
                        noteTextArea.moveCursorSelection(fontSizePopover.selectionEnd);
                        formattingHelper.fontSize = modelData;
                        PopupUtils.close(fontSizePopover)
                    }
                }
            }
        }
    }

    Component {
        id: colorPopoverComponent
        Popover {
            id: colorPopover

            property int selectionStart: -1
            property int selectionEnd: -1

            GridView {
                id: colorsGrid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(0.5) }
                height: cellWidth * 5 + units.gu(1)


                cellWidth: width / 8
                cellHeight: cellWidth

                model: ListModel {
                    ListElement { color: "#000000" }
                    ListElement { color: "#993300" }
                    ListElement { color: "#333300" }
                    ListElement { color: "#003300" }
                    ListElement { color: "#003366" }
                    ListElement { color: "#000080" }
                    ListElement { color: "#333399" }
                    ListElement { color: "#333333" }

                    ListElement { color: "#800000" }
                    ListElement { color: "#ff6600" }
                    ListElement { color: "#808000" }
                    ListElement { color: "#008000" }
                    ListElement { color: "#008080" }
                    ListElement { color: "#0000ff" }
                    ListElement { color: "#666699" }
                    ListElement { color: "#808080" }

                    ListElement { color: "#ff0000" }
                    ListElement { color: "#ff6600" }
                    ListElement { color: "#99CC00" }
                    ListElement { color: "#339966" }
                    ListElement { color: "#33CCCC" }
                    ListElement { color: "#3366FF" }
                    ListElement { color: "#800080" }
                    ListElement { color: "#999999" }

                    ListElement { color: "#ff00ff" }
                    ListElement { color: "#ffcc00" }
                    ListElement { color: "#ffff00" }
                    ListElement { color: "#00ff00" }
                    ListElement { color: "#00ffff" }
                    ListElement { color: "#00ccff" }
                    ListElement { color: "#993366" }
                    ListElement { color: "#c0c0c0" }

                    ListElement { color: "#ff99cc" }
                    ListElement { color: "#ffcc99" }
                    ListElement { color: "#ffff99" }
                    ListElement { color: "#ccffcc" }
                    ListElement { color: "#ccffff" }
                    ListElement { color: "#99ccff" }
                    ListElement { color: "#cc99ff" }
                    ListElement { color: "#ffffff" }
                }
                delegate: AbstractButton {
                    width: colorsGrid.cellWidth
                    height: colorsGrid.cellHeight
                    UbuntuShape {
                        anchors.fill: parent
                        anchors.margins: units.gu(.5)
                        color: model.color
                        radius: "small"
                    }
                    onClicked: {
                        noteTextArea.cursorPosition = colorPopover.selectionStart;
                        noteTextArea.moveCursorSelection(colorPopover.selectionEnd);
                        formattingHelper.color = color
                        PopupUtils.close(colorPopover)
                    }
                }
            }
        }
    }

    Component {
        id: tagsDialog
        EditTagsDialog { note: root.note; pageHeight: parent.height }
    }

    Rectangle {
        anchors.fill: toolbox
        color: "#efefef"
    }

    Column {
        id: toolbox
        anchors { left: parent.left; right: parent.right; bottom: keyboardRect.top }
        height: implicitHeight + units.gu(1)
        clip: true
        spacing: units.gu(1)

        property bool charFormatExpanded: false
        property bool blockFormatExpanded: false

        Behavior on height { UbuntuNumberAnimation {} }

        move: Transition {
            UbuntuNumberAnimation { properties: "y" }
        }
        add: Transition {
            UbuntuNumberAnimation { property: "opacity"; from: 0; to: 1 }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            height: 1
        }

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            height: units.gu(4)
            visible: toolbox.charFormatExpanded
            opacity: visible ? 1 : 0

            RtfButton {
                id: fontButton
                text: formattingHelper.fontFamily || i18n.tr("Font")
                height: parent.height
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
                onClicked: {
                    Qt.inputMethod.hide();
                    PopupUtils.open(fontPopoverComponent, fontButton, {selectionStart: noteTextArea.selectionStart, selectionEnd: noteTextArea.selectionEnd})
                }
            }

            RtfButton {
                id: fontSizeButton
                text: formattingHelper.fontSize || i18n.tr("Size")
                height: parent.height
                width: height
                onClicked: {
                    Qt.inputMethod.hide();
                    PopupUtils.open(fontSizePopoverComponent, fontSizeButton, {selectionStart: noteTextArea.selectionStart, selectionEnd: noteTextArea.selectionEnd})
                }
            }
            RtfButton {
                id: colorButton
                height: parent.height
                width: height
                color: formattingHelper.color
                onClicked: {
                    Qt.inputMethod.hide();
                    PopupUtils.open(colorPopoverComponent, colorButton, {selectionStart: noteTextArea.selectionStart, selectionEnd: noteTextArea.selectionEnd})
                }
            }

            RtfButton {
                height: parent.height
                width: height
                // TRANSLATORS: Toolbar button for "Bold"
                text: i18n.tr("B")
                font.bold: true
                font.family: "Serif"
                active: formattingHelper.bold
                onClicked: {
                    formattingHelper.bold = !formattingHelper.bold
                }
            }

            RtfButton {
                height: parent.height
                width: height
                // TRANSLATORS: Toolbar button for "Italic"
                text: i18n.tr("I")
                font.bold: true
                font.italic: true
                font.family: "Serif"
                active: formattingHelper.italic
                onClicked: {
                    formattingHelper.italic = !formattingHelper.italic;
                }
            }

            RtfButton {
                height: parent.height
                width: height
                // TRANSLATORS: Toolbar button for "Underline"
                text: i18n.tr("U")
                font.bold: true
                font.underline: true
                font.family: "Serif"
                active: formattingHelper.underline
                onClicked: {
                    formattingHelper.underline = !formattingHelper.underline;
                }
            }

            RtfButton {
                height: parent.height
                width: height
                // TRANSLATORS: Toolbar button for "Strikeout"
                text: i18n.tr("T")
                font.bold: true
                font.strikeout: true
                font.family: "Serif"
                active: formattingHelper.strikeout
                onClicked: {
                    formattingHelper.strikeout = !formattingHelper.strikeout;
                }
            }
        }

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            height: units.gu(4)
            visible: toolbox.blockFormatExpanded
            opacity: visible ? 1 : 0

            RtfButton {
                iconSource: "../images/bullet-list.svg"
                height: parent.height
                width: height
                active: formattingHelper.bulletList
                onClicked: {
                    formattingHelper.bulletList = !formattingHelper.bulletList;
                }
            }

            RtfButton {
                iconSource: "../images/numbered-list.svg"
                height: parent.height
                width: height
                active: formattingHelper.numberedList
                onClicked: {
                    formattingHelper.numberedList = !formattingHelper.numberedList;
                }
            }

            RtfSeparator {}

            RtfButton {
                height: parent.height
                width: height
                iconSource: "../images/indent-block.svg"
                onClicked: {
                    formattingHelper.indentBlock();
                }
            }
            RtfButton {
                height: parent.height
                width: height
                iconSource: "../images/unindent-block.svg"
                onClicked: {
                    formattingHelper.unindentBlock();
                }
            }

            RtfSeparator {}

            RtfButton {
                height: parent.height
                width: height
                iconSource: "../images/left-align.svg"
                active: formattingHelper.alignment & Qt.AlignLeft
                onClicked: {
                    formattingHelper.alignment = Qt.AlignLeft
                }
            }
            RtfButton {
                height: parent.height
                width: height
                iconSource: "../images/center-align.svg"
                active: formattingHelper.alignment & Qt.AlignHCenter
                onClicked: {
                    formattingHelper.alignment = Qt.AlignHCenter
                }
            }
            RtfButton {
                height: parent.height
                width: height
                iconSource: "../images/right-align.svg"
                active: formattingHelper.alignment & Qt.AlignRight
                onClicked: {
                    formattingHelper.alignment = Qt.AlignRight
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        RowLayout {
            anchors { left: parent.left; right: parent.right }
            anchors.margins: units.gu(1)
            height: units.gu(4)

            RtfButton {
                iconName: "tick"
                // TRANSLATORS: Button to close the edit mode
                text: i18n.tr("Done")
                height: parent.height
                iconColor: UbuntuColors.green
                onClicked: {
                    saveNote();
                    root.exitEditMode(root.note);
                }
            }

            RtfSeparator { }

            RtfButton {
                iconName: "undo"
                height: parent.height
                width: height
                enabled: formattingHelper.canUndo
                onClicked: {
                    formattingHelper.undo();
                }
            }
            RtfButton {
                iconName: "redo"
                height: parent.height
                width: height
                enabled: formattingHelper.canRedo
                onClicked: {
                    formattingHelper.redo();
                }
            }

            RtfSeparator {}

            Item {
                Layout.fillWidth: true
            }

            RtfSeparator {}

            RtfButton {
                iconName: "select"
                height: parent.height
                width: height
                onClicked: {
                    var pos = noteTextArea.cursorPosition
                    noteTextArea.insert(pos, "<img src=\"../images/unchecked.svg\" height=" + units.gu(2) + ">")
                    noteTextArea.cursorPosition = pos + 1;
                }
            }

// TextEdit can't display horizontal lines yet :/
// https://bugreports.qt-project.org/browse/QTBUG-42545
//            RtfButton {
//                text: "__"
//                height: parent.height
//                width: height
//                onClicked: {
//                    formattingHelper.addHorizontalLine();
//                }
//            }

            RtfButton {
                iconName: "attachment"
                height: parent.height
                width: height
                onClicked: {
                    priv.insertPosition = noteTextArea.cursorPosition;
                    note.richTextContent = noteTextArea.text;
                    importPicker.visible = true;
                    Qt.inputMethod.hide();
                }
            }

            RtfSeparator {}

            RtfButton {
                iconName: "navigation-menu"
                height: parent.height
                width: height
                active: toolbox.blockFormatExpanded
                onClicked: {
                    toolbox.blockFormatExpanded = !toolbox.blockFormatExpanded
                }
            }

            RtfButton {
                iconName: "edit-select-all"
                height: parent.height
                width: height
                active: toolbox.charFormatExpanded
                onClicked: {
                    toolbox.charFormatExpanded = !toolbox.charFormatExpanded
                }
            }
        }
    }

    Item {
        id: keyboardRect
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Qt.inputMethod.keyboardRectangle.height
    }

    ContentPeerPicker {
        id: importPicker
        anchors.fill: parent
        contentType: ContentType.Pictures
        handler: ContentHandler.Source
        visible: false

        onCancelPressed: visible = false

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single
            priv.activeTransfer = peer.request()
            visible = false;
        }
    }
}

