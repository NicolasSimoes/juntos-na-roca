class_name Jogador
extends CharacterBody2D
## Um dos dois amigos. "numero" diz quais teclas ele usa:
## 1 = W A S D + Espaço (laranja)   2 = Setas + Enter (azul).
## A posição do nó fica nos pés do personagem.

@export var numero := 1
@export var velocidade := 80.0

var pode_mover := true
var carregando := ""       # nome do item na mão ("" = mãos livres)
var carregando_junto := false   # true quando está levando algo pesado com o amigo
var _direcao_anim := "baixo"
var _passos := 0.0
var _comemorando := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var item_sprite: Sprite2D = $Item

## Altura do sprite acima dos pés (o quadro do pacote tem 20 px de altura).
const PES_Y := -10.0


func _ready() -> void:
	add_to_group("jogadores")
	z_index = 10
	# As animações vêm do pacote Super Retro World (ver scripts/aparencia.gd).
	sprite.sprite_frames = Aparencia.quadros_neto(numero)
	sprite.play("parado_baixo")
	# O anel sob os pés mostra de quem é o neto: laranja (1) ou azul (2).
	$Anel.modulate = Jogo.COR[numero]


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if pode_mover:
		dir = Jogo.direcao(numero)
	var vel := velocidade * (0.75 if carregando_junto else 1.0)
	velocity = dir * vel
	var antes := global_position
	move_and_slide()
	_animar(dir)
	_passos += global_position.distance_to(antes)
	if _passos > 18.0:
		_passos = 0.0
		Sons.tocar("passo", -14.0, randf_range(0.85, 1.15))


func _animar(dir: Vector2) -> void:
	if _comemorando > 0.0:
		_comemorando -= get_physics_process_delta_time()
		sprite.flip_h = false
		sprite.play("comemora")
		if _comemorando <= 0.0:
			_direcao_anim = "baixo"
		return
	if dir.length() > 0.1:
		if absf(dir.x) > absf(dir.y):
			_direcao_anim = "lado"
			sprite.flip_h = dir.x < 0
		elif dir.y < 0:
			_direcao_anim = "cima"
		else:
			_direcao_anim = "baixo"
		sprite.play("anda_" + _direcao_anim)
	else:
		sprite.play("parado_" + _direcao_anim)


## Põe um item na mão (aparece em cima da cabeça).
func segurar(item: String, textura: Texture2D = null) -> void:
	carregando = item
	item_sprite.texture = textura
	item_sprite.visible = textura != null


## Larga o item e devolve o nome dele.
func largar() -> String:
	var item := carregando
	carregando = ""
	item_sprite.visible = false
	return item


## Some do mapa (por exemplo, quando sobe no trator).
func esconder(sim: bool) -> void:
	visible = not sim
	pode_mover = not sim
	$Colisao.set_deferred("disabled", sim)


## Pulinho de alegria.
func pular() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "position:y", PES_Y - 6.0, 0.12)
	tw.tween_property(sprite, "position:y", PES_Y, 0.12)


## Comemora com os braços para cima, dando pulinhos.
func comemorar() -> void:
	_comemorando = 1.4
	var tw := create_tween()
	for i in 3:
		tw.tween_property(sprite, "position:y", PES_Y - 6.0, 0.13)
		tw.tween_property(sprite, "position:y", PES_Y, 0.13)


func olhar_para_baixo() -> void:
	_direcao_anim = "baixo"
	sprite.play("parado_baixo")
