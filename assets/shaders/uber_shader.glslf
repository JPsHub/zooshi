// Copyright 2016 Google Inc. All rights reserved.
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

#include "shaders/fplbase/phong_shading.glslf_h"
#include "shaders/include/fog_effect.glslf_h"
#include "shaders/include/shadow_map.glslf_h"
#include "shaders/include/water.glslf_h"

varying mediump vec2 vTexCoord;
uniform sampler2D texture_unit_0;
uniform lowp vec4 color;

#ifdef PHONG_SHADING
// Variables used in lighting:
varying vec3 vPosition;
varying lowp vec4 vColor;
varying vec3 vNormal;
#ifndef NORMALS
#ifndef SHADOW_EFFECT
uniform vec3 light_pos;
uniform vec3 camera_pos;
#endif  // SHADOW_EFFECT
#endif  // NORMALS
#endif  // PHONG_SHADING

#ifdef SHADOW_EFFECT
// Variables used by shadow maps:
uniform mediump mat4 shadow_mvp;
// The position of the coordinate, in light-space
varying vec4 vShadowPosition;

uniform vec3 light_pos;     // in object space
uniform vec3 camera_pos;    // in object space
#endif  // SHADOW_EFFECT

#ifdef BANK
uniform sampler2D texture_unit_1;
#ifndef PHONG_SHADING
varying lowp vec4 vColor;
#endif  // PHONG_SHADING
#endif  // BANK

#ifdef NORMALS
varying mediump vec3 vObjectSpacePosition;
varying lowp vec3 vTangentSpaceLightVector;
varying lowp vec3 vTangentSpaceCameraVector;
// Normal map
#ifndef BANK
uniform sampler2D texture_unit_1;
#else
uniform sampler2D texture_unit_2;
#endif  // BANK
#endif  // NORMALS

void main()
{
  #ifdef BANK
  // Blend between the bank's two textures based on the vertex color's alpha.
  mediump vec4 texture_color =
    texture2D(texture_unit_0, vTexCoord) * (1.0 - vColor.a) +
    texture2D(texture_unit_1, vTexCoord) * vColor.a;
  #else
  #ifdef WATER
  highp vec2 texture_coords = CalculateWaterTextureCoordinates(vTexCoord);
  lowp vec4 texture_color = texture2D(texture_unit_0, texture_coords);
  #else
  lowp vec4 texture_color = texture2D(texture_unit_0, vTexCoord);
  #endif  // WATER
  #endif  // BANK

  // Apply the object tint:
  lowp vec4 final_color = color * texture_color;

  #ifdef PHONG_SHADING
  #ifdef NORMALS
  #ifndef BANK
  lowp vec3 tangent_space_normal =
      texture2D(texture_unit_1, vTexCoord).yxz * 2.0 - 1.0;
  #else
  lowp vec3 tangent_space_normal =
      texture2D(texture_unit_2, vTexCoord).yxz * 2.0 - 1.0;
  #endif  // BANK

  vec3 normal = normalize(tangent_space_normal);
  vec3 light_direction = normalize(vTangentSpaceLightVector);

  lowp vec4 shading_tint = CalculatePhong(vPosition, normal, light_direction);

  #ifdef SPECULAR_EFFECT
  shading_tint += CalculateSpecular(vPosition, normal, light_direction, vTangentSpaceCameraVector);
  #endif  // SPECULAR_EFFECT
  #else
  vec3 light_direction = CalculateLightDirection(vPosition, light_pos);

  lowp vec4 shading_tint = CalculatePhong(vPosition, vNormal, light_direction);
  #ifdef SPECULAR_EFFECT
  shading_tint += CalculateSpecular(vPosition, vNormal, light_direction, camera_pos);
  #endif  // SPECULAR_EFFECT
  #endif  // NORMALS

  final_color *= shading_tint;
  #endif  // PHONG_SHADING

  #ifdef FOG_EFFECT
  // Apply the fog:
  final_color = ApplyFog(final_color, vDepth, fog_roll_in_dist, fog_max_dist,
      fog_color, fog_max_saturation);
  #endif  // FOG_EFFECT

  #ifdef SHADOW_EFFECT
  // Apply the shadow map:
  mediump vec2 shadowmap_coords = CalculateShadowMapCoords(vShadowPosition);

  highp float light_dist = vShadowPosition.z / vShadowPosition.w;
  light_dist = (light_dist + 1.0) / 2.0;

  // Apply shadows:
  final_color = ApplyShadows(final_color, shadowmap_coords, light_dist);
  #endif  // SHADOW_EFFECT

  gl_FragColor = final_color;
}
