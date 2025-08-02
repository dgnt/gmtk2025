#!/usr/bin/env python3
from PIL import Image

# Load all sprite images
head = Image.open('test/assets/sprites/dachshund/head.png')
face = Image.open('test/assets/sprites/dachshund/face.png')
nose = Image.open('test/assets/sprites/dachshund/nose.png')
body = Image.open('test/assets/sprites/dachshund/body.png')
body_light = Image.open('test/assets/sprites/dachshund/body-light.png')
arm_front = Image.open('test/assets/sprites/dachshund/arm-front.png')
arm_back = Image.open('test/assets/sprites/dachshund/arm-back.png')
leg_front = Image.open('test/assets/sprites/dachshund/leg-front.png')
leg_back = Image.open('test/assets/sprites/dachshund/leg-back.png')
tail = Image.open('test/assets/sprites/dachshund/tail.png')
ear_front = Image.open('test/assets/sprites/dachshund/ear-front.png')
back_ear = Image.open('test/assets/sprites/dachshund/back-ear.png')

# Function to create a combined image from a list of sprites
def combine_sprites(sprites, base_size=None):
    if base_size is None:
        # Find the maximum dimensions
        max_width = max(sprite.width for sprite in sprites)
        max_height = max(sprite.height for sprite in sprites)
        base_size = (max_width, max_height)
    
    combined = Image.new('RGBA', base_size, (0, 0, 0, 0))
    
    for sprite in sprites:
        # Center each sprite
        x = (base_size[0] - sprite.width) // 2
        y = (base_size[1] - sprite.height) // 2
        combined.paste(sprite, (x, y), sprite)
    
    return combined

# Determine the overall canvas size for the fully combined sprite
all_sprites = [body, body_light, leg_back, leg_front, arm_back, arm_front, tail, head, back_ear, ear_front, face, nose]
max_width = max(sprite.width for sprite in all_sprites)
max_height = max(sprite.height for sprite in all_sprites)
canvas_size = (max_width, max_height)

# Create fully combined dachshund (all parts)
full_combined = combine_sprites([
    back_ear,      # Back ear behind head
    leg_back,      # Back leg behind body
    leg_front,     # Front leg behind body
    tail,          # Tail behind body
    head,          # Head
    body,          # Main body
    body_light,    # Body highlight/detail
    ear_front,     # Front ear
    face,          # Face
    nose,          # Nose on top
    arm_back,      # Back arm on top
    arm_front      # Front arm on top
], canvas_size)

# Create body+arms+tail combination
body_parts = combine_sprites([
    tail,          # Tail behind body
    body,          # Main body
    body_light,    # Body highlight/detail
    arm_back,      # Back arm behind body 
    arm_front      # Front arm in front of body
], canvas_size)

# Create head+face+nose+ears combination
head_parts = combine_sprites([
    back_ear,      # Back ear behind head
    head,          # Head
    ear_front,     # Front ear
    face,          # Face
    nose           # Nose on top
], canvas_size)

# Save all three versions
full_combined.save('test/assets/sprites/dachshund/dachshund_full_combined.png')
print("Fully combined dachshund sprite saved to test/assets/sprites/dachshund/dachshund_full_combined.png")

body_parts.save('test/assets/sprites/dachshund/dachshund_body_parts.png')
print("Body parts (body+arms+tail) saved to test/assets/sprites/dachshund/dachshund_body_parts.png")

head_parts.save('test/assets/sprites/dachshund/dachshund_head_parts.png')
print("Head parts (head+face+nose+ears) saved to test/assets/sprites/dachshund/dachshund_head_parts.png")