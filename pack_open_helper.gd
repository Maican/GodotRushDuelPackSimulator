extends Node

var packs : Dictionary[String, PackResource] = {}
var opening_pack_resource : PackResource
var opened_cards : Dictionary[String, Array] = {}
var packs_to_open : int = 0
const PACK_FOLDER : String = "res://PackResources/"

func _ready():
	load_packs()

func load_packs() -> void:
	var dir = DirAccess.open(PACK_FOLDER)
	if dir == null:
		push_error("Cannot open PackResources folder")
		return
	
	# First load all packs into a temporary array
	var pack_array : Array[PackResource] = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".res"):
			var pack_path = PACK_FOLDER + file_name
			var time_before : int = Time.get_ticks_msec()
			var pack_resource : PackResource = ResourceLoader.load(pack_path)
			var time_after : int = Time.get_ticks_msec()
			print("loading pack " + file_name + " took " + str(time_after - time_before) + "ms")
			
			if pack_resource != null and !pack_resource.pack_name.is_empty():
				pack_array.append(pack_resource)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort packs by release_date chronologically
	pack_array.sort_custom(func(a: PackResource, b: PackResource) -> bool:
		return a.release_date < b.release_date
	)
	
	# Add sorted packs to dictionary
	for pack_resource in pack_array:
		packs[pack_resource.pack_name] = pack_resource
	
	print("Loaded " + str(packs.size()) + " pack resources in chronological order")
