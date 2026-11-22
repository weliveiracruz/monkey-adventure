extends Control
## Menu acessível, que fala sozinho:
## deslize para a direita ou esquerda para escolher, toque para repetir,
## toque duas vezes para confirmar, dois dedos para voltar.

var titulo := ""
var intro := ""
var itens: Array = []      ## [[texto, Callable], ...]
var voltar = null          ## Callable ou null
var indice := 0
var _alvo_anterior: Object = null
var _labels: Array[Label] = []


func configurar(t: String, lista: Array, cb_voltar = null, texto_intro := "", inicio := 0) -> void:
	titulo = t
	itens = lista
	voltar = cb_voltar
	intro = texto_intro
	indice = clamp(inicio, 0, max(0, lista.size() - 1))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.08, 0.25, 0.12, 0.93)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var caixa := VBoxContainer.new()
	caixa.set_anchors_preset(Control.PRESET_FULL_RECT)
	caixa.offset_left = 80
	caixa.offset_top = 40
	caixa.offset_right = -80
	caixa.add_theme_constant_override("separation", 14)
	add_child(caixa)
	var lt := Label.new()
	lt.text = titulo
	lt.add_theme_font_size_override("font_size", 52)
	lt.add_theme_color_override("font_color", Color(1, 0.86, 0.2))
	caixa.add_child(lt)
	for it in itens:
		var l := Label.new()
		l.text = String(it[0])
		l.add_theme_font_size_override("font_size", 34)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caixa.add_child(l)
		_labels.append(l)
	_alvo_anterior = Gestos.alvo
	Gestos.alvo = self
	_realcar()
	var texto := titulo + ". "
	if intro != "":
		texto += intro + " "
	Fala.dizer(texto + _descricao_atual(), "", true)


func _exit_tree() -> void:
	if Gestos.alvo == self:
		Gestos.alvo = _alvo_anterior if is_instance_valid(_alvo_anterior) else null


func _descricao_atual() -> String:
	if itens.is_empty():
		return ""
	return "%s. %d de %d." % [String(itens[indice][0]), indice + 1, itens.size()]


func _realcar() -> void:
	for i in _labels.size():
		var l := _labels[i]
		if i == indice:
			l.add_theme_color_override("font_color", Color(1, 1, 0.4))
			l.text = "▶ " + String(itens[i][0])
		else:
			l.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
			l.text = "   " + String(itens[i][0])


func _mover(passo: int) -> void:
	if itens.is_empty():
		return
	indice = (indice + passo + itens.size()) % itens.size()
	Sfx.tocar("menu_mover")
	_realcar()
	Fala.dizer(_descricao_atual(), "", true)


func gesto(nome: String, direcao: String) -> void:
	match nome:
		"deslize":
			if direcao == "direita" or direcao == "baixo":
				_mover(1)
			else:
				_mover(-1)
		"toque":
			Fala.dizer(_descricao_atual(), "", true)
		"toque_duplo", "toque_longo":
			if itens.is_empty():
				return
			Sfx.tocar("menu_ok")
			var cb: Callable = itens[indice][1]
			cb.call()
		"dois_dedos":
			if voltar is Callable:
				Sfx.tocar("menu_ok")
				voltar.call()


## Atualiza o texto de uma opção (usado nas Opções).
func mudar_texto(i: int, texto: String) -> void:
	itens[i][0] = texto
	_realcar()
	Fala.dizer(_descricao_atual(), "", true)
