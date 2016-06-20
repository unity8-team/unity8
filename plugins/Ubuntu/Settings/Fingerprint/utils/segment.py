#!/usr/bin/python2
"""
 * Copyright 2016 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by  Florian Boucault <florian.boucault@canonical.com>
 */
"""

import os.path
import argparse
import json
import cv2

parser = argparse.ArgumentParser(
    description='Generates segmented version of img and extracts bbs.'
)
parser.add_argument('input_image', type=str,
                    help='path to the image to segment')
args = parser.parse_args()

input_image = os.path.abspath(args.input_image)
print("Segmenting %s..." % input_image)
filename, _ = os.path.splitext(os.path.basename(input_image))
split = filename.split('@')
if len(split) != 1:
    output_image = "%s_segmented@%s.png" % (split[0], split[1])
    output_boxes = "%s_boxes.json" % split[0]
else:
    output_image = "%s_segmented.png" % filename
    output_boxes = "%s_boxes.json" % filename

img = cv2.imread(input_image, -1)
img_boxes = img.copy()
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
ret, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY)
contours, hierarchy = cv2.findContours(
    thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE
)

print("Detected %d segments." % len(contours))

bounding_boxes = []
for index, contour in enumerate(contours):
    x, y, w, h = cv2.boundingRect(contour)
    bounding_boxes.append((x, y, w, h))
#  print(x, y, w, h)
    cv2.rectangle(img_boxes,
                  (x, y),
                  (x + w, y + h),
                  (255, 20, 20, 255), 1)
    cv2.drawContours(thresh, contours, index, (index + 1),
                     cv2.cv.CV_FILLED)
    cv2.drawContours(thresh, contours, index, (index + 1), 2)

b, g, r, a = cv2.split(img)
img = cv2.merge([a, g, thresh])

cv2.imwrite(output_image, img)
print("Written segmented version of '%s' to '%s'" % (
    args.input_image, output_image)
)

description = {"width": img.shape[1],
               "height": img.shape[0],
               "boxes": bounding_boxes}
with open(output_boxes, 'w') as outfile:
    json.dump(description, outfile)
print("Written bounding boxes to '%s'" % output_boxes)

cv2.imshow('image', img_boxes)
cv2.waitKey(0)
cv2.destroyAllWindows()
