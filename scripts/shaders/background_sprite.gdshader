shader_type canvas_item;

uniform float wave_amplitude = 0.1; // Amplitude of the wave
uniform float wave_frequency = 10.0; // Frequency of the wave
uniform float time : hint_range(0, 5); // Time for animation
uniform float scroll_speed = 0.04;

void fragment() {
    vec2 uv = UV;
	uv.y += sin(uv.x * wave_frequency + TIME) * wave_amplitude;
	uv.y += TIME * scroll_speed;
	uv.x += TIME * scroll_speed;
    uv.x = mod(uv.x, 1.0);
    uv.y = mod(uv.y, 1.0);
    COLOR = texture(TEXTURE, uv);
}

