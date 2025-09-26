extends RefCounted
class_name ComputeWorker

const SHADER_PATH = "res://compute_shader.glsl"
const INPUT_COUNT = 8
const SSBO_SIZE = 1 + INPUT_COUNT # Number of floats for our input/output. 1 counter + 8 inputs

var rd: RenderingDevice
var shader: RID
## Keep track of the .glsl version that was compiled - merely a helper for development
var shader_hash: String
var pipeline: RID
var storage_buffer: RID

# Outputs
var counter: int
var storage_out: PackedFloat32Array
var benchmark: float

func _init() -> void:
	rd = RenderingServer.create_local_rendering_device()

	compile()

	var storage_init := PackedByteArray()
	# Each 32-bit float is 4 bytes
	storage_init.resize(SSBO_SIZE * 4)
	storage_buffer = rd.storage_buffer_create(storage_init.size(), storage_init)


## Destructor
func _notification(what) -> void:
	if what == NOTIFICATION_PREDELETE:
		print_rich('[color=dim_gray]Worker goodbye![/color]')

		if not rd:
			return

		if storage_buffer.is_valid():
			rd.free_rid(storage_buffer)

		if shader.is_valid():
			rd.free_rid(shader)

		# Free if local RD only
		rd.free()


func compile() -> void:
	shader = compile_shader(rd, SHADER_PATH)
	shader_hash = FileAccess.get_md5(SHADER_PATH)
	pipeline = rd.compute_pipeline_create(shader)


## Rudimentary check for .glsl has been modified, since we're keeping a single ComputeWorker instance
func should_recompile() -> bool:
	var hash_current := FileAccess.get_md5(SHADER_PATH)
	return shader_hash and shader_hash != hash_current



## Import, compile and load shader
func compile_shader(p_rd: RenderingDevice, p_shader_path: String) -> RID:
	var shader_file: RDShaderFile = load(p_shader_path)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()

	var err = shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
	if err: push_warning(err)

	return p_rd.shader_create_from_spirv(shader_spirv, p_shader_path.get_file())


func create_uniform(rids: Array[RID], type: RenderingDevice.UniformType, binding: int = 0) -> RDUniform:
	var uniform: RDUniform = RDUniform.new()
	uniform.uniform_type = type
	uniform.binding = binding
	for rid in rids:
		uniform.add_id(rid)
	return uniform


func compute(push_constant: PackedFloat32Array) -> void:
	if should_recompile():
		compile()

	assert(push_constant.size() == INPUT_COUNT,
		"Push constant passed in must be strictly a predetermined length of %d" % INPUT_COUNT)

	# Uniform set: storage buffer
	var uniform: RDUniform = create_uniform([storage_buffer], RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER)
	#var storage_buffer_set := UniformSetCacheRD.get_cache(shader, 1, [uniform])
	var storage_buffer_set: RID = rd.uniform_set_create([uniform], shader, 0)

	rd.capture_timestamp("bench_start")
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, storage_buffer_set, 0)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, 1, 1, 1)
	rd.compute_list_end()
	rd.capture_timestamp("bench_end")
	rd.submit()


func _get_benchmark() -> float:
	var start := rd.get_captured_timestamp_gpu_time(0)
	var end := rd.get_captured_timestamp_gpu_time(1)
	var gpu_ms := (end - start) * 1e-6
	return gpu_ms


func sync() -> void:
	rd.sync()

	# Important this is after sync but before buffer_get_data
	benchmark = _get_benchmark()
	print(benchmark)

	var bytes_out := rd.buffer_get_data(storage_buffer)
	counter = bytes_out.decode_u32(0)
	storage_out = bytes_out.slice(4).to_float32_array()
