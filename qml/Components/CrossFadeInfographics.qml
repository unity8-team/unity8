/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
// FIXME: When a module contains QML, C++ and JavaScript elements exported,
// we need to use named imports otherwise namespace collision is reported
// by the QML engine. As workaround, we use Ubuntu named import.
// Bug to watch: https://bugreports.qt-project.org/browse/QTBUG-27645
import Ubuntu.Components 0.1 as Ubuntu

/*!
   \qmltype CrossFadeImage
   \ingroup ubuntu
   \brief An Image like component which smoothly fades when its source is updated.

   \qml
        import QtQuick 2.0
        import Ubuntu.Components 1.1

        CrossFadeImage {
            width: units.gu(100)
            height: units.gu(75)
            source: "http://design.ubuntu.com/wp-content/uploads/ubuntu-logo14.png"
            fadeDuration: 1000
            MouseArea {
                anchors.fill: parent
                onClicked: parent.source = "http://design.ubuntu.com/wp-content/uploads/canonical-logo1.png"
            }
        }
    \endqml
    */

Item {
    id: crossFadeImage

    /*!
      The image being displayed. Can be a URL to any image format supported by Qt.
     */
    property url source

    /*!
      \qmlproperty enumeration fillMode

      Defaults to \c Image.PreserveAspectFit.

      \list
        \li Image.Stretch - the image is scaled to fit
        \li Image.PreserveAspectFit - the image is scaled uniformly to fit without cropping
        \li Image.PreserveAspectCrop - the image is scaled uniformly to fill, cropping if necessary
        \li Image.Tile - the image is duplicated horizontally and vertically
        \li Image.TileVertically - the image is stretched horizontally and tiled vertically
        \li Image.TileHorizontally - the image is stretched vertically and tiled horizontally
        \li Image.Pad - the image is not transformed
      \endlist
    */
    property int fillMode : Image.PreserveAspectFit

    /*!
      The time over which to fade between images. Defaults to \c UbuntuAnimation.FastDuration.
      \sa UbuntuAnimation
    */
    property int fadeDuration: Ubuntu.UbuntuAnimation.FastDuration

    /*!
      Whether the animation is running
    */
    readonly property bool running: nextImageFadeIn.running

    /*!
      The actual width and height of the loaded image
      This property holds the actual width and height of the loaded image.

      Unlike the width and height properties, which scale the painting of the image,
      this property sets the actual number of pixels stored for the loaded image so that large
      images do not use more memory than necessary.

      Note: Changing this property dynamically causes the image source to be reloaded, potentially
      even from the network, if it is not in the disk cache.
    */
    // FIXME: Support resetting sourceSize
    property size sourceSize: internals.loadingImage ? Qt.size(internals.loadingImage.sourceSize.width, internals.loadingImage.sourceSize.height) : Qt.size(0, 0)

    Binding {
        target: crossFadeImage
        property: "sourceSize"
        value: internals.loadingImage ? Qt.size(internals.loadingImage.sourceSize.width, internals.loadingImage.sourceSize.height) : Qt.size(0, 0)
        when: internals.forcedSourceSize === undefined
    }

    /*!
      \internal
     */
    onSourceSizeChanged: {
        if (internals.loadingImage && (sourceSize != Qt.size(internals.loadingImage.sourceSize.width, internals.loadingImage.sourceSize.height))) {
            internals.forcedSourceSize = sourceSize;
        }
    }

    /*!
      \qmlproperty enumeration status

      This property holds the status of image loading. It can be one of:

      \list
        \li Image.Null - no image has been set
        \li Image.Ready - the image has been loaded
        \li Image.Loading - the image is currently being loaded
        \li Image.Error - an error occurred while loading the image
      \endlist
    */
    readonly property int status: internals.loadingImage ? internals.loadingImage.status : Image.Null

    QtObject {
        id: internals

        /*! \internal
          Source size specified by the setting crossFadeImage.sourceSize.
         */
        property size forcedSourceSize

        /*! \internal
          Defines the image currently being shown
        */
        property Image currentImage: image1
        /*! \internal
          Defines the image being changed to
        */
        property Image nextImage: image2

        property Image loadingImage: currentImage

        function swapImages() {
            internals.currentImage.z = 0;
            internals.nextImage.z = 1;
            nextImageFadeIn.start();

            var tmpImage = internals.currentImage;
            internals.currentImage = internals.nextImage;
            internals.nextImage = tmpImage;
        }
    }

    Image {
        id: image1
        anchors.fill: parent
        cache: false
        asynchronous: true
        fillMode: parent.fillMode
        z: 1
        Binding {
            target: image1
            property: "sourceSize"
            value: internals.forcedSourceSize
            when: internals.forcedSourceSize !== undefined
        }
    }

    Image {
        id: image2
        anchors.fill: parent
        cache: false
        asynchronous: true
        fillMode: parent.fillMode
        z: 0
        Binding {
            target: image2
            property: "sourceSize"
            value: internals.forcedSourceSize
            when: internals.forcedSourceSize !== undefined
        }
    }

    /*!
      \internal
      Do the fading when the source is updated
    */
    onSourceChanged: {
        // On creation, the souce handler is called before image pointers are set.
        if (internals.currentImage === null) {
            internals.currentImage = image1;
            internals.nextImage = image2;
        }

        nextImageFadeIn.stop();

        // Don't fade in initial picture, only fade changes
        if (internals.currentImage.source == "") {
            internals.currentImage.source = source;
            internals.loadingImage = internals.currentImage;
        } else {
            nextImageFadeIn.stop();
            internals.nextImage.opacity = 0.0;
            internals.nextImage.source = source;
            internals.loadingImage = internals.nextImage;

            // If case the image is still in QML's cache, status will be "Ready" immediately
            if (internals.nextImage.status === Image.Ready || internals.nextImage.source === "") {
                internals.swapImages();
            }
        }
    }

    Connections {
        target: internals.nextImage
        onStatusChanged: {
            if (internals.nextImage.status == Image.Ready) {
                 internals.swapImages();
             }
        }
    }

    ParallelAnimation {
        id: nextImageFadeIn

        Ubuntu.UbuntuNumberAnimation {
            id: currentImageFadeOut
            parent: true ? nextImageFadeIn : crossFadeImage
            target: internals.currentImage
            property: "opacity"
            to: 0.0
            duration: crossFadeImage.fadeDuration
        }

        Ubuntu.UbuntuNumberAnimation {
            target: internals.nextImage
            property: "opacity"
            to: 1.0
            duration: crossFadeImage.fadeDuration
        }

        onRunningChanged: {
            if (!running) {
                internals.nextImage.source = "";
            }
        }
    }
}
