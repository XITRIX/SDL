/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2017 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#include "SDL_internal.h"

#if SDL_VIDEO_DRIVER_SWITCH

#include <switch.h>

#include "../../events/SDL_touch_c.h"
#include "../../video/SDL_sysvideo.h"

static HidTouchScreenState touchState;
static HidTouchScreenState touchStateOld;
static SDL_TouchID touch_id = 1;

static s32 SWITCH_FindFingerIndex(const HidTouchScreenState *state, u32 finger_id)
{
    s32 i;

    for (i = 0; i < state->count; ++i) {
        if (state->touches[i].finger_id == finger_id) {
            return i;
        }
    }

    return -1;
}

void SWITCH_InitTouch(void)
{
    hidInitializeTouchScreen();
    SDL_AddTouch(touch_id, SDL_TOUCH_DEVICE_DIRECT, "Switch");
    SDL_SetHintWithPriority(SDL_HINT_TOUCH_MOUSE_EVENTS, "0", SDL_HINT_DEFAULT);
    SDL_memset(&touchState, 0, sizeof(HidTouchScreenState));
    SDL_memset(&touchStateOld, 0, sizeof(HidTouchScreenState));
}

void SWITCH_QuitTouch(void)
{
    SDL_DelTouch(touch_id);
}

void SWITCH_PollTouch(Uint64 timestamp)
{
    const float rel_w = 1280.0f, rel_h = 720.0f;
    SDL_Window *window = SDL_GetKeyboardFocus();
    SDL_TouchID id = touch_id;
    s32 i;

    if (!window) {
        return;
    }

    SDL_memcpy(&touchStateOld, &touchState, sizeof(touchState));

    if (hidGetTouchScreenStates(&touchState, 1)) {
        /* Finger down */
        for (i = 0; i < touchState.count; i++) {
            if (SWITCH_FindFingerIndex(&touchStateOld, touchState.touches[i].finger_id) < 0) {
                SDL_SendTouch(timestamp, id,
                              (SDL_FingerID)touchState.touches[i].finger_id + 1,
                              window, SDL_EVENT_FINGER_DOWN,
                              (float)touchState.touches[i].x / rel_w,
                              (float)touchState.touches[i].y / rel_h, 1);
            }
        }

        /* Scan for moves or up */
        for (i = 0; i < touchStateOld.count; i++) {
            s32 current_index = SWITCH_FindFingerIndex(&touchState, touchStateOld.touches[i].finger_id);

            if (current_index >= 0) {
                /* Finger moved */
                if (touchState.touches[current_index].x != touchStateOld.touches[i].x ||
                    touchState.touches[current_index].y != touchStateOld.touches[i].y) {
                    SDL_SendTouchMotion(timestamp, id,
                                        (SDL_FingerID)touchState.touches[current_index].finger_id + 1,
                                        window,
                                        (float)touchState.touches[current_index].x / rel_w,
                                        (float)touchState.touches[current_index].y / rel_h, 1);
                }
            } else {
                /* Finger Up */
                SDL_SendTouch(timestamp, id,
                              (SDL_FingerID)touchStateOld.touches[i].finger_id + 1,
                              window,
                              SDL_EVENT_FINGER_UP,
                              (float)touchStateOld.touches[i].x / rel_w,
                              (float)touchStateOld.touches[i].y / rel_h, 1);
            }
        }
    }
}

#endif /* SDL_VIDEO_DRIVER_SWITCH */

/* vi: set ts=4 sw=4 expandtab: */
