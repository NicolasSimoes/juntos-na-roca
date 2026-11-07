extends Tarefa
## Dia 1 — Consertar o poço.
## Primeiro a dupla traz a corda (do galpão) e as tábuas (da mata) até o poço.
## Depois: um encaixa as tábuas no espaço de mesmo formato e o outro acerta o martelo.

var _corda: Coletavel
var _tabuas: Coletavel
var _entregues := {}


func _init() -> void:
	dica = "Um põe a tábua no espaço de mesmo formato. O outro bate o martelo quando o marcador passar no prego!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_POCO


func papeis() -> Array:
	return ["encaixar", "martelar", tex("res://assets/sprites/extras/pilha_tabuas.png"),
			tex("res://assets/sprites/objetos/martelo.png")]


func preparar() -> void:
	_corda = Coletavel.new().configurar("corda", "res://assets/sprites/extras/corda.png", Lugares.CORDA)
	fazenda.mundo.add_child(_corda)
	_tabuas = Coletavel.new().configurar("tabuas", "res://assets/sprites/extras/pilha_tabuas.png", Lugares.TABUAS)
	fazenda.mundo.add_child(_tabuas)


func pode_comecar() -> bool:
	return _entregues.size() >= 2


func aguardando(_delta: float) -> void:
	for j in jogadores():
		if j.carregando in ["corda", "tabuas"] and j.global_position.distance_to(Lugares.POCO_CENTRO) < 28.0:
			var item := j.largar()
			_entregues[item] = true
			Sons.tocar("soltar")
			if _entregues.size() < 2:
				fazenda.hud.aviso("Falta " + ("a corda!" if item == "tabuas" else "as tábuas!"))
			else:
				fazenda.hud.aviso("Tudo aqui! Os dois nos círculos.")


func ponto_guia() -> Variant:
	if pode_comecar():
		return super.ponto_guia()
	for j in jogadores():
		if j.carregando in ["corda", "tabuas"]:
			return Lugares.POCO_CENTRO
	if is_instance_valid(_corda):
		return _corda.global_position
	if is_instance_valid(_tabuas):
		return _tabuas.global_position
	return Lugares.POCO_CENTRO


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	var mj: MinijogoPoco = preload("res://cenas/minijogos/minijogo_poco.tscn").instantiate()
	abrir_minijogo(mj)
	mj.concluido.connect(finalizar)


func encerrar() -> void:
	fazenda.consertar_poco()


func _draw() -> void:
	if em_andamento or Jogo.feita("poco"):
		return
	if _entregues.has("corda"):
		draw_texture(tex("res://assets/sprites/extras/corda.png"), Lugares.POCO_CENTRO + Vector2(-30, -6))
	if _entregues.has("tabuas"):
		draw_texture(tex("res://assets/sprites/extras/pilha_tabuas.png"), Lugares.POCO_CENTRO + Vector2(14, -6))
