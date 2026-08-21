shader_type canvas_item;

// Filtro temporario para tutoriais. Valores negativos escurecem o asset;
// valores positivos aproximam suas cores do branco sem alterar a textura.
uniform float intensidade : hint_range(-0.35, 0.45) = 0.0;

void fragment() {
	vec4 cor_base = texture(TEXTURE, UV) * COLOR;
	if (intensidade < 0.0) {
		cor_base.rgb *= 1.0 + intensidade;
	} else {
		cor_base.rgb = mix(cor_base.rgb, vec3(1.0), intensidade);
	}
	COLOR = cor_base;
}
