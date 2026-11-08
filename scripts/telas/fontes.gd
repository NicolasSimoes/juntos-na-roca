class_name Fontes
## As fontes do jogo (as duas são livres, licença SIL OFL, em assets/fontes).
## Cinzel Decorative: títulos.   Pixelify Sans: textos de menu, com cara de jogo antigo.

static var _titulo: Font
static var _pixel := {}


static func titulo() -> Font:
	if _titulo == null:
		_titulo = load("res://assets/fontes/CinzelDecorative-Black.ttf")
	return _titulo


## peso: 400 normal, 700 negrito.
static func pixel(peso := 400) -> Font:
	if not _pixel.has(peso):
		var v := FontVariation.new()
		v.base_font = load("res://assets/fontes/PixelifySans.ttf")
		var ts := TextServerManager.get_primary_interface()
		v.variation_opentype = {ts.name_to_tag("wght"): peso}
		# sem ligaduras: a Pixelify junta "fi" num desenho só e "fica" vira "Aca"
		v.opentype_features = {ts.name_to_tag("liga"): 0}
		_pixel[peso] = v
	return _pixel[peso]


static func rotulo(texto: String, fonte: Font, tamanho: int, cor := Color.WHITE, contorno := 0, cor_contorno := Color(0.1, 0.07, 0.05)) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if contorno > 0:
		l.add_theme_constant_override("outline_size", contorno)
		l.add_theme_color_override("font_outline_color", cor_contorno)
	return l
