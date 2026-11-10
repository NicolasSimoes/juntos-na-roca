extends Control
## Tela inicial. O jogo só começa quando os DOIS apertam AÇÃO.
## Cada cartão mostra o neto, as teclas dele e se já está pronto.

const FAZENDA := "res://cenas/fazenda.tscn"
const MENU := "res://cenas/menu_principal.tscn"

var _pronto := {1: false, 2: false}
var _indo := false
var _tempo := 0.0

@onready var _netos := {1: %Neto1 as TextureRect, 2: %Neto2 as TextureRect}
@onready var _teclas := {1: %Teclas1 as TeclasJogador, 2: %Teclas2 as TeclasJogador}
@onready var _status := {1: %Status1 as Label, 2: %Status2 as Label}
@onready var _rodape: Label = %Menu


func _ready() -> void:
	Jogo.novo_jogo()
	Sons.musica("musica_inicio")
	Elenco.vestir(self)
	ControleESP32.conexao_mudou.connect(_mostrar_controle)
	_mostrar_controle(ControleESP32.conectado)


## O rodapé avisa quando o controle de ESP32 está ligado.
func _mostrar_controle(conectado: bool) -> void:
	if conectado:
		_rodape.text = "menu     ·     controle ESP32 conectado!"
		_rodape.add_theme_color_override("font_color", Color(0.6, 1, 0.5))
	else:
		_rodape.text = "menu     ·     com controle também funciona!"
		_rodape.remove_theme_color_override("font_color")


func _process(delta: float) -> void:
	_tempo += delta
	for n in [1, 2]:
		var status: Label = _status[n]
		if Jogo.apertou(n) and not _pronto[n]:
			_ficar_pronto(n)
		status.modulate.a = 1.0 if _pronto[n] else 0.55 + 0.45 * absf(sin(_tempo * 4.0))
	if _indo:
		return
	if Input.is_action_just_pressed("pausa"):
		_indo = true
		Sons.tocar("menu_voltar")
		get_tree().change_scene_to_file(MENU)
	elif _pronto[1] and _pronto[2]:
		_indo = true
		Sons.tocar("acerto")
		await get_tree().create_timer(0.7).timeout
		get_tree().change_scene_to_file(FAZENDA)


func _ficar_pronto(n: int) -> void:
	_pronto[n] = true
	Sons.tocar("pegar")
	var status: Label = _status[n]
	status.text = "Pronto!"
	status.add_theme_color_override("font_color", Color(0.6, 1, 0.5))
	(_teclas[n] as TeclasJogador).get_node("%Acao").apertar()
	# o neto dá um pulinho de alegria
	var neto: TextureRect = _netos[n]
	var tw := create_tween()
	tw.tween_property(neto, "position:y", neto.position.y - 10, 0.12)
	tw.tween_property(neto, "position:y", neto.position.y, 0.12)
