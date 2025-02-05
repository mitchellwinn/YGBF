shader_type canvas_item;

uniform bool palette_shift;
uniform bool ping_pong_shift;
uniform sampler2D palette_texture; // Palette texture
uniform int palette_size = 5;
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
    
	vec4 color = texture(TEXTURE, uv);
	
	if(palette_shift){
	    vec4 new_color = color;
		int shift;
		float ping_pong_time;
		if (ping_pong_shift){
			ping_pong_time = mod(TIME*palette_shift_speed, float(palette_size * 2));	
			shift = int(ping_pong_time);
		}
	    else{
			shift = int(mod(TIME*palette_shift_speed, float(palette_size)));
		}
	    if (shift >= palette_size) {
	        shift = palette_size * 2 - shift - 1;
	    }
	    for (int i = 0; i < palette_size; i++) {
	        vec4 palette_color = texelFetch(palette_texture, ivec2(i, 0), 0);
	        if (distance(color, palette_color) < 0.01) { // Use a small threshold to match colors
	            new_color = texelFetch(palette_texture, ivec2((i + shift) % palette_size, 0), 0);
	            break;
	        }
	    }
		COLOR = new_color; // Assign the new color to the current pixel	
	}
	else{
		COLOR = color;
	}
}
