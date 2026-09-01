shader_type canvas_item;

uniform vec4 remove_color1 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 remove_color2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float tolerance : hint_range(0.0, 1.0) = 0.01;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float dist1 = distance(tex_color.rgb, remove_color1.rgb);
    float dist2 = distance(tex_color.rgb, remove_color2.rgb);
    
    if (dist1 < tolerance || dist2 < tolerance) {
        COLOR = vec4(tex_color.rgb, 0.0);
    } else {
        COLOR = tex_color;
    }
}
