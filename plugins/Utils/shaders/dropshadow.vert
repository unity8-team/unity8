// Copyright © 2015 Canonical Ltd.
// Author: Loïc Molinari <loic.molinari@canonical.com>
//
// This file is part of Quick+.
//
// Quick+ is free software: you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free
// Software Foundation; version 3.
//
// Quick+ is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
// details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Quick+. If not, see <http://www.gnu.org/licenses/>.

uniform highp mat4 matrix;
attribute highp vec4 positionAttrib;
attribute mediump vec2 shadowCoordAttrib;
attribute lowp vec4 colorAttrib;
varying mediump vec2 shadowCoord;
varying lowp vec4 color;

void main()
{
    shadowCoord = shadowCoordAttrib;
    color = colorAttrib;
    gl_Position = matrix * positionAttrib;
}
