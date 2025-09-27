# Storage Buffers Compute

Showcase of getting data into and out of GLSL compute shaders using Push Constants and Storage Buffers&hellip; in Godot.

Usage of **Specialization Constants** -- which are more efficient than Push Constants for input data that need not change during runtime -- is also included.

Helpful UI included to help understand the concepts.

For more info, see https://1hue.github.io/storage-buffers-compute-shaders-godot

![Screenshot](/assets/screenshot.png)

Scripts of interest:

- [`/src/compute_worker.gd`](src/compute_worker.gd)
- [`/src/compute_shader.glsl`](src/compute_shader.glsl)

## Compatibility

Tested with:

- Godot 4.5
- Godot 4.4
- Vulkan API

Compute shaders are not supported in WebGL/Compatibility mode.
