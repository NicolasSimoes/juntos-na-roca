shader_type canvas_item;
// Pinta as letras do título de dourado (claro em cima, escuro embaixo)
// e passa uma faixa de brilho na diagonal, de tempos em tempos.
// O contorno escuro das letras não é mexido.

uniform float altura = 56.0;        // altura das letras, em pixels
uniform float brilho_pos = -200.0;  // onde está a faixa de brilho

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	if (c.r + c.g + c.b > 1.5) {
		float t = clamp((local.y - altura * 0.15) / altura, 0.0, 1.0);
		vec3 ouro = mix(vec3(1.0, 0.96, 0.66), vec3(0.9, 0.52, 0.12), t);
		float faixa = 1.0 - smoothstep(0.0, 10.0, abs(local.x + local.y * 0.7 - brilho_pos));
		c.rgb = ouro + vec3(faixa * 0.55);
	}
	COLOR = c;
}
