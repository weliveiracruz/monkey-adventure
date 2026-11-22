extends CanvasLayer
## Diálogos e avisos falados em português (voz do próprio celular) com legenda.

## Tom de voz de cada personagem.
const TONS := {
	"Macaco": 1.25, "Vovô Macaco": 0.8, "Narrador": 1.0, "Coruja": 1.4,
	"Crocodilo": 0.7, "Elefante": 0.65, "Leoa": 1.05, "Leão": 0.6,
	"Hiena": 1.4, "Zebra": 1.1, "Garça": 1.3, "Piranha": 1.5, "Cabra": 1.3,
	"Águia": 1.2, "Urso": 0.6, "Gavião": 1.3, "Aranha": 1.4, "Eco": 0.9,
	"Morcegos": 1.6, "Galinha": 1.5, "Cachorro": 1.1, "Bode": 0.9,
	"Touro": 0.55, "Pombo": 1.3, "Gato": 1.4, "Feirante": 1.0,
	"Carrocinha": 0.85, "Tratador": 0.9, "Pinguim": 1.5, "Macaco preso": 1.3,
	"Macaco aliado": 1.3, "Rinoceronte": 0.6, "Caranguejo": 1.4,
	"Gaivota": 1.5, "Tartaruga gigante": 0.6, "Babuíno": 1.2,
	"Gorila-chefe": 0.5, "Macaco bagunceiro": 1.4, "Animais da selva": 1.1,
}

var _voz := ""
var _tem_tts := false
var _suporta_tts := false
var _t_busca := 0.0
var _buscas := 0
var _fila := []
var _falando := false
var _t := 0.0
var _id := 0
var _id_atual := -1
var _esconder_t := 0.0

## Quantos menus estão abertos: nos menus a voz fala sempre, mesmo com a narração desligada,
## para quem não enxerga conseguir ligar de novo.
var menus_abertos := 0

var _painel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_legenda()
	_suporta_tts = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if _suporta_tts:
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _terminou_fala)
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _terminou_fala)
		_procurar_voz()


## No Android a lista de vozes pode demorar a ficar pronta: tenta de novo por alguns segundos.
func _procurar_voz() -> void:
	_escolher_voz()
	_tem_tts = _voz != ""


func _escolher_voz() -> void:
	var todas: Array = DisplayServer.tts_get_voices()
	for v in todas:
		var lang := String(v.get("language", "")).to_lower()
		if lang.begins_with("pt_br") or lang.begins_with("pt-br"):
			_voz = String(v.get("id", ""))
			return
	var pt: PackedStringArray = DisplayServer.tts_get_voices_for_language("pt")
	if pt.size() > 0:
		_voz = pt[0]
		return
	if todas.size() > 0:
		_voz = String(todas[0].get("id", ""))


func _montar_legenda() -> void:
	_painel = PanelContainer.new()
	_painel.anchor_left = 0.08
	_painel.anchor_right = 0.92
	_painel.anchor_top = 0.80
	_painel.anchor_bottom = 0.96
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.6)
	estilo.set_corner_radius_all(14)
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	_painel.add_theme_stylebox_override("panel", estilo)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_painel.add_child(_label)
	add_child(_painel)
	_painel.visible = false


func _duracao(texto: String) -> float:
	return 0.7 + texto.length() * 0.068


## Fala uma linha. Retorna quanto tempo falta para terminar tudo que está na fila.
func dizer(texto: String, quem := "", interromper := false) -> float:
	if interromper:
		parar()
	_fila.append([quem, texto, _duracao(texto)])
	if not _falando and Engine.get_process_frames() > 45:
		_proxima()
	return tempo_restante()


## Fala várias linhas seguidas: [["Macaco", "texto"], ...]
func sequencia(linhas: Array) -> float:
	for l in linhas:
		dizer(String(l[1]), String(l[0]))
	return tempo_restante()


func tempo_restante() -> float:
	var total := _t if _falando else 0.0
	for it in _fila:
		total += float(it[2])
	return total


func ocupado() -> bool:
	return _falando or not _fila.is_empty()


func parar() -> void:
	_fila.clear()
	_falando = false
	_t = 0.0
	_id_atual = -1
	if _tem_tts:
		DisplayServer.tts_stop()
	_painel.visible = false


func _proxima() -> void:
	if _fila.is_empty():
		_falando = false
		_esconder_t = 1.2
		return
	var it: Array = _fila.pop_front()
	var quem: String = it[0]
	var texto: String = it[1]
	_falando = true
	_t = float(it[2])
	var mostrado := texto if quem == "" else quem + ": " + texto
	_label.text = mostrado
	_painel.visible = Game.opcoes.legendas
	if _tem_tts and (Game.opcoes.narracao or menus_abertos > 0):
		_id += 1
		_id_atual = _id
		var falado := texto if quem == "" else quem + ". " + texto
		var tom: float = TONS.get(quem, 1.0)
		DisplayServer.tts_speak(falado, _voz, 85, tom, 1.05, _id, false)
		_t = _t * 3.0  # a voz real avisa quando termina; o tempo é só segurança


func _terminou_fala(id: int) -> void:
	if id == _id_atual and _falando:
		_t = 0.05


func _process(delta: float) -> void:
	if _suporta_tts and not _tem_tts and _buscas < 20:
		_t_busca -= delta
		if _t_busca <= 0.0:
			_t_busca = 0.5
			_buscas += 1
			_procurar_voz()
	# espera um instante na abertura do jogo para a voz do celular ficar pronta
	if not _falando and not _fila.is_empty() and Engine.get_process_frames() > 45:
		_proxima()
	if _falando:
		_t -= delta
		if _t <= 0.0:
			_proxima()
	elif _esconder_t > 0.0:
		_esconder_t -= delta
		if _esconder_t <= 0.0:
			_painel.visible = false
