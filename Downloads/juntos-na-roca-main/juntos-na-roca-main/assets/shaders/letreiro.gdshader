shader_type canvas_item;
// O chão da roça em perspectiva (pasto listrado no meio, trilha de terra, cerca e
// plantação dos lados), com o texto amarelo do prefácio "deitado" no pasto.
// O texto é desenhado reto numa SubViewport; aqui ele e o chão são projetados
// até o horizonte. "rolagem" anda o chão e o texto juntos: parece que a câmera
// vai voando baixinho por cima do pasto, em direção à casa da Vovó.

uniform sampler2D texto : filter_linear, repeat_disable;
uniform vec2 tamanho_texto = vec2(960.0, 2600.0); // tamanho da SubViewport, em texels
uniform vec2 tela = vec2(640.0, 360.0);
uniform float rolagem = 0.0;    // linha do mundo que está na borda de baixo da tela
uniform float horizonte = 116.0;
uniform float escala = 0.62;    // pixels da tela por texel, na borda de baixo
uniform float sumir = 7.0;      // distância em que o texto some de vez
uniform float texto_alfa = 1.0;
uniform vec3 luz = vec3(1.0);              // cor da luz (amanhecer → manhã)
uniform vec3 neblina = vec3(0.8, 0.85, 0.8); // cor do longe

const float PASTO = 500.0;   // metade da largura do pasto (o texto tem 480 de cada lado)
const float CERCA = 540.0;   // onde fica a cerca

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// integral da onda quadrada (0 na primeira metade do período, 1 na segunda)
float integral_listra(float u) {
	return floor(u) * 0.5 + max(fract(u) - 0.5, 0.0);
}

// listra sem serrilhado: a média da onda quadrada dentro da largura de um pixel.
// Quando as listras ficam menores que um pixel, vira a média (0,5).
float listra(float x, float periodo, float largura_pixel) {
	float u = x / periodo;
	float w = max(largura_pixel / periodo, 0.0001);
	return (integral_listra(u + w * 0.5) - integral_listra(u - w * 0.5)) / w;
}

vec4 amostra(vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	return texture(texto, uv);
}

void fragment() {
	vec2 p = UV * tela;
	float h = tela.y - horizonte;
	if (p.y <= horizonte) {
		COLOR = vec4(0.0);
	} else {
		float z = h / max(p.y - horizonte, 0.01);
		float X = (p.x - tela.x * 0.5) * z / escala;      // de lado, em texels
		float Y = rolagem - (z - 1.0) * h / escala;        // para frente, em texels
		float px = max(fwidth(X), 0.001) * 1.5;            // quantos texels cabem num pixel
		float detalhe = 1.0 - smoothstep(1.5, 4.5, z);
		float ax = abs(X);
		vec3 c;
		if (ax < PASTO) {
			// pasto com faixas de grama cortada que vão até o horizonte
			float f = listra(X + 60.0, 240.0, px);
			c = mix(vec3(0.30, 0.56, 0.22), vec3(0.36, 0.63, 0.26), f);
			float tufo = hash(floor(vec2(X, Y) / 14.0));
			c += (tufo - 0.5) * 0.07 * detalhe;
			if (hash(floor(vec2(X, Y) / 6.0) + 3.1) > 0.965) {
				c += vec3(0.07, 0.09, 0.03) * detalhe;
			}
		} else if (ax < CERCA + 14.0) {
			// trilha de terra junto da cerca
			c = vec3(0.64, 0.49, 0.32);
			c += (hash(floor(vec2(X, Y) / 8.0)) - 0.5) * 0.08 * detalhe;
		} else {
			// plantação: fileiras de pés de milho e terra
			float f = listra(ax - CERCA, 44.0, px);
			vec3 terra = vec3(0.46, 0.31, 0.19);
			vec3 folha = vec3(0.33, 0.58, 0.21) + (hash(floor(vec2(X / 44.0, Y / 10.0))) - 0.5) * 0.08 * detalhe;
			c = mix(folha, terra, f);
		}
		c *= luz;
		c = mix(c, neblina, smoothstep(2.0, 14.0, z) * 0.75);

		// o texto, com várias amostras dentro do pixel para não chuviscar de longe
		vec2 uv = vec2(X + tamanho_texto.x * 0.5, Y) / tamanho_texto;
		vec2 dx = dFdx(uv);
		vec2 dy = dFdy(uv);
		vec4 t = vec4(0.0);
		for (int i = 0; i < 3; i++) {
			for (int j = 0; j < 3; j++) {
				t += amostra(uv + (float(i) - 1.0) / 3.0 * dx + (float(j) - 1.0) / 3.0 * dy);
			}
		}
		t /= 9.0;
		if (t.a > 0.001) {
			t.rgb /= t.a; // a SubViewport guarda a cor já multiplicada pelo alfa
		}
		t.a *= texto_alfa * (1.0 - smoothstep(sumir * 0.45, sumir, z));
		c = mix(c, t.rgb * mix(vec3(1.0), luz, 0.35), t.a);
		COLOR = vec4(c, 1.0);
	}
}
