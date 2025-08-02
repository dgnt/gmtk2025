shader_type canvas_item;

// Shader parameters
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.01;
uniform float animation_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
uniform float secondary_frequency : hint_range(1.0, 30.0) = 15.0;
uniform float edge_fade_size : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// Noise generation function for organic movement
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec2 screen_uv = SCREEN_UV;

    // Use UV coordinates to determine distance from edges
    // UV goes from 0 to 1 across the ColorRect
    float dist_to_left = UV.x;
    float dist_to_right = 1.0 - UV.x;
    float min_dist = min(dist_to_left, dist_to_right);

    // Edge fade effect - stronger near the edges (left and right)
    float edge_influence = 1.0 - smoothstep(0.0, edge_fade_size, min_dist);

    // Time-based animation
    float time = TIME * animation_speed;

    // Use screen position for wave calculations
    vec2 screen_pos = FRAGCOORD.xy;

    // Create multiple layers of distortion for more organic movement
    // Primary wave - larger, slower movement
    vec2 primary_offset = vec2(
        sin(screen_pos.y * wave_frequency * 0.001 + time) * 0.5,
        cos(screen_pos.x * wave_frequency * 0.001 + time * 0.7) * 0.5
    );

    // Secondary wave - smaller, faster ripples
    vec2 secondary_offset = vec2(
        sin(screen_pos.y * secondary_frequency * 0.001 + time * 2.3) * 0.3,
        cos(screen_pos.x * secondary_frequency * 0.001 + time * 1.7) * 0.3
    );

    // Add some noise for more organic feel
    vec2 noise_offset = vec2(
        noise(screen_pos * 0.003 + vec2(time * 0.5, 0.0)) - 0.5,
        noise(screen_pos * 0.003 + vec2(0.0, time * 0.5)) - 0.5
    ) * 0.2;

    // Combine all distortions
    vec2 total_offset = (primary_offset + secondary_offset + noise_offset) * distortion_strength * edge_influence;

    // Apply directional bias - distortion flows outward from edges
    vec2 edge_direction;
    if (dist_to_left < dist_to_right) {
        edge_direction = vec2(-1.0, 0.0); // Flow left from left edge
    } else {
        edge_direction = vec2(1.0, 0.0);  // Flow right from right edge
    }
    total_offset *= 0.7 + 0.3 * abs(dot(normalize(total_offset), edge_direction));

    // Sample the screen with distortion
    vec4 screen_color = texture(screen_texture, screen_uv + total_offset);

    // Apply subtle color shift for heat-like effect (very subtle)
    vec3 final_color = screen_color.rgb;
    final_color.r += edge_influence * 0.01;
    final_color.b -= edge_influence * 0.01;

    // Make the ColorRect itself transparent, only show the distorted background
    COLOR = vec4(final_color, edge_influence * 0.5);
}