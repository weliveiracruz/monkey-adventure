extends Node
## Cena principal: menu, troca de fases e tela final.

const MenuS := preload("res://scripts/menu.gd")
const FaseS := preload("res://scripts/fase.gd")
const Dados := preload("res://scripts/dados.gd")

var atual: Node = null


func _ready() -> void:
	mostrar_menu()


func _notification(what: int) -> void:
	# Botão "voltar" do Android: pausa / volta.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Gestos.enviar("dois_dedos")


func _trocar(n: Node) -> void:
	if atual != null and is_instance_valid(atual):
		atual.queue_free()
	atual = n
	add_child(n)


func _nome_fase(n: int) -> String:
	return String(Dados.FASES[n - 1].nome)


func mostrar_menu(inicio := 0) -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.25, 0.12))
	var itens := []
	if Game.fase > 1 or Game.pontos > 0:
		itens.append(["Continuar: fase %d, %s" % [Game.fase, _nome_fase(Game.fase)], func(): iniciar_fase(Game.fase)])
	itens.append(["Nova aventura", _nova_aventura])
	itens.append(["Escolher fase", _escolher_fase])
	itens.append(["Como jogar", _como_jogar])
	itens.append(["Opções", _opcoes])
	var m := MenuS.new()
	m.configurar("Monkey Adventure", itens, null,
		"A aventura do Macaco atrás da banana de ouro. Deslize para a direita ou para a esquerda para escolher, e toque duas vezes para confirmar.", inicio)
	_trocar(m)


func _nova_aventura() -> void:
	Game.nova_aventura()
	iniciar_fase(1)


func _escolher_fase() -> void:
	var itens := []
	for n in range(1, Game.fase_liberada + 1):
		var num := n
		itens.append(["Fase %d: %s" % [n, _nome_fase(n)], func(): iniciar_fase(num)])
	var m := MenuS.new()
	m.configurar("Escolher fase", itens, mostrar_menu.bind(2), "Fases liberadas: %d." % Game.fase_liberada)
	_trocar(m)


func _como_jogar() -> void:
	var itens := []
	for linha in Dados.COMO_JOGAR:
		itens.append([linha, func(): pass])
	itens.append(["Voltar ao menu", mostrar_menu.bind(3)])
	var m := MenuS.new()
	m.configurar("Como jogar", itens, mostrar_menu.bind(3), "Deslize para a direita para ouvir a próxima dica.")
	_trocar(m)


func _texto_opcao(chave: String) -> String:
	var v: bool = Game.opcoes[chave]
	match chave:
		"narracao":
			return "Narração do jogo: " + ("ligada" if v else "desligada, os menus continuam falando")
		"dialogos":
			return "Diálogos da história: " + ("ligados" if v else "desligados")
		"lenta":
			return "Velocidade do Macaco: " + ("lenta" if v else "normal")
		"dicas":
			return "Dicas faladas: " + ("ligadas" if v else "desligadas")
		"vibrar":
			return "Vibração: " + ("ligada" if v else "desligada")
		"legendas":
			return "Legendas: " + ("ligadas" if v else "desligadas")
	return chave


func _opcoes() -> void:
	var chaves := ["narracao", "dialogos", "lenta", "dicas", "vibrar", "legendas"]
	var itens := []
	var m := MenuS.new()
	for i in chaves.size():
		var ch: String = chaves[i]
		var idx := i
		itens.append([_texto_opcao(ch), func():
			Game.opcoes[ch] = not Game.opcoes[ch]
			Game.salvar()
			if ch == "vibrar":
				Game.vibrar(150)
			m.mudar_texto(idx, _texto_opcao(ch))
		])
	itens.append(["Voltar ao menu", mostrar_menu.bind(4)])
	m.configurar("Opções", itens, mostrar_menu.bind(4), "Toque duas vezes para mudar.")
	_trocar(m)


func iniciar_fase(n: int) -> void:
	Game.iniciar_fase(n)
	var f := FaseS.new()
	f.num = n
	f.terminou.connect(_fim_fase.bind(n))
	_trocar.call_deferred(f)


func _fim_fase(resultado: String, n: int) -> void:
	match resultado:
		"concluida":
			if n < Game.TOTAL_FASES:
				iniciar_fase(n + 1)
			else:
				_mostrar_fim.call_deferred()
		"reiniciar":
			iniciar_fase(n)
		"fim":
			_mostrar_fim.call_deferred()
		_:
			mostrar_menu.call_deferred()


func _mostrar_fim() -> void:
	RenderingServer.set_default_clear_color(Color(0.1, 0.3, 0.1))
	var m := MenuS.new()
	m.configurar("Você venceu!", [["Voltar ao menu", mostrar_menu], ["Jogar de novo desde o começo", _nova_aventura]], mostrar_menu,
		"O Macaco recuperou a banana de ouro! Você fez %d pontos e soltou %d macacos." % [Game.pontos, Game.aliados])
	_trocar(m)
