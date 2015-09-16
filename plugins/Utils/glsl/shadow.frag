// Copyright © 2015 Canonical Ltd.
//
// This program is free software; you can redistribute it and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation; version 3.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
// even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along with this program.
// If not, see <http://www.gnu.org/licenses/>.
//
// Author: Loïc Molinari <loic.molinari@canonical.com>

uniform sampler2D contentTexture;
uniform bool textured;
uniform lowp float opacity;
uniform lowp float shadowOpacity;
varying mediump vec2 shadowCoord;
varying mediump vec2 contentCoord;
varying mediump float contentFactor;

void main(void)
{
    // FIXME(loicm) If we drop the textured shadows, shadowCoord could be adapted so that we can
    //     drop the subtraction.
    lowp float shadow = max(0.0, min(1.0, length(1.0 - shadowCoord)));
    shadow = 2.0 * shadow - shadow * shadow;  // Falloff
    lowp vec4 color = vec4(0.0, 0.0, 0.0, -shadow * shadowOpacity + shadowOpacity);
    lowp vec4 content = textured ?
        texture2D(contentTexture, contentCoord) : vec4(0.0, 0.0, 0.0, 1.0);
    content *= vec4(max(0.0, contentFactor));
    color = vec4(1.0 - content.a) * color + content;
    gl_FragColor = color * vec4(opacity);
}
