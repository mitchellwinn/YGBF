shader_type canvas_item;

// Uniform to control the oscillation speed
uniform float oscillation_speed = 1.0;
// Uniform to toggle the flashing effect
uniform bool flash_enabled = true;

void fragment() {
    // Sample the texture to get the normal color
    vec4 normal_color = texture(TEXTURE, UV);

    if (flash_enabled) {
        // Calculate the oscillation factor using sine function and time
        float oscillation = abs(sin(TIME * oscillation_speed));
        // Set the color, blending between normal color and white based on the oscillation factor
        COLOR = mix(normal_color, vec4(1.0, 1.0, 1.0, normal_color.a), oscillation);
    } else {
        // When flashing is disabled, just use the normal color
        COLOR = normal_color;
    }
}
