import raylib

from os import parentDir, `/`
const raylibasepriteHeader = currentSourcePath().parentDir()/"raylib-aseprite.h"
const cute_asepriteHeader = currentSourcePath().parentDir()/"cute_aseprite.h"
{.passC: "-DRAYLIB_ASEPRITE_IMPLEMENTATION -DCUTE_ASEPRITE_IMPLEMENTATION".}
##
## 	------------------------------------------------------------------------------
## 		Licensing information can be found at the end of the file.
## 	------------------------------------------------------------------------------
##
## 	cute_aseprite.h - v1.04
##
## 	To create implementation (the function definitions)
## 		#define CUTE_ASEPRITE_IMPLEMENTATION
## 	in *one* C/CPP file (translation unit) that includes this file
##
##
## 	SUMMARY
##
## 		cute_aseprite.h is a single-file header that implements some functions to
## 		parse .ase/.aseprite files. The entire file is parsed all at once and some
## 		structs are filled out then handed back to you.
##
##
## 	LIMITATIONS
##
## 		Only the "normal" blend mode for layers is supported. As a workaround try
## 		using the "merge down" function in Aseprite to create a normal layer.
## 		Supporting all blend modes would take too much code to be worth it.
##
## 		Does not support very old versions of Aseprite (with old palette chunks
## 		0x0004 or 0x0011). Also does not support deprecrated mask chunk.
##
## 		sRGB and ICC profiles are parsed but completely ignored when blending
## 		frames together. If you want these to be used when composing frames you
## 		have to do this yourself.
##
##
## 	SPECIAL THANKS
##
## 		Special thanks to Noel Berry for the blend code in his reference C++
## 		implementation (https://github.com/NoelFB/blah).
##
## 		Special thanks to Richard Mitton for the initial implementation of the
## 		zlib inflater.
##
##
## 	Revision history:
## 		1.00 (08/25/2020) initial release
## 		1.01 (08/31/2020) fixed memleaks, tag parsing bug (crash), blend bugs
## 		1.02 (02/05/2022) fixed icc profile parse bug, support transparent pal-
## 		                  ette index, can parse 1.3 files (no tileset support)
## 		1.03 (11/27/2023) fixed slice pivot parse bug
##   		1.04 (02/20/2024) chunck 0x0004 support
##
##
## 	DOCUMENTATION
##
## 		Simply load an .ase or .aseprite file from disk or from memory like so.
##
## 			ase_t* ase = cute_aseprite_load_from_file("data/player.aseprite", NULL);
##
##
## 		Then access the fields directly, assuming you have your own `Animation` type.
##
## 			int w = ase->w;
## 			int h = ase->h;
## 			Animation anim = { 0 }; // Your custom animation data type.
##
## 			for (int i = 0; i < ase->frame_count; ++i) {
## 				ase_frame_t* frame = ase->frames + i;
## 				anim.add_frame(frame->duration_milliseconds, frame->pixels);
## 			}
##
##
## 		Then free it up when done.
##
## 			cute_aseprite_free(ase);
##
##
## 	DATA STRUCTURES
##
## 		Aseprite files have frames, layers, and cels. A single frame is one frame of an
## 		animation, formed by blending all the cels of an animation together. There is
## 		one cel per layer per frame. Each cel contains its own pixel data.
##
## 		The frame's pixels are automatically assumed to have been blended by the `normal`
## 		blend mode. A warning is emit if any other blend mode is encountered. Feel free
## 		to update the pixels of each frame with your own implementation of blending
## 		functions. The frame's pixels are merely provided like this for convenience.
##
##
## 	BUGS AND CRASHES
##
## 		This header is quite new and it takes time to test all the parse paths. Don't be
## 		shy about opening a GitHub issue if there's a crash! It's quite easy to update
## 		the parser as long as you upload your .ase file that shows the bug.
##
## 		https://github.com/RandyGaul/cute_headers/issues
##

const
  CUTE_ASEPRITE_MAX_LAYERS* = 64
  CUTE_ASEPRITE_MAX_SLICES* = 128
  CUTE_ASEPRITE_MAX_PALETTE_ENTRIES* = 1024
  CUTE_ASEPRITE_MAX_TAGS* = 256

type
  uint8_t* = uint8
  uint16_t* = uint16
  uint32_t* = uint32

  ase_color_t* {.importc: "ase_color_t", header: cute_asepriteHeader, bycopy.} = object
    r*: uint8_t
    g*: uint8_t
    b*: uint8_t
    a*: uint8_t

  ase_fixed_t* {.importc: "ase_fixed_t", header: cute_asepriteHeader, bycopy.} = object
    a*: uint16_t
    b*: uint16_t

  ase_udata_t* {.importc: "ase_udata_t", header: cute_asepriteHeader, bycopy.} = object
    has_color*: cint
    color*: ase_color_t
    has_text*: cint
    text*: cstring

  ase_layer_flags_t* {.size: sizeof(cint).} = enum
    ASE_LAYER_FLAGS_VISIBLE = 0x01
    ASE_LAYER_FLAGS_EDITABLE = 0x02
    ASE_LAYER_FLAGS_LOCK_MOVEMENT = 0x04
    ASE_LAYER_FLAGS_BACKGROUND = 0x08
    ASE_LAYER_FLAGS_PREFER_LINKED_CELS = 0x10
    ASE_LAYER_FLAGS_COLLAPSED = 0x20
    ASE_LAYER_FLAGS_REFERENCE = 0x40

  ase_layer_type_t* {.size: sizeof(cint).} = enum
    ASE_LAYER_TYPE_NORMAL
    ASE_LAYER_TYPE_GROUP

  ase_layer_t* {.importc: "ase_layer_t", header: cute_asepriteHeader, bycopy.} = object
    flags*: ase_layer_flags_t
    `type`*: ase_layer_type_t
    name*: cstring
    parent*: ptr ase_layer_t
    opacity*: cfloat
    udata*: ase_udata_t

  ase_cel_extra_chunk_t* {.importc: "ase_cel_extra_chunk_t", header: cute_asepriteHeader, bycopy.} = object
    precise_bounds_are_set*: cint
    precise_x*: ase_fixed_t
    precise_y*: ase_fixed_t
    w*: ase_fixed_t
    h*: ase_fixed_t

  ase_cel_t* {.importc: "ase_cel_t", header: cute_asepriteHeader, bycopy.} = object
    layer*: ptr ase_layer_t
    pixels*: pointer
    w*: cint
    h*: cint
    x*: cint
    y*: cint
    opacity*: cfloat
    is_linked*: cint
    linked_frame_index*: uint16_t
    has_extra*: cint
    extra*: ase_cel_extra_chunk_t
    udata*: ase_udata_t

  ase_frame_t* {.importc: "ase_frame_t", header: cute_asepriteHeader, bycopy.} = object
    ase*: ptr ase_t
    duration_milliseconds*: cint
    pixels*: ptr ase_color_t
    cel_count*: cint
    cels*: array[CUTE_ASEPRITE_MAX_LAYERS, ase_cel_t]

  ase_animation_direction_t* {.size: sizeof(cint).} = enum
    ASE_ANIMATION_DIRECTION_FORWARDS
    ASE_ANIMATION_DIRECTION_BACKWORDS
    ASE_ANIMATION_DIRECTION_PINGPONG

  ase_tag_t* {.importc: "ase_tag_t", header: cute_asepriteHeader, bycopy.} = object
    from_frame*: cint
    to_frame*: cint
    loop_animation_direction*: ase_animation_direction_t
    repeat*: cint
    r*: uint8_t
    g*: uint8_t
    b*: uint8_t
    name*: cstring
    udata*: ase_udata_t

  ase_slice_t* {.importc: "ase_slice_t", header: cute_asepriteHeader, bycopy.} = object
    name*: cstring
    frame_number*: cint
    origin_x*: cint
    origin_y*: cint
    w*: cint
    h*: cint
    has_center_as_9_slice*: cint
    center_x*: cint
    center_y*: cint
    center_w*: cint
    center_h*: cint
    has_pivot*: cint
    pivot_x*: cint
    pivot_y*: cint
    udata*: ase_udata_t

  ase_palette_entry_t* {.importc: "ase_palette_entry_t", header: cute_asepriteHeader, bycopy.} = object
    color*: ase_color_t
    color_name*: cstring

  ase_palette_t* {.importc: "ase_palette_t", header: cute_asepriteHeader, bycopy.} = object
    entry_count*: cint
    entries*: array[CUTE_ASEPRITE_MAX_PALETTE_ENTRIES, ase_palette_entry_t]

  ase_color_profile_type_t* {.size: sizeof(cint).} = enum
    ASE_COLOR_PROFILE_TYPE_NONE
    ASE_COLOR_PROFILE_TYPE_SRGB
    ASE_COLOR_PROFILE_TYPE_EMBEDDED_ICC

  ase_color_profile_t* {.importc: "ase_color_profile_t", header: cute_asepriteHeader, bycopy.} = object
    `type`*: ase_color_profile_type_t
    use_fixed_gamma*: cint
    gamma*: ase_fixed_t
    icc_profile_data_length*: uint32_t
    icc_profile_data*: pointer

  ase_mode_t* {.size: sizeof(cint).} = enum
    ASE_MODE_RGBA
    ASE_MODE_GRAYSCALE
    ASE_MODE_INDEXED

  ase_t* {.importc: "ase_t", header: cute_asepriteHeader, bycopy.} = object
    mode*: ase_mode_t
    w*: cint
    h*: cint
    transparent_palette_entry_index*: cint
    number_of_colors*: cint
    pixel_w*: cint
    pixel_h*: cint
    grid_x*: cint
    grid_y*: cint
    grid_w*: cint
    grid_h*: cint
    has_color_profile*: cint
    color_profile*: ase_color_profile_t
    palette*: ase_palette_t
    layer_count*: cint
    layers*: array[CUTE_ASEPRITE_MAX_LAYERS, ase_layer_t]
    frame_count*: cint
    frames*: ptr ase_frame_t
    tag_count*: cint
    tags*: array[CUTE_ASEPRITE_MAX_TAGS, ase_tag_t]
    slice_count*: cint
    slices*: array[CUTE_ASEPRITE_MAX_SLICES, ase_slice_t]
    mem_ctx*: pointer


## ********************************************************************************************
##
##    raylib-aseprite - Aseprite sprite loader for raylib.
##
##    Copyright 2021 Rob Loach (@RobLoach)
##
##    DEPENDENCIES:
##        raylib 5.0+ https://www.raylib.com/
##
##    LICENSE: zlib/libpng
##
##    raylib-aseprite is licensed under an unmodified zlib/libpng license, which is an OSI-certified,
##    BSD-like license that allows static linking with closed source software:
##
##    This software is provided "as-is", without any express or implied warranty. In no event
##    will the authors be held liable for any damages arising from the use of this software.
##
##    Permission is granted to anyone to use this software for any purpose, including commercial
##    applications, and to alter it and redistribute it freely, subject to the following restrictions:
##
##      1. The origin of this software must not be misrepresented; you must not claim that you
##      wrote the original software. If you use this software in a product, an acknowledgment
##      in the product documentation would be appreciated but is not required.
##
##      2. Altered source versions must be plainly marked as such, and must not be misrepresented
##      as being the original software.
##
##      3. This notice may not be removed or altered from any source distribution.
##
## ********************************************************************************************

##
##  Aseprite object containing a pointer to the ase_t* from cute_aseprite.h.
##
##  @see LoadAseprite()
##  @see UnloadAseprite()
##

type
  Aseprite* {.importc: "Aseprite", header: raylibasepriteHeader, bycopy.} = object
    ase* {.importc: "ase".}: ptr ase_t
    ##  Pointer to the cute_aseprite data.


##
##  Tag information from an Aseprite object.
##
##  @see LoadAsepriteTag()
##  @see LoadAsepriteTagFromIndex()
##

type
  AsepriteTag* {.importc: "AsepriteTag", header: raylibasepriteHeader, bycopy.} = object
    name* {.importc: "name".}: cstring
    ##  The name of the tag.
    currentFrame* {.importc: "currentFrame".}: cint
    ##  The frame that the tag is currently on
    timer* {.importc: "timer".}: cfloat
    ##  The countdown timer in seconds
    direction* {.importc: "direction".}: cint
    ##  Whether we are moving forwards, or backwards through the frames
    speed* {.importc: "speed".}: cfloat
    ##  The animation speed factor (1 is normal speed, 2 is double speed)
    color* {.importc: "color".}: Color
    ##  The color provided for the tag
    loop* {.importc: "loop".}: bool
    ##  Whether to continue to play the animation when the animation finishes
    paused* {.importc: "paused".}: bool
    ##  Set to true to not progression of the animation
    aseprite* {.importc: "aseprite".}: Aseprite
    ##  The loaded Aseprite file
    tag* {.importc: "tag".}: ptr ase_tag_t
    ##  The active tag to act upon


##
##  Slice data for the Aseprite.
##
##  @see LoadAsepriteSlice()
##  @see https://www.aseprite.org/docs/slices/
##

type
  AsepriteSlice* {.importc: "AsepriteSlice", header: raylibasepriteHeader, bycopy.} = object
    name* {.importc: "name".}: cstring
    ##  The name of the slice.
    bounds* {.importc: "bounds".}: Rectangle
    ##  The rectangle outer bounds for the slice.


##  Aseprite functions

proc loadAseprite*(fileName: cstring): Aseprite {.cdecl, importc: "LoadAseprite",
    header: raylibasepriteHeader.}
##  Load an .aseprite file

proc loadAsepriteFromMemory*(fileData: ptr uint8; size: cint): Aseprite {.cdecl,
    importc: "LoadAsepriteFromMemory", header: raylibasepriteHeader.}
##  Load an aseprite file from memory

proc isAsepriteValid*(aseprite: Aseprite): bool {.cdecl, importc: "IsAsepriteValid",
    header: raylibasepriteHeader.}
##  Check if the given Aseprite was loaded successfully

proc unloadAseprite*(aseprite: Aseprite) {.cdecl, importc: "UnloadAseprite",
                                        header: raylibasepriteHeader.}
##  Unloads the aseprite file

proc traceAseprite*(aseprite: Aseprite) {.cdecl, importc: "TraceAseprite",
                                       header: raylibasepriteHeader.}
##  Display all information associated with the aseprite

proc getAsepriteTexture*(aseprite: Aseprite): Texture {.cdecl,
    importc: "GetAsepriteTexture", header: raylibasepriteHeader.}
##  Retrieve the raylib texture associated with the aseprite

proc getAsepriteWidth*(aseprite: Aseprite): cint {.cdecl,
    importc: "GetAsepriteWidth", header: raylibasepriteHeader.}
##  Get the width of the sprite

proc getAsepriteHeight*(aseprite: Aseprite): cint {.cdecl,
    importc: "GetAsepriteHeight", header: raylibasepriteHeader.}
##  Get the height of the sprite

proc drawAseprite*(aseprite: Aseprite; frame: cint; posX: cint; posY: cint; tint: Color) {.
    cdecl, importc: "DrawAseprite", header: raylibasepriteHeader.}
proc drawAsepriteFlipped*(aseprite: Aseprite; frame: cint; posX: cint; posY: cint;
                         horizontalFlip: bool; verticalFlip: bool; tint: Color) {.
    cdecl, importc: "DrawAsepriteFlipped", header: raylibasepriteHeader.}
proc drawAsepriteV*(aseprite: Aseprite; frame: cint; position: Vector2; tint: Color) {.
    cdecl, importc: "DrawAsepriteV", header: raylibasepriteHeader.}
proc drawAsepriteVFlipped*(aseprite: Aseprite; frame: cint; position: Vector2;
                          horizontalFlip: bool; verticalFlip: bool; tint: Color) {.
    cdecl, importc: "DrawAsepriteVFlipped", header: raylibasepriteHeader.}
proc drawAsepriteExFlipped*(aseprite: Aseprite; frame: cint; position: Vector2;
                           rotation: cfloat; scale: cfloat; horizontalFlip: bool;
                           verticalFlip: bool; tint: Color) {.cdecl,
    importc: "DrawAsepriteExFlipped", header: raylibasepriteHeader.}
proc drawAsepritePro*(aseprite: Aseprite; frame: cint; dest: Rectangle;
                     origin: Vector2; rotation: cfloat; tint: Color) {.cdecl,
    importc: "DrawAsepritePro", header: raylibasepriteHeader.}
proc drawAsepriteProFlipped*(aseprite: Aseprite; frame: cint; dest: Rectangle;
                            origin: Vector2; rotation: cfloat; horizontalFlip: bool;
                            verticalFlip: bool; tint: Color) {.cdecl,
    importc: "DrawAsepriteProFlipped", header: raylibasepriteHeader.}
##  Aseprite Tag functions

proc loadAsepriteTag*(aseprite: Aseprite; name: cstring): AsepriteTag {.cdecl,
    importc: "LoadAsepriteTag", header: raylibasepriteHeader.}
##  Load an Aseprite tag animation sequence

proc loadAsepriteTagFromIndex*(aseprite: Aseprite; index: cint): AsepriteTag {.cdecl,
    importc: "LoadAsepriteTagFromIndex", header: raylibasepriteHeader.}
##  Load an Aseprite tag animation sequence from its index

proc getAsepriteTagCount*(aseprite: Aseprite): cint {.cdecl,
    importc: "GetAsepriteTagCount", header: raylibasepriteHeader.}
##  Get the total amount of available tags

proc isAsepriteTagValid*(tag: AsepriteTag): bool {.cdecl,
    importc: "IsAsepriteTagValid", header: raylibasepriteHeader.}
##  Check if the given Aseprite tag was loaded successfully

proc updateAsepriteTag*(tag: ptr AsepriteTag) {.cdecl, importc: "UpdateAsepriteTag",
    header: raylibasepriteHeader.}
##  Update the tag animation frame

proc genAsepriteTagDefault*(): AsepriteTag {.cdecl,
    importc: "GenAsepriteTagDefault", header: raylibasepriteHeader.}
##  Generate an empty Tag with sane defaults

proc drawAsepriteTag*(tag: AsepriteTag; posX: cint; posY: cint; tint: Color) {.cdecl,
    importc: "DrawAsepriteTag", header: raylibasepriteHeader.}
proc drawAsepriteTagFlipped*(tag: AsepriteTag; posX: cint; posY: cint;
                            horizontalFlip: bool; verticalFlip: bool; tint: Color) {.
    cdecl, importc: "DrawAsepriteTagFlipped", header: raylibasepriteHeader.}
proc drawAsepriteTagV*(tag: AsepriteTag; position: Vector2; tint: Color) {.cdecl,
    importc: "DrawAsepriteTagV", header: raylibasepriteHeader.}
proc drawAsepriteTagVFlipped*(tag: AsepriteTag; position: Vector2;
                             horizontalFlip: bool; verticalFlip: bool; tint: Color) {.
    cdecl, importc: "DrawAsepriteTagVFlipped", header: raylibasepriteHeader.}
proc drawAsepriteTagEx*(tag: AsepriteTag; position: Vector2; rotation: cfloat;
                       scale: cfloat; tint: Color) {.cdecl,
    importc: "DrawAsepriteTagEx", header: raylibasepriteHeader.}
proc drawAsepriteTagExFlipped*(tag: AsepriteTag; position: Vector2; rotation: cfloat;
                              scale: cfloat; horizontalFlip: bool;
                              verticalFlip: bool; tint: Color) {.cdecl,
    importc: "DrawAsepriteTagExFlipped", header: raylibasepriteHeader.}
proc drawAsepriteTagPro*(tag: AsepriteTag; dest: Rectangle; origin: Vector2;
                        rotation: cfloat; tint: Color) {.cdecl,
    importc: "DrawAsepriteTagPro", header: raylibasepriteHeader.}
proc drawAsepriteTagProFlipped*(tag: AsepriteTag; dest: Rectangle; origin: Vector2;
                               rotation: cfloat; horizontalFlip: bool;
                               verticalFlip: bool; tint: Color) {.cdecl,
    importc: "DrawAsepriteTagProFlipped", header: raylibasepriteHeader.}
proc setAsepriteTagFrame*(tag: ptr AsepriteTag; frameNumber: cint) {.cdecl,
    importc: "SetAsepriteTagFrame", header: raylibasepriteHeader.}
##  Sets which frame the tag is currently displaying.

proc getAsepriteTagFrame*(tag: AsepriteTag): cint {.cdecl,
    importc: "GetAsepriteTagFrame", header: raylibasepriteHeader.}
##  Aseprite Slice functions

proc loadAsepriteSlice*(aseprite: Aseprite; name: cstring): AsepriteSlice {.cdecl,
    importc: "LoadAsepriteSlice", header: raylibasepriteHeader.}
##  Load a slice from an Aseprite based on its name.

proc loadAsperiteSliceFromIndex*(aseprite: Aseprite; index: cint): AsepriteSlice {.
    cdecl, importc: "LoadAsperiteSliceFromIndex", header: raylibasepriteHeader.}
##  Load a slice from an Aseprite based on its index.

proc getAsepriteSliceCount*(aseprite: Aseprite): cint {.cdecl,
    importc: "GetAsepriteSliceCount", header: raylibasepriteHeader.}
##  Get the amount of slices that are defined in the Aseprite.

proc isAsepriteSliceValid*(slice: AsepriteSlice): bool {.cdecl,
    importc: "IsAsepriteSliceValid", header: raylibasepriteHeader.}
##  Return whether or not the given slice was found.

proc genAsepriteSliceDefault*(): AsepriteSlice {.cdecl,
    importc: "GenAsepriteSliceDefault", header: raylibasepriteHeader.}
##  Generate empty Aseprite slice data.
