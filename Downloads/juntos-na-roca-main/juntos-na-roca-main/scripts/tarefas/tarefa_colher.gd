extends Tarefa
## Dia 5 — Colher. Os dois colhem tudo e depois carregam juntos o jerimum
## gigante até a porteira, onde começa a Festa da Colheita.

var _fase := "colher"
var _jerimum: CarregarJuntos


func _init() -> void:
	dica = "Parem na planta que brilha e colham!"


func posicao_estacao() -> Vector2:
	return Lugares.ESTACAO_HORTA


func papeis() -> Array:
	var cesta := tex("res://assets/sprites/objetos/cesta.png")
	return ["colher", "colher", cesta, cesta]


func comecar(a: Jogador, b: Jogador) -> void:
	super.comecar(a, b)
	fazenda.hud.falar("Tudo maduro! Colham o que brilha.")


func atualizar(_delta: float) -> void:
	if _fase != "colher":
		return
	var horta: Horta = fazenda.horta
	var alvos := {}
	for j in jogadores():
		var i := horta.cova_perto(j.global_position)
		alvos[j.numero] = i
		if Jogo.apertou(j.numero) and i >= 0 and horta.cova(i)["fase"] == 4:
			horta.cova(i)["fase"] = 5
			Jogo.adicionar(horta.tipo(i), 1)
			Sons.tocar("pegar")
			j.pular()
			progresso()
	horta.alvos = alvos
	for c in Jogo.horta:
		if c["fase"] == 4:
			return
	_fase = "jerimum"
	horta.alvos = {}
	dica = "Fiquem pertinho e levem o jerimum!"
	_jerimum = CarregarJuntos.new().configurar("res://assets/sprites/objetos/jerimum_gigante.png", Lugares.JERIMUM_GIGANTE, Lugares.DESTINO_FESTA)
	fazenda.mundo.add_child(_jerimum)
	_jerimum.entregue.connect(_entregou)
	_jerimum.caiu.connect(func(): fazenda.hud.aviso("Opa! Fiquem pertinho."))
	Sons.tocar("acerto")
	fazenda.hud.falar("Jerimum gigante! Levem juntos até a porteira!")


func _entregou() -> void:
	Jogo.adicionar("jerimum", 1)
	finalizar()


func ponto_guia() -> Variant:
	if not em_andamento:
		return super.ponto_guia()
	if _fase == "jerimum" and is_instance_valid(_jerimum):
		return Lugares.DESTINO_FESTA.get_center() if _jerimum.segurando else _jerimum.global_position
	for i in Jogo.horta.size():
		if Jogo.horta[i]["fase"] == 4:
			return fazenda.horta.centro(i)
	return null
