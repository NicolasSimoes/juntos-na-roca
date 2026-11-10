extends Node
## Autoload "Sons": toca os efeitos (assets/sons/*.wav) e a música (*.ogg).
## Uso: Sons.tocar("toim")   Sons.musica("musica_fazenda")

var _canais: Array[AudioStreamPlayer] = []
var _musica: AudioStreamPlayer
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var canal := AudioStreamPlayer.new()
		add_child(canal)
		_canais.append(canal)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -10.0
	add_child(_musica)


func tocar(nome: String, volume_db := 0.0, tom := 1.0) -> void:
	var som := _carregar("res://assets/sons/%s.wav" % nome)
	if som == null:
		return
	var livre: AudioStreamPlayer = _canais[0]
	for canal in _canais:
		if not canal.playing:
			livre = canal
			break
	livre.stream = som
	livre.volume_db = volume_db
	livre.pitch_scale = tom
	livre.play()


func musica(nome: String, repetir := true) -> void:
	var caminho := "res://assets/sons/%s.ogg" % nome
	if _musica.playing and _musica.stream and _musica.stream.resource_path == caminho:
		return
	var som := _carregar(caminho) as AudioStreamOggVorbis
	if som == null:
		return
	som.loop = repetir
	_musica.stream = som
	_musica.play()


func parar_musica() -> void:
	_musica.stop()


func _carregar(caminho: String) -> AudioStream:
	if not _cache.has(caminho):
		_cache[caminho] = load(caminho) if ResourceLoader.exists(caminho) else null
	return _cache[caminho]
