extends Node
## Autoload "ControleESP32": deixa jogar com o controle de ESP32 (2 joysticks Funduino).
##
## O ESP32 manda pelo Bluetooth, umas 30 vezes por segundo, uma linha assim:
##     J,X1,Y1,B1,X2,Y2,B2
## X e Y vão de 0 a 1023 (512 = parado) e B é 1 quando o botão do joystick está apertado.
##
## O Godot não lê porta serial/Bluetooth sozinho. Por isso existe a ponte
## ferramentas/ponte_esp32.py: ela lê a porta COM do Bluetooth e repassa cada linha
## para cá por UDP (127.0.0.1, porta PORTA). Este autoload transforma cada linha
## nas mesmas ações do teclado (p1_cima, p1_acao, p2_esquerda...), então o jogo
## inteiro funciona sem mudar mais nada.
##
## Se a ponte não estiver rodando, o autoload tenta abrir ela sozinho (só quando o
## jogo é aberto pela pasta do projeto, no editor ou com "godot --path").

signal conexao_mudou(conectado: bool)

const PORTA := 4242
## Mexer o joystick além disso (de 0 a 1) conta como apertar a direção.
const LIMIAR := 0.5
## Sem receber nada por este tempo (s), o controle é dado como desligado.
const TEMPO_SEM_SINAL := 1.0
## O joystick do Funduino aumenta o Y quando é empurrado para cima.
## No Godot "cima" é Y negativo, então invertemos. Se ficar trocado, mude para false.
const INVERTER_Y := true
const INVERTER_X := false
## Segurar os DOIS botões juntos por este tempo (s) aperta "pausa" (o controle não tem Start).
const TEMPO_PAUSA := 1.0
const PONTE := "res://ferramentas/ponte_esp32.py"
## Número de "aparelho" dos eventos do ESP32 (não bate com teclado nem com controles USB).
const APARELHO := 42

var conectado := false
## Últimos valores, de -1 a 1 (eixos) e true/false (botão), para quem quiser mostrar na tela.
var eixos := {1: Vector2.ZERO, 2: Vector2.ZERO}
var botoes := {1: false, 2: false}

var _udp := PacketPeerUDP.new()
var _ouvindo := false
var _sem_sinal := 0.0
var _apertadas := {}          # ação -> true enquanto o controle segura a ação
var _forcas := {}             # ação -> última força mandada
var _tempo_dois_botoes := 0.0
var _pausa_enviada := false
var _pid_ponte := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua lendo com o jogo pausado
	if DisplayServer.get_name() == "headless":
		return   # testes automáticos: sem controle
	var erro := _udp.bind(PORTA, "127.0.0.1")
	_ouvindo = erro == OK
	if not _ouvindo:
		push_warning("ControleESP32: não consegui usar a porta UDP %d (erro %d)." % [PORTA, erro])
		return
	_abrir_ponte()


func _exit_tree() -> void:
	_soltar_tudo()
	if _pid_ponte > 0:
		OS.kill(_pid_ponte)
	_udp.close()


func _process(delta: float) -> void:
	if not _ouvindo:
		return
	var chegou := false
	var ultima := ""
	while _udp.get_available_packet_count() > 0:
		ultima = _udp.get_packet().get_string_from_utf8()
		chegou = true
	if chegou:
		# só a linha mais nova importa (as outras já ficaram velhas)
		for linha in ultima.split("\n", false):
			if _aplicar(linha.strip_edges()):
				_sem_sinal = 0.0
				_mudar_conexao(true)
	else:
		_sem_sinal += delta
		if conectado and _sem_sinal > TEMPO_SEM_SINAL:
			_soltar_tudo()
			_mudar_conexao(false)


## Lê "J,X1,Y1,B1,X2,Y2,B2" e aperta/solta as ações. Devolve false se a linha não serve.
func _aplicar(linha: String) -> bool:
	var partes := linha.split(",")
	if partes.size() != 7 or partes[0] != "J":
		return false
	for i in range(1, 7):
		if not partes[i].is_valid_int():
			return false
	for n in [1, 2]:
		var base: int = 1 + (n - 1) * 3
		var x := _normalizar(partes[base].to_int(), INVERTER_X)
		var y := _normalizar(partes[base + 1].to_int(), INVERTER_Y)
		var b := partes[base + 2].to_int() == 1
		eixos[n] = Vector2(x, y)
		botoes[n] = b
		_acao("p%d_esquerda" % n, maxf(0.0, -x))
		_acao("p%d_direita" % n, maxf(0.0, x))
		_acao("p%d_cima" % n, maxf(0.0, -y))
		_acao("p%d_baixo" % n, maxf(0.0, y))
		_acao("p%d_acao" % n, 1.0 if b else 0.0)
	_checar_pausa()
	return true


## 0..1023 (512 = centro) vira -1..1.
func _normalizar(valor: int, inverter: bool) -> float:
	var v := clampf((valor - 512) / 511.0, -1.0, 1.0)
	return -v if inverter else v


## Aperta (com força) ou solta uma ação, mandando um evento de verdade:
## assim funcionam tanto o Input.is_action_just_pressed quanto o _unhandled_input.
func _acao(nome: String, forca: float) -> void:
	var apertar := forca >= LIMIAR
	var estava: bool = _apertadas.get(nome, false)
	var forca_antes: float = _forcas.get(nome, 0.0)
	if not apertar and not estava:
		return
	if apertar and estava and absf(forca - forca_antes) < 0.05:
		return   # nada mudou de verdade
	var e := InputEventAction.new()
	e.device = APARELHO
	e.action = nome
	e.pressed = apertar
	e.strength = clampf(forca, 0.0, 1.0) if apertar else 0.0
	Input.parse_input_event(e)
	_apertadas[nome] = apertar
	_forcas[nome] = e.strength


func _checar_pausa() -> void:
	if botoes[1] and botoes[2]:
		_tempo_dois_botoes += get_process_delta_time()
		if _tempo_dois_botoes >= TEMPO_PAUSA and not _pausa_enviada:
			_pausa_enviada = true
			_evento_pausa(true)
			# solta no quadro seguinte (soltar no mesmo quadro poderia "sumir" com o aperto)
			await get_tree().process_frame
			_evento_pausa(false)
	else:
		_tempo_dois_botoes = 0.0
		_pausa_enviada = false


func _evento_pausa(apertado: bool) -> void:
	var e := InputEventAction.new()
	e.device = APARELHO
	e.action = "pausa"
	e.pressed = apertado
	Input.parse_input_event(e)


func _soltar_tudo() -> void:
	for nome in _apertadas.keys():
		if _apertadas[nome]:
			var e := InputEventAction.new()
			e.device = APARELHO
			e.action = nome
			e.pressed = false
			Input.parse_input_event(e)
	_apertadas.clear()
	_forcas.clear()
	for n in [1, 2]:
		eixos[n] = Vector2.ZERO
		botoes[n] = false


func _mudar_conexao(sim: bool) -> void:
	if sim == conectado:
		return
	conectado = sim
	print("ControleESP32: ", "conectado" if sim else "desconectado")
	conexao_mudou.emit(sim)


## Abre a ponte (Python) escondida, se o arquivo existir no disco.
func _abrir_ponte() -> void:
	var caminho := ProjectSettings.globalize_path(PONTE)
	if not FileAccess.file_exists(caminho) or not caminho.is_absolute_path():
		return
	var comandos: Array = [["pyw", ["-3"]], ["pythonw", []], ["py", ["-3"]], ["python", []], ["python3", []]] \
			if OS.get_name() == "Windows" else [["python3", []], ["python", []]]
	for c in comandos:
		var args: Array = c[1].duplicate()
		args.append_array([caminho, "--udp", str(PORTA), "--sair-com-pid", str(OS.get_process_id())])
		var pid := OS.create_process(c[0], PackedStringArray(args))
		if pid > 0:
			_pid_ponte = pid
			print("ControleESP32: ponte aberta com ", c[0])
			return
