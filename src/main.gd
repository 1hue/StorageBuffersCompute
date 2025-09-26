# Copyright (c) 2025 1hue - MIT License
extends Control

@onready var input_fields: GridContainer = %InputFields
@onready var output_fields: GridContainer = %OutputFields
@onready var counter: LineEdit = %Counter
@onready var time: LineEdit = %Time

var worker: ComputeWorker

func _ready() -> void:
	worker = ComputeWorker.new()


func _on_compute_button_pressed() -> void:
	var inputs := get_inputs()
	worker.compute(inputs)
	worker.sync()

	time.text = "%.4f" % worker.benchmark
	counter.text = "%d" % worker.counter

	for i in output_fields.get_child_count():
		# Note that we're formatting floats into %d decimals
		output_fields.get_child(i).text = "%d" % worker.storage_out[i]


func get_inputs() -> PackedFloat32Array:
	var inputs = PackedFloat32Array()

	for child in input_fields.get_children():
		if child is LineEdit: # Type-hint
			inputs.append(float(child.text)) # Or we could .map() but this is more readable

	return inputs
