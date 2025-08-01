#!/usr/bin/env python3
"""
Split dachshund limb images into separate front and back limb files.
Each image contains two limbs that need to be separated.
"""

from PIL import Image
import numpy as np
import os

def find_limb_bounds(img_array, alpha_channel):
    """Find the bounding boxes of non-transparent regions (limbs)."""
    # Find all non-transparent pixels
    non_transparent = alpha_channel > 0
    
    # Get coordinates of all non-transparent pixels
    coords = np.column_stack(np.where(non_transparent))
    
    if len(coords) == 0:
        return []
    
    # Simple clustering based on horizontal position
    # Sort by x-coordinate
    x_coords = coords[:, 1]
    sorted_indices = np.argsort(x_coords)
    sorted_coords = coords[sorted_indices]
    sorted_x = x_coords[sorted_indices]
    
    # Find gaps in x-coordinates to separate limbs
    gaps = []
    for i in range(1, len(sorted_x)):
        if sorted_x[i] - sorted_x[i-1] > 20:  # Gap threshold
            gaps.append(i)
    
    # Split coordinates into groups
    groups = []
    start = 0
    for gap in gaps:
        groups.append(sorted_coords[start:gap])
        start = gap
    groups.append(sorted_coords[start:])
    
    # Get bounding boxes for each group
    bboxes = []
    for group in groups:
        if len(group) > 0:
            min_y, min_x = group.min(axis=0)
            max_y, max_x = group.max(axis=0)
            bboxes.append((min_x, min_y, max_x + 1, max_y + 1))
    
    return bboxes

def extract_limb(img, bbox, preserve_position=True):
    """Extract a limb from the image, preserving original dimensions and position."""
    x1, y1, x2, y2 = bbox
    
    if preserve_position:
        # Create new image with same dimensions as original
        limb_img = Image.new('RGBA', img.size, (0, 0, 0, 0))
        # Copy the region to its original position
        region = img.crop((x1, y1, x2, y2))
        limb_img.paste(region, (x1, y1))
    else:
        # Original behavior - crop to bounding box
        limb_img = Image.new('RGBA', (x2 - x1, y2 - y1), (0, 0, 0, 0))
        region = img.crop((x1, y1, x2, y2))
        limb_img.paste(region, (0, 0))
    
    return limb_img

def split_limbs(input_path, output_prefix):
    """Split an image containing two limbs into separate files."""
    # Load image
    img = Image.open(input_path)
    img_array = np.array(img)
    
    # Get alpha channel
    if img_array.shape[2] == 4:
        alpha = img_array[:, :, 3]
    else:
        # If no alpha channel, assume non-white pixels are opaque
        alpha = np.where(np.all(img_array == 255, axis=2), 0, 255).astype(np.uint8)
    
    # Find limb bounding boxes
    bboxes = find_limb_bounds(img_array, alpha)
    
    if len(bboxes) < 2:
        print(f"Warning: Found {len(bboxes)} limbs in {input_path}, expected 2")
    
    # Sort bboxes by x-coordinate (left to right)
    bboxes.sort(key=lambda b: b[0])
    
    # Extract and save limbs
    limb_names = ['back', 'front']  # Left limb is back, right limb is front
    
    for i, (bbox, name) in enumerate(zip(bboxes[:2], limb_names)):
        limb_img = extract_limb(img, bbox)
        output_path = f"{output_prefix}-{name}.png"
        limb_img.save(output_path)
        print(f"Saved {output_path}")

def main():
    # Base directory for sprites
    base_dir = "test/assets/sprites/dachshund"
    
    # Split arms
    arms_path = os.path.join(base_dir, "arms.png")
    arms_output = os.path.join(base_dir, "arm")
    split_limbs(arms_path, arms_output)
    
    # Split legs
    legs_path = os.path.join(base_dir, "legs.png")
    legs_output = os.path.join(base_dir, "leg")
    split_limbs(legs_path, legs_output)

if __name__ == "__main__":
    main()