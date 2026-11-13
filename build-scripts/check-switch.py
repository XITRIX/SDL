#!/usr/bin/env python3
"""Compile the homebrew platform sources against libnx and libounce headers.

Run after configuring SDL for a native Switch build. This checks SDK/API and
EGL/Vulkan conditional compilation; it does not link or execute console code.
"""
import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--devkitpro', type=Path, required=True)
    parser.add_argument('--config', type=Path, required=True,
                        help='Configured include-config-release/build_config directory')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    assert (args.config / 'SDL_build_config.h').is_file()
    compiler = args.devkitpro / 'devkitA64/bin/aarch64-none-elf-gcc'
    common = [str(compiler), '-fsyntax-only', '-std=gnu11', '-D__SWITCH__',
              '-DUSING_GENERATED_CONFIG_H', '-DSDL_STATIC_LIB',
              '-Werror=implicit-function-declaration', '-Werror=incompatible-pointer-types',
              '-I' + str(args.config), '-I' + str(root / 'include'),
              '-I' + str(root / 'src'), '-idirafter', str(root / 'src/video/khronos')]
    count = 0
    for generation, sdk in ((1, 'libnx'), (2, 'libounce')):
        flags = common + ['-isystem', str(args.devkitpro / sdk / 'include')]
        if generation == 2:
            flags += ['-D__SWITCH2__']
        sources = sorted(root.glob('src/*/switch/*.c'))
        for mode, defines in (
            ('native', []),
            ('EGL', ['-DSDL_VIDEO_OPENGL_EGL=1', '-DSDL_VIDEO_OPENGL_ES2=1']),
            ('Vulkan', ['-DSDL_VIDEO_VULKAN=1']),
        ):
            selected = sources if mode == 'native' else sorted(root.glob('src/video/switch/*.c'))
            for source in selected:
                subprocess.run(flags + defines + [str(source)], check=True)
                count += 1
            print(f'Switch {generation} {mode}: {len(selected)} platform sources passed', flush=True)
    print(f'{count} platform compilation checks passed; console runtime testing is separate')


if __name__ == '__main__':
    main()
