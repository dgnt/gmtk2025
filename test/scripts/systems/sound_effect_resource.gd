extends Resource
class_name SoundEffectResource

# Resource class for sound effects with configurable properties

@export var audio_stream: AudioStream
@export var base_volume_db: float = 0.0
@export var pitch_variation: float = 0.1
@export var bus_name: String = "SFX"
@export var looping: bool = false

func play() -> int:
	"""Play this sound effect through the AudioManager."""
	if not audio_stream:
		push_error("SoundEffectResource has no audio stream assigned!")
		return -1
	
	return AudioManager.play_sfx(
		audio_stream.resource_path,
		pitch_variation,
		base_volume_db
	)