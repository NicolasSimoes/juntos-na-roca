shader_type canvas_item;
// Deixa cinza tudo o que está desenhado embaixo deste retângulo.
// "cinza" = 1 deixa totalmente cinza; 0 deixa com as cores normais.

uniform sampler2D tela : hint_screen_texture, filter_nearest;
uniform float cinza : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 cor = texture(tela, SCREEN_UV).rgb;
	float luz = dot(cor, vec3(0.299, 0.587, 0.114));
	vec3 cinzento = vec3(luz) * 0.8 + vec3(0.1);
	COLOR = vec4(mix(cor, cinzento, cinza), 1.0);
}
