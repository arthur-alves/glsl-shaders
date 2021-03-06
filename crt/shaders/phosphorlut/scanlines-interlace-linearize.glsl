/*
   Interlacing
   Author: hunterk
   License: Public domain
   
   Note: This shader is designed to work with the typical interlaced output from an emulator, which displays both even and odd fields twice.
   This shader will un-weave the image, resulting in a standard, alternating-field interlacing.
*/

// Parameter lines go here:
#pragma parameter input_gamma "CRT Gamma" 2.5 0.0 5.0 0.1
#pragma parameter percent "Interlacing Scanline Bright %" 0.0 0.0 1.0 0.05
#pragma parameter enable_480i "Enable 480i Mode" 1.0 0.0 1.0 1.0
#pragma parameter top_field_first "Top Field First Enable" 0.0 0.0 1.0 1.0

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float input_gamma;
uniform COMPAT_PRECISION float percent;
uniform COMPAT_PRECISION float enable_480i;
uniform COMPAT_PRECISION float top_field_first;
#else
#define input_gamma 2.5
#define percent 0.0
#define enable_480i 1.0
#define top_field_first 0.0
#endif

void main()
{
   vec4 res = COMPAT_TEXTURE(Source, vTexCoord).rgba;
   float y = 0.0;
   float tick = vec2(FrameCount, 1.0).x;

   // assume anything with a vertical resolution greater than 400 lines is interlaced
   if (InputSize.y > 400.0)
   {y = SourceSize.y * vTexCoord.y + (tick * enable_480i) + top_field_first;}
   else
   {y = 2.0 * SourceSize.y * vTexCoord.y + top_field_first;}

   if (mod(y, 1.99999) > 0.99999)
   {res = res;}
   else
   {res = vec4(percent) * res;}
#if __VERSION__ < 130 // don't bother linearizing if srgb_framebuffers aren't guaranteed
   FragColor = res;
#else
   FragColor = pow(res, vec4(input_gamma));
#endif
} 
#endif
