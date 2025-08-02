extends Node

# Audio manager singleton for managing all game audio
# Handles music, sound effects, and audio buses

signal music_started(track_name: String)
signal music_stopped()
signal sfx_played(sound_name: String)

# Audio buses
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

# Audio pools
var sfx_pool: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var active_sounds: Dictionary = {} # track_id -> AudioStreamPlayer

# Pool settings
const SFX_POOL_SIZE = 10
const DEFAULT_PITCH_VARIATION = 0.1

func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Create SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sfx_pool.append(player)

func play_sfx(sound_path: String, pitch_variation: float = DEFAULT_PITCH_VARIATION, volume_db: float = 0.0) -> int:
	"""Play a sound effect with optional pitch variation. Returns a track ID for looping sounds."""
	var stream = load(sound_path) as AudioStream
	if not stream:
		push_error("Failed to load audio stream: " + sound_path)
		return -1
	
	# Find available player from pool
	var player = _get_available_sfx_player()
	if not player:
		push_warning("All SFX players are busy!")
		return -1
	
	# Apply settings
	player.stream = stream
	player.volume_db = volume_db
	
	# Apply pitch variation
	if pitch_variation > 0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()
	
	# Generate track ID for tracking
	var track_id = hash(sound_path + str(Time.get_ticks_msec()))
	active_sounds[track_id] = player
	
	# Clean up tracking when sound finishes (for non-looping sounds)
	if not stream.loop:
		# Disconnect any existing connections first to avoid duplicate connections
		if player.finished.is_connected(_on_sfx_finished):
			player.finished.disconnect(_on_sfx_finished)
		player.finished.connect(_on_sfx_finished.bind(track_id), CONNECT_ONE_SHOT)
	
	sfx_played.emit(sound_path)
	return track_id

func stop_sfx(track_id: int) -> void:
	"""Stop a specific sound effect by its track ID."""
	if track_id in active_sounds:
		var player = active_sounds[track_id]
		player.stop()
		player.stream = null
		active_sounds.erase(track_id)

func play_music(music_path: String, volume_db: float = 0.0, fade_in: float = 0.0) -> void:
	"""Play background music with optional fade in."""
	var stream = load(music_path) as AudioStream
	if not stream:
		push_error("Failed to load music stream: " + music_path)
		return
	
	music_player.stream = stream
	music_player.volume_db = volume_db
	
	if fade_in > 0:
		# Start quiet and tween to target volume
		music_player.volume_db = -80.0
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", volume_db, fade_in)
	else:
		music_player.play()
	
	music_started.emit(music_path)

func stop_music(fade_out: float = 0.0) -> void:
	"""Stop the current music with optional fade out."""
	if not music_player.playing:
		return
	
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(music_player.stop)
		tween.tween_callback(func(): music_stopped.emit())
	else:
		music_player.stop()
		music_stopped.emit()

func set_bus_volume(bus_name: String, volume_db: float) -> void:
	"""Set the volume of a specific audio bus."""
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_bus_mute(bus_name: String, mute: bool) -> void:
	"""Mute or unmute a specific audio bus."""
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, mute)

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available player from the SFX pool."""
	for player in sfx_pool:
		if not player.playing:
			return player
	return null

func _on_sfx_finished(track_id: int) -> void:
	"""Clean up finished sound effects."""
	if track_id in active_sounds:
		active_sounds[track_id].stream = null
		active_sounds.erase(track_id)

# Convenience functions for common sounds
func play_helicopter_sound() -> int:
	"""Play the helicopter sound with pitch variation."""
	return play_sfx("res://assets/audio/sfx/HelicopterNoise.ogg", 0.1, 0.0)

func stop_helicopter_sound(track_id: int) -> void:
	"""Stop the helicopter sound."""
	stop_sfx(track_id)

func play_jump_sound() -> int:
	"""Play the jump sound with pitch variation."""
	return play_sfx("res://assets/audio/sfx/JumpNoise.ogg", 0.15, -3.0)
