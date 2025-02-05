shader_type canvas_item;

uniform sampler2D palette_texture; // Palette texture
uniform float wave_amplitude = 0.05; // Amplitude of the wave
uniform float wave_frequency = 10.0; // Frequency of the wave
uniform float scroll_speed = 0.04; // Speed for vertical scrolling
uniform float palette_shift_speed = 2; // Speed for palette shifting

void fragment() {
    vec2 uv = UV;
    uv.y += sin(uv.x * wave_frequency + TIME) * wave_amplitude;
    uv.x += sin(uv.x * wave_frequency + TIME) * wave_amplitude;
    uv.y += TIME * scroll_speed;
    uv.x += TIME * scroll_speed;
    uv.x = mod(uv.x, 1.0);
    uv.y = mod(uv.y, 1.0);
    
    // Get the original color from the main texture
    vec4 color = texture((TEXTURE), uv);
    
    // Use the red channel as the palette index, quantize to 256 levels
    float palette_index = floor(color.r*255.0);
    palette_index = mod(palette_index + floor(TIME * palette_shift_speed), 5.0)/5.0;
	
    // Sample the palette texture at the calculated index
    vec4 shifted_color = texture(palette_texture, vec2(palette_index, .5));
    
    COLOR = shifted_color;
}
