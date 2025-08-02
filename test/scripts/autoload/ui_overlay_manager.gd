# ui_overlay_manager.gd
# Add this as an AutoLoad singleton in Project Settings
extends Node

var overlay_canvas: CanvasLayer
var fullscreen_button: Button
var ui_container: Control

func _ready():
	# Wait a frame to ensure the scene tree is ready
	await get_tree().process_frame
	create_overlay_ui()

func create_overlay_ui():
	# Create CanvasLayer for overlay UI - this stays on top of everything
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 100  # High layer value to stay on top
	overlay_canvas.name = "UIOverlay"
	
	# Create a Control container for organizing UI elements
	ui_container = Control.new()
	ui_container.name = "UIContainer"
	ui_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through empty areas
	
	# Create fullscreen button
	create_fullscreen_button()
	
	# Build the hierarchy
	overlay_canvas.add_child(ui_container)
	ui_container.add_child(fullscreen_button)
	
	# Add to scene tree
	get_tree().root.add_child(overlay_canvas)
	
	print("UIOverlay: Overlay UI created successfully")

func create_fullscreen_button():
	fullscreen_button = Button.new()
	fullscreen_button.name = "FullscreenButton"
	
	# Set button properties
	fullscreen_button.text = "⛶"  # Fullscreen symbol
	fullscreen_button.custom_minimum_size = Vector2(40, 40)
	
	# Make button click-only (not keyboard navigable)
	fullscreen_button.focus_mode = Control.FOCUS_NONE
	
	# Position in top-right corner with some padding
	fullscreen_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fullscreen_button.position.x -= 50  # 10px padding from right edge
	fullscreen_button.position.y += 10   # 10px padding from top edge
	
	# Style the button for HTML5 visibility
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Semi-transparent dark
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color.WHITE
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color.YELLOW
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	
	fullscreen_button.add_theme_stylebox_override("normal", style_normal)
	fullscreen_button.add_theme_stylebox_override("hover", style_hover)
	fullscreen_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect signal
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Only exit fullscreen if currently in fullscreen mode
			if OS.get_name() == "Web":
				# Check if in fullscreen for HTML5
				var js_check = """
				document.fullscreenElement !== null
				"""
				var is_fullscreen = JavaScriptBridge.eval(js_check)
				if is_fullscreen:
					JavaScriptBridge.eval("document.exitFullscreen();")
			else:
				# Check if in fullscreen for desktop
				if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_fullscreen_pressed():
	print("UIOverlay: Fullscreen button pressed")
	
	# HTML5 fullscreen handling
	if OS.get_name() == "Web":
		# For HTML5, we need to use JavaScript
		var js_code = """
		if (document.fullscreenElement) {
			document.exitFullscreen();
		} else {
			document.documentElement.requestFullscreen();
		}
		"""
		JavaScriptBridge.eval(js_code)
	else:
		# For desktop builds
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Method to show/hide overlay (useful for cutscenes, menus, etc.)
func set_overlay_visible(visible: bool):
	if overlay_canvas:
		overlay_canvas.visible = visible

# Method to add additional overlay elements
func add_overlay_element(element: Control):
	if ui_container:
		ui_container.add_child(element)

# Method to remove overlay elements
func remove_overlay_element(element: Control):
	if ui_container and element.get_parent() == ui_container:
		ui_container.remove_child(element)
