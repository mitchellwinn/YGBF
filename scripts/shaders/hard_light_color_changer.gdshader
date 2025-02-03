shader_type canvas_item;

uniform vec4 color; // Color to blend with
uniform bool use_blend = true; // Toggle to enable/disable hard light blend mode

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    vec4 result_color;
    if (use_blend) {
       result_color = tex_color * color;
    } else {
        result_color = tex_color;
    }

    result_color.a = tex_color.a;

    COLOR = result_color;
}
