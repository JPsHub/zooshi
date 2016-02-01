// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "shaders/include/water.glslf_h"

varying mediump vec2 vTexCoord;
uniform sampler2D texture_unit_0;
uniform lowp vec4 color;

void main() {
  highp vec2 tc = CalculateWaterTextureCoordinates(vTexCoord);

  lowp vec4 texture_color = texture2D(texture_unit_0, tc);

  gl_FragColor = color * texture_color;
}
