#[compute]
#version 460

layout(local_size_x = 4, local_size_y = 4) in;
layout(set = 0, binding = 0, std430) buffer DataStorageBuffer {
  // Order here is very important for the right byte offsets outside of the shader
  uint counter;
  float storage_data[];
};
layout(push_constant, std430) uniform PushParams {
  float push_data[8];
};

shared vec3 s[gl_WorkGroupSize.x * gl_WorkGroupSize.y];

void main() {
  uint idx = gl_LocalInvocationID.x + gl_LocalInvocationID.y * gl_WorkGroupSize.x;
  uint prev = atomicAdd(counter, 1u);

  // Each invocation is uniquely identified by idx and only touches that particular array index
  storage_data[idx] = push_data[idx];

  // With our persistent storage buffer, the data doesn't disappear, so we could keep adding:
  //storage_data[idx] += push_data[idx];
}
