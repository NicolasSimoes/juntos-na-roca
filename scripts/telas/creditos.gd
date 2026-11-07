extends Control
## Créditos que sobem devagar, como no cinema. Os nomes da equipe vêm de
## Textos.CREDITOS_EQUIPE (é só editar a lista lá). AÇÃO ou Esc voltam ao menu.

signal fechou

## Velocidade da subida, em pixels por segundo.
@export var velocidade := 22.0

var _tempo := 0.0
var _fechando := false

@onready var _rolo: VBoxContainer = %Rolo
@onready var _equipe: VBoxContainer = %Equipe


func _ready() -> void:
	Elenco.vestir(self)
	for pessoa in Textos.CREDITOS_EQUIPE:
		var nome := Label.new()
		nome.text = pessoa[0] if pessoa[1] == "" else "%s  ·  %s" % [pessoa[0], pessoa[1]]
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.add_theme_font_size_override("font_size", 14)
		_equipe.add_child(nome)
	_rolo.position.y = size.y
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	_tempo += delta
	_rolo.position.y -= velocidade * delta
	# quando tudo passou, recomeça de baixo
	if _rolo.position.y + _rolo.size.y < 0.0:
		_rolo.position.y = size.y
	if _fechando or _tempo < 0.3:
		return
	if Jogo.apertou(1) or Jogo.apertou(2) or Input.is_action_just_pressed("pausa"):
		_fechando = true
		fechou.emit()
