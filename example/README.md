# prism_ui gallery

Interactive gallery for the prism_ui fork: one page per component area, with a
shell that switches theme, seed color, contrast and text scale.

## Run

```sh
cd example
flutter run -d linux
```

On an NVIDIA host with Flutter 3.50, prefix the command to render through Mesa
zink:

```sh
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json \
MESA_LOADER_DRIVER_OVERRIDE=zink flutter run -d linux
```

## Screenshots

```sh
cd example
ftest test/screenshots_test.dart   # or: flutter test test/screenshots_test.dart
```

PNGs land in `example/screenshots/` (Roboto from `/usr/share/fonts/TTF` is
used when present):

- `<page>_<theme>.png`: the whole page at 1280 px wide, as tall as its content.
- `<page>_<state>_<theme>.png`: after tapping the demo triggers (sheets opened,
  cards selected, motion demos part-way).
