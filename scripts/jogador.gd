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


func _ready() -> void:
	add_to_group("jogadores")
	z_index = 10
	sprite.sprite_frames = _montar_animacoes()
	sprite.play("parado_baixo")


func _montar_animacoes() -> SpriteFrames:
	var quadros := SpriteFrames.new()
	var base := "res://assets/sprites/personagens/p%d_" % numero
	for d in ["baixo", "cima", "lado"]:
		var parado: Texture2D = load(base + d + "_parado.png")
		quadros.add_animation("parado_" + d)
		quadros.add_frame("parado_" + d, parado)
		quadros.add_animation("anda_" + d)
		quadros.set_animation_speed("anda_" + d, 9.0)
		for k in [1, 2, 3, 4]:
			quadros.add_frame("anda_" + d, load(base + d + "_anda%d.png" % k))
	quadros.add_animation("comemora")
	quadros.set_animation_speed("comemora", 7.0)
	quadros.add_frame("comemora", load(base + "comemora1.png"))
	quadros.add_frame("comemora", load(base + "comemora2.png"))
	return quadros


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
	tw.tween_property(sprite, "position:y", -18.0, 0.12)
	tw.tween_property(sprite, "position:y", -12.0, 0.12)


## Comemora com os braços para cima, dando pulinhos.
func comemorar() -> void:
	_comemorando = 1.4
	var tw := create_tween()
	for i in 3:
		tw.tween_property(sprite, "position:y", -18.0, 0.13)
		tw.tween_property(sprite, "position:y", -12.0, 0.13)


func olhar_para_baixo() -> void:
	_direcao_anim = "baixo"
	sprite.play("parado_baixo")
