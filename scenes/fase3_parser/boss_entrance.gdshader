shader_type canvas_item;

// Cor a ser removida (por padrão, preto)
uniform vec4 key_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Tolerância para pegar tons próximos da cor escolhida (ajuste de 0.0 a 1.0)
uniform float threshold : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // Calcula a diferença entre a cor do pixel e a cor a ser removida
    float dist = distance(color.rgb, key_color.rgb);
    
    if (dist < threshold) {
        COLOR.a = 0.0; // Torna o fundo transparente
    } else {
        COLOR = color;
    }
}
