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
varying mediump vec2 contentCoord;

void main(void)
{
    gl_FragColor = textured ?
        texture2D(contentTexture, contentCoord) * vec4(opacity) : vec4(0.0, 0.0, 0.0, opacity);
}
