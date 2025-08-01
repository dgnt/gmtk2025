#!/usr/bin/env python3

import os
from PIL import Image
import numpy as np
from skimage import measure
import json

def detect_polygon_from_alpha(image_path, threshold=10):
    """Extract polygon from sprite alpha channel"""
    img = Image.open(image_path)
    
    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Get alpha channel
    alpha = np.array(img)[:,:,3]
    
    # Create binary mask
    mask = alpha > threshold
    
    # Find contours
    contours = measure.find_contours(mask, 0.5)
    
    if not contours:
        return []
    
    # Get the largest contour
    largest_contour = max(contours, key=lambda c: len(c))
    
    # Simplify contour
    simplified = measure.approximate_polygon(largest_contour, tolerance=2.0)
    
    # Convert to list of points
    points = [[float(x), float(y)] for y, x in simplified]
    
    return points

def get_bounds(points):
    """Calculate bounding box from points"""
    if not points:
        return None
    
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    
    return {
        'x': min(xs),
        'y': min(ys),
        'width': max(xs) - min(xs),
        'height': max(ys) - min(ys),
        'center': [(min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2]
    }

def process_sprites(sprite_dir):
    """Process all sprites in directory"""
    results = {}
    
    for filename in os.listdir(sprite_dir):
        if filename.endswith('.png'):
            path = os.path.join(sprite_dir, filename)
            print(f"\nProcessing: {filename}")
            
            try:
                polygon = detect_polygon_from_alpha(path)
                bounds = get_bounds(polygon)
                
                results[filename] = {
                    'polygon': polygon,
                    'bounds': bounds,
                    'point_count': len(polygon)
                }
                
                print(f"  Points: {len(polygon)}")
                if bounds:
                    print(f"  Size: {bounds['width']:.1f} x {bounds['height']:.1f}")
                    print(f"  Center: ({bounds['center'][0]:.1f}, {bounds['center'][1]:.1f})")
                
            except Exception as e:
                print(f"  Error: {e}")
    
    return results

if __name__ == "__main__":
    sprite_dir = "test/assets/sprites/dachshund"
    
    # Check if required libraries are installed
    try:
        import skimage
    except ImportError:
        print("Installing required libraries...")
        import subprocess
        subprocess.check_call(["pip", "install", "pillow", "scikit-image", "numpy"])
    
    results = process_sprites(sprite_dir)
    
    # Save results
    with open('sprite_polygons.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\nResults saved to sprite_polygons.json")