#version 150 core

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

in vec2 shadowCoord;
in vec4 color;
out vec4 fragColor;
uniform sampler2D shadowTexture;
uniform float opacity;

void main(void)
{
    fragColor = (texture2D(shadowTexture, shadowCoord).r * opacity) * color;
}
