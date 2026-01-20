extends TextureRect
class_name SigilIcon

var sigil_id: String = ""
var description: String = ""

func setup(data: Dictionary) -> void:
	sigil_id = data.get("id", "")
	var icon_path = data.get("icon", "")
	
	if icon_path != "":
		texture = load(icon_path)
	else:
		# Fallback to ArtRegistry if path missing in JSON
		texture = ArtRegistry.get_texture(sigil_id)
		
	var name_text = data.get("name", "Unknown Sigil")
	description = data.get("text", "")
	
	tooltip_text = "%s\n%s" % [name_text, description]
	
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
