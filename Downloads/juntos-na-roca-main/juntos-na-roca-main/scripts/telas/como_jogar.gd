extends Control
## "Como jogar": quase sem texto. Os dois netos com as suas teclas (que se apertam
## sozinhas, mostrando o que fazer) e quatro cartões ilustrados com as regras.
## Qualquer AÇÃO ou Esc fecha e avisa o menu pelo sinal "fechou".

signal fechou

var _tempo := 0.0
var _fechando := false

@onready var _seta: Sprite2D = %SetaGuia
@onready var _pa: Label = %Pa
@onready var _toque_a: Sprite2D = %ToqueA
@onready var _toque_b: Sprite2D = %ToqueB
var _seta_y := 0.0


func _ready() -> void:
	Elenco.vestir(self)
	_seta_y = _seta.position.y
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _process(delta: float) -> void:
	_tempo += delta
	# a seta do cartão "Siga a seta" pula, como no jogo
	_seta.position.y = _seta_y + 3.0 * sin(_tempo * 6.0)
	# "Toca aqui!": os dois pulam juntos e aparece o "PÁ!" a cada 1,6 s
	var ciclo := fmod(_tempo, 1.6)
	var pulo := absf(sin(ciclo * PI / 0.5)) * 6.0 if ciclo < 0.5 else 0.0
	_toque_a.offset.y = -_toque_a.texture.get_height() - pulo / _toque_a.scale.y
	_toque_b.offset.y = _toque_a.offset.y
	_pa.modulate.a = 1.0 if ciclo > 0.2 and ciclo < 0.9 else 0.0
	_pa.scale = Vector2.ONE * (1.0 + 0.3 * maxf(0.0, 0.5 - ciclo))
	if _fechando or _tempo < 0.3:
		return
	if Jogo.apertou(1) or Jogo.apertou(2) or Input.is_action_just_pressed("pausa"):
		_fechando = true
		fechou.emit()
