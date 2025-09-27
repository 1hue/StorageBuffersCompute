// Copyright (c) 2025 1hue - MIT License
#[compute]
#version 460

layout(constant_id = 0) const float CONSTANT_0 = 0.0;
layout(constant_id = 1) const float CONSTANT_1 = 0.0;
layout(local_size_x = 4, local_size_y = 2) in;
layout(set = 0, binding = 0, std430) buffer DataStorageBuffer {
  // Order here is very important for the right byte offsets outside of the shader
  uint counter;
  // Layout rules dictate that this must be a group of 16 bytes (=4 floats), but we can omit/comment out the following line as it can be inferred
  // float padding;
  vec2 constants;

  float storage_data[];
};
layout(push_constant, std430) uniform PushParams {
  float push_data[8];
};

void main() {
  uint idx = gl_LocalInvocationIndex;
  uint prev = atomicAdd(counter, 1u);

  // Each invocation is uniquely identified by idx and only touches that particular array index
  storage_data[idx] = push_data[idx];

  // With our persistent storage buffer, the data doesn't disappear until we destroy the buffer ourselves,
  // so we could keep adding:
  //storage_data[idx] += push_data[idx];

  // Don't need to run this 8 times, only run it on invocation 0
  if (idx == 0) {
    constants = vec2(CONSTANT_0, CONSTANT_1);
  }
}
