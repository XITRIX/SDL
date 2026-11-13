# Nintendo Switch

## XITRIX homebrew fork

This fork also contains the devkitPro homebrew port for Switch 1 (libnx) and
Switch 2 (libounce), based on upstream SDL 3.4.20. This is separate from the
commercial port described below. The existing VisionOS changes are retained.

Use devkitPro's `cmake/Switch.cmake` for Switch 1, or
`libounce/cmake/Switch2.cmake` for Switch 2. The Switch 1 handheld/docked modes
remain 1280x720 and 1920x1080. Switch 2 follows the native window dimensions,
including the TV resolution, and exposes the handheld 1080p/120 mode.

For applications presenting directly through a native API, set the
`SDL_SWITCH_NATIVE_WINDOW` hint to `1` before creating the window. The driver
then leaves the window's buffer queue to the application. EGL is optional: use
`SDL_OPENGL=OFF`, `SDL_OPENGLES=OFF` and `SDL_OPENGL_EGL=OFF` for a build without
GL dependencies. Existing Switch 1 EGL/GLES applications retain their normal
surface path. Vulkan is opt-in with `SDL_VULKAN=ON`; Switch 1 links Mesa NVK
(`vulkan_nouveau`) and Switch 2 links OunceVK (`vulkan`).

Both generations retain the fork's controller, touch, keyboard, software
keyboard, audio, lifecycle, rumble, motion and filesystem support.

After configuring a native build, check the platform sources against both SDKs:

```sh
python3 build-scripts/check-switch.py --devkitpro "$DEVKITPRO" \
    --config build/include-config-release/build_config
```

This checks native, EGL and Vulkan conditional compilation. It does not replace
console runtime testing.

## Commercial port

SDL3 runs on the Nintendo Switch! Both Switch and Switch 2 are supported. There are commercial games shipping with this port. This port is kept in a separate repository, but is available for free, under the zlib license, to anyone that is under the appropriate NDAs with Nintendo. Please contact Ryan (icculus at icculus dot org) for details.
