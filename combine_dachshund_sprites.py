#!/usr/bin/env python3
from PIL import Image

# Load the three sprite images
head = Image.open('test/assets/sprites/dachshund/head.png')
face = Image.open('test/assets/sprites/dachshund/face.png')
nose = Image.open('test/assets/sprites/dachshund/nose.png')

# Create a new image with the same size as the head (assuming it's the largest)
combined = Image.new('RGBA', head.size, (0, 0, 0, 0))

# Paste the head first (base layer)
combined.paste(head, (0, 0), head)

# Calculate center position for face
face_x = (head.width - face.width) // 2
face_y = (head.height - face.height) // 2
combined.paste(face, (face_x, face_y), face)

# Calculate center position for nose
nose_x = (head.width - nose.width) // 2
nose_y = (head.height - nose.height) // 2
combined.paste(nose, (nose_x, nose_y), nose)

# Save the combined image
combined.save('test/assets/sprites/dachshund/dachshund_combined.png')
print("Combined dachshund sprite saved to test/assets/sprites/dachshund/dachshund_combined.png")