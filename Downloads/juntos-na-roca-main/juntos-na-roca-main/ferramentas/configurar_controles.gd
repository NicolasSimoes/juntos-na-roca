extends SceneTree
## Cria o Input Map do projeto (p1_ e p2_) e salva no project.godot.
## Rodar uma vez: godot --headless --path <projeto> --script <este arquivo>

func _init() -> void:
	var acoes := {
		"p1_cima": [_tecla(KEY_W), _eixo(0, JOY_AXIS_LEFT_Y, -1.0), _botao(0, JOY_BUTTON_DPAD_UP)],
		"p1_baixo": [_tecla(KEY_S), _eixo(0, JOY_AXIS_LEFT_Y, 1.0), _botao(0, JOY_BUTTON_DPAD_DOWN)],
		"p1_esquerda": [_tecla(KEY_A), _eixo(0, JOY_AXIS_LEFT_X, -1.0), _botao(0, JOY_BUTTON_DPAD_LEFT)],
		"p1_direita": [_tecla(KEY_D), _eixo(0, JOY_AXIS_LEFT_X, 1.0), _botao(0, JOY_BUTTON_DPAD_RIGHT)],
		"p1_acao": [_tecla(KEY_SPACE), _botao(0, JOY_BUTTON_A)],
		"p2_cima": [_tecla(KEY_UP), _eixo(1, JOY_AXIS_LEFT_Y, -1.0), _botao(1, JOY_BUTTON_DPAD_UP)],
		"p2_baixo": [_tecla(KEY_DOWN), _eixo(1, JOY_AXIS_LEFT_Y, 1.0), _botao(1, JOY_BUTTON_DPAD_DOWN)],
		"p2_esquerda": [_tecla(KEY_LEFT), _eixo(1, JOY_AXIS_LEFT_X, -1.0), _botao(1, JOY_BUTTON_DPAD_LEFT)],
		"p2_direita": [_tecla(KEY_RIGHT), _eixo(1, JOY_AXIS_LEFT_X, 1.0), _botao(1, JOY_BUTTON_DPAD_RIGHT)],
		"p2_acao": [_tecla(KEY_ENTER), _tecla(KEY_KP_ENTER), _botao(1, JOY_BUTTON_A)],
		"pausa": [_tecla(KEY_ESCAPE), _botao(-1, JOY_BUTTON_START)],
	}
	for acao in acoes:
		ProjectSettings.set_setting("input/" + acao, {"deadzone": 0.5, "events": acoes[acao]})
	ProjectSettings.save()
	print("controles salvos")
	quit()


func _tecla(codigo: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.device = -1
	e.physical_keycode = codigo
	return e


func _eixo(aparelho: int, eixo: JoyAxis, valor: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.device = aparelho
	e.axis = eixo
	e.axis_value = valor
	return e


func _botao(aparelho: int, botao: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.device = aparelho
	e.button_index = botao
	return e
