extends Node2D
## Uma fase do Monkey Adventure. Monta o cenário a partir do mapa em dados.gd,
## move o Macaco, cuida dos bichos, itens, sons de aviso, chefes e da torre final.

const Dados := preload("res://scripts/dados.gd")
const Ent := preload("res://scripts/entidade.gd")
const ChefeS := preload("res://scripts/chefe.gd")
const MacacoS := preload("res://scripts/macaco.gd")
const MenuS := preload("res://scripts/menu.gd")

const G := 1800.0
const V_PULO := -810.0
const LARG_BURACO := 130.0
const LARG_CIPO := 330.0
const LARG_AGUA := 55.0
const VALORES := {"normal": 1, "bronze": 3, "prata": 10}
const SONS_BANANA := {"normal": "plim", "bronze": "plim_bronze", "prata": "plim_prata", "metalica": "metalica", "verde": "azedo"}
const CHAVES_ARTE := ["selva", "rio", "savana", "montanha", "caverna", "fazenda", "cidade", "zoo", "praia", "templo"]
const ARMADILHA_ARTE := ["arm_espinho", "arm_espinho", "arm_espinho", "arm_espinho", "arm_espinho", "arm_espinho", "arm_bueiro", "arm_espinho", "arm_agua_viva", "arm_lanca"]
const ITENS := {
	"b": ["normal", false], "b^": ["normal", true], "z": ["bronze", false], "z^": ["bronze", true],
	"s": ["prata", false], "s^": ["prata", true], "m": ["metalica", false], "v": ["verde", false],
}

signal terminou(resultado: String)

var num := 1
var info: Dictionary = {}
var segs: Array = []
var ents: Array = []
var mac = null
var cam: Camera2D
var hud: Label
var x_fim := 0.0
var checkpoint_x := 130.0
var pausado := false
var em_dialogo := false
var parado := ""            ## "", "jaula", "arena", "torre", "fim"
var chefe = null
var arena_ent = null
var jaula_atual = null
var aliados_fase := 0
var t_aliado := 4.0
var t_passo := 0.0
var t_vento := 8.0
var vento_t := 0.0
var vento_dir := 1.0
var torre_x := 0.0
var torre_passo := 0
var torre_pedra_t := 0.0
var t_total := 0.0
var _fim_t := -1.0
var _resultado := ""
var _avisou_chuva := false
var _avisou_sovaco := false
var _menu_pausa: CanvasLayer = null
var chave_arte := ""
var fundo: Node2D = null
var aliados_no: Node2D = null
# piloto automático (testes)
var _bot_cd := 0.0
var _bot_resp := false


func _ready() -> void:
	info = Dados.FASES[num - 1]
	RenderingServer.set_default_clear_color(info.ceu)
	chave_arte = CHAVES_ARTE[num - 1]
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	if Arte.tem("ceu_" + chave_arte):
		fundo = Node2D.new()
		fundo.z_index = -20
		fundo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(fundo)
		fundo.draw.connect(_desenhar_fundo)
	elif info.get("escuro", false):
		var cm := CanvasModulate.new()
		cm.color = Color(0.45, 0.42, 0.55)
		add_child(cm)
	aliados_no = Node2D.new()
	aliados_no.z_index = 4
	add_child(aliados_no)
	aliados_no.draw.connect(_desenhar_aliados)
	_construir()
	mac = MacacoS.new()
	mac.position = Vector2(80, 0)
	add_child(mac)
	cam = Camera2D.new()
	add_child(cam)
	cam.position = Vector2(mac.position.x + 260, -160)
	cam.make_current()
	_montar_hud()
	if num >= 9:
		aliados_fase = Game.aliados
	Gestos.alvo = self
	Fala.dizer("Fase %d: %s." % [num, info.nome], "Narrador", true)
	queue_redraw()


# =============================================================== montagem

func _seg(x0: float, x1: float, tipo: String) -> void:
	if tipo == "chao" and not segs.is_empty():
		var u: Dictionary = segs[-1]
		if u.tipo == "chao" and abs(u.x1 - x0) < 0.5:
			u.x1 = x1
			return
	segs.append({"x0": x0, "x1": x1, "tipo": tipo, "afunda_t": -1.0, "afundou": false,
		"borda": false, "aviso": false, "continua": false})


func _ent(tipo: String, sub: String, pos: Vector2) -> Ent:
	var e: Ent = Ent.new()
	e.tipo = tipo
	e.sub = sub
	e.position = pos
	add_child(e)
	ents.append(e)
	return e


func _construir() -> void:
	var x := 0.0
	var agua: bool = info.get("agua", false)
	var centro := 0.0
	for tok in String(info.layout).split(" ", false):
		if tok == "_":
			_seg(x, x + 200, "chao")
			centro = x + 100
			x += 200
		elif tok == "B":
			centro = x + LARG_BURACO / 2.0
			x += LARG_BURACO
		elif tok == "C":
			var c := _ent("cipo", "", Vector2(x + LARG_CIPO / 2.0, -175))
			c.w = 20
			centro = x + LARG_CIPO / 2.0
			x += LARG_CIPO
		elif tok == "T":
			_seg(x, x + 260, "tronco")
			centro = x + 130
			x += 260
		elif tok == "F":
			_seg(x, x + 90, "folha")
			centro = x + 45
			x += 90
		elif tok == "~":
			centro = x + LARG_AGUA / 2.0
			x += LARG_AGUA
		elif tok == "P":
			_seg(x, x + 110, "piso")
			centro = x + 55
			x += 110
		elif tok == "H":
			_seg(x, x + 450, "chao")
			var mh := _ent("milharal", "", Vector2(x, 0))
			mh.largura = 450
			mh.z_index = 7
			centro = x + 225
			x += 450
		elif tok == "J":
			_seg(x, x + 160, "chao")
			_ent("jaula", "", Vector2(x + 80, 0))
			centro = x + 80
			x += 160
		elif tok == "FEIRA":
			_seg(x, x + 1000, "chao")
			for i in 30:
				var b := _ent("banana", "normal", Vector2(x + 20 + i * 32, -24))
				b.w = 28
				b.h = 30
			centro = x + 500
			x += 1000
		elif tok == "K":
			_ent("checkpoint", "", Vector2(x, 0))
		elif tok == "a":
			var pa := x + 40
			if agua:
				pa = centro
			else:
				_seg(x, x + 80, "chao")
				x += 80
			var ar := _ent("armadilha", "", Vector2(pa, 0))
			ar.w = 48
			ar.h = 26
			ar.cor = Color(0.75, 0.75, 0.8)
			ar.d = {"sprite": ARMADILHA_ARTE[num - 1]}
		elif tok.begins_with("D:"):
			_ent("dialogo", tok.substr(2), Vector2(x, 0))
		elif tok.begins_with("M:") or tok.begins_with("X:"):
			_seg(x, x + 900, "chao")
			var ae := _ent("arena", tok.substr(2), Vector2(x + 150, 0))
			ae.d = {"final": tok.begins_with("X:")}
			centro = x + 450
			x += 900
		elif tok.begins_with("o:"):
			var po := x + 35
			if agua:
				po = centro
			else:
				_seg(x, x + 70, "chao")
				x += 70
			var nome_o := tok.substr(2)
			var o := _ent("objeto", nome_o, Vector2(po, 0))
			o.d = Dados.OBJETOS.get(nome_o, {"nome": nome_o, "forca": 1})
		elif tok.begins_with("e:"):
			var pe := x + 45
			if agua:
				pe = centro
			else:
				_seg(x, x + 90, "chao")
				x += 90
			_criar_inimigo(tok.substr(2), pe)
		elif ITENS.has(tok):
			var pb := x + 35
			if agua:
				pb = centro
			else:
				_seg(x, x + 70, "chao")
				x += 70
			var it: Array = ITENS[tok]
			var bn := _ent("banana", it[0], Vector2(pb, -150 if it[1] else -24))
			bn.alta = it[1]
			bn.w = 30
			bn.h = 30
		else:
			push_warning("Trecho desconhecido no mapa: " + tok)
	x_fim = x
	_seg(x, x + 1800, "chao")  # chão depois do fim, para não aparecer um buraco atrás do chefe
	for s in segs:
		for s2 in segs:
			if s2 != s and abs(s2.x0 - s.x1) < 1.0:
				s.continua = true


func _criar_inimigo(nome: String, px: float) -> void:
	if not Dados.INIMIGOS.has(nome):
		push_warning("Inimigo desconhecido: " + nome)
		return
	var def: Dictionary = Dados.INIMIGOS[nome]
	var e := _ent("inimigo", nome, Vector2(px, 0))
	e.d = def
	e.mov = def.mov
	e.w = def.w
	e.h = def.h
	e.cor = def.cor
	match e.mov:
		"aereo", "ladrao":
			e.position.y = -75
		"alto":
			e.position.y = -80
		"pulante":
			e.position.y = 40
		"queda":
			e.position.y = -280


func _montar_hud() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 10
	add_child(camada)
	hud = Label.new()
	hud.position = Vector2(20, 12)
	hud.add_theme_font_size_override("font_size", 26)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	hud.add_theme_constant_override("outline_size", 6)
	camada.add_child(hud)


# =============================================================== laço principal

func _process(delta: float) -> void:
	t_total += delta
	_atualizar_hud()
	if pausado:
		return
	if em_dialogo:
		if Game.piloto:
			Fala.parar()
		if Fala.ocupado():
			return
		em_dialogo = false
	if _fim_t >= 0.0:
		_fim_t -= delta
		if _fim_t < 0.0:
			terminou.emit(_resultado)
		return
	if Game.piloto:
		_piloto(delta)
	_mover_macaco(delta)
	_atualizar_segs(delta)
	_atualizar_ents(delta)
	if chefe != null:
		chefe.atualizar(delta)
	if parado == "torre":
		_torre(delta)
	_aliados(delta)
	_vento(delta)
	_camera(delta)


func _atualizar_hud() -> void:
	var txt := "Vida %d   Pontos %d   Bananas %d" % [Game.vida, Game.pontos, Game.na_sacola()]
	if Game.no_sovaco() > 0:
		txt += " (+%d no sovaco)" % Game.no_sovaco()
	if mac.objeto != "":
		txt += "   Segurando: " + String(Dados.OBJETOS.get(mac.objeto, {}).get("nome", mac.objeto))
	if mac.blind_t > 0.0:
		txt += "   Blindado %ds" % ceili(mac.blind_t)
	if aliados_fase > 0:
		txt += "   Aliados %d" % aliados_fase
	txt += "\nFase %d: %s" % [num, info.nome]
	hud.text = txt


# =============================================================== Macaco

func _seg_em(x: float):
	for s in segs:
		if not s.afundou and x >= s.x0 - 8.0 and x <= s.x1 + 8.0:
			return s
	return null


func _mover_macaco(delta: float) -> void:
	var m = mac
	m.tick(delta)
	if parado == "torre" or parado == "fim":
		return
	var vel := Game.velocidade()
	var vx := vel if parado == "" else 0.0
	if vento_t > 0.0 and parado == "":
		vx += 70.0 * vento_dir
	if m.dash_t > 0.0:
		vx = vel * 2.2 if m.dash_dir > 0 else -vel * 1.1
	if m.lanc_t > 0.0:
		vx = max(vx, vel * 1.35)
	# pendurado no cipó
	if m.cipo != null:
		m.cipo_t += delta
		var ang: float = lerp(-0.9, 0.9, clamp(m.cipo_t / 0.8, 0.0, 1.0))
		m.position = m.cipo.position + Vector2(sin(ang), cos(ang)) * 95.0
		if m.cipo_t >= 0.8:
			m.cipo = null
			m.cipo_espera = 0.6
			m.vy = -560.0
			m.lanc_t = 0.6
			m.no_chao = false
		return
	m.position.x += vx * delta
	if parado == "arena" and arena_ent != null:
		m.position.x = clamp(m.position.x, arena_ent.position.x - 120.0, arena_ent.position.x + 200.0)
	m.position.x = max(m.position.x, 20.0)
	# chão e gravidade
	if m.no_chao:
		var s = _seg_em(m.position.x)
		if s == null:
			m.no_chao = false
			m.coyote = 0.11
			m.vy = 0.0
			m.seg_atual = null
		else:
			m.position.y = 0.0
			_pisando(s, delta)
	if not m.no_chao:
		m.vy += G * delta
		var y_antes: float = m.position.y
		m.position.y += m.vy * delta
		if m.vy > 0.0 and y_antes <= 1.0 and m.position.y >= 0.0:
			var s2 = _seg_em(m.position.x)
			if s2 == null:
				s2 = _beirada_a_frente(m.position.x)
				if s2 != null:
					m.position.x = s2.x0 + 6.0
			if s2 != null:
				_aterrissar(s2)
		if m.position.y > 380.0:
			_caiu()
			return
	if m.buffer_pulo > 0.0 and m.no_chao:
		_pular()


## Ajuda de acessibilidade: se o pulo foi um pouco curto, o Macaco agarra a beirada.
func _beirada_a_frente(x: float):
	for s in segs:
		if not s.afundou and s.x0 > x and s.x0 - x <= 45.0:
			return s
	return null


func _aterrissar(s: Dictionary) -> void:
	var m = mac
	m.position.y = 0.0
	m.vy = 0.0
	m.no_chao = true
	m.lanc_t = 0.0
	m.seg_atual = null
	_pisando(s, 0.0)
	if s.tipo == "tronco":
		Sfx.tocar("toc", -4.0)
	elif s.tipo == "chao":
		Sfx.tocar(String(info.passo), -6.0)


func _pisando(s: Dictionary, delta: float) -> void:
	var m = mac
	if m.seg_atual != s:
		m.seg_atual = s
		if (s.tipo == "folha" or s.tipo == "piso") and s.afunda_t < 0.0:
			s.afunda_t = 0.55 if s.tipo == "folha" else 0.75
			Sfx.tocar("papel" if s.tipo == "folha" else "rachado")
			if s.tipo == "folha":
				_dica("folha", "Folha! Ela vai afundar, pule!")
	t_passo -= delta
	if t_passo <= 0.0 and parado == "":
		t_passo = 0.32
		Sfx.tocar("toc" if s.tipo == "tronco" else String(info.passo), -16.0)


func _pular() -> void:
	var m = mac
	if m.cipo != null or parado == "torre" or parado == "fim":
		return
	if m.no_chao or m.coyote > 0.0:
		m.vy = V_PULO
		m.no_chao = false
		m.coyote = 0.0
		m.buffer_pulo = 0.0
		m.seg_atual = null
		Sfx.tocar("pulo", -8.0)
	else:
		m.buffer_pulo = 0.2


func _caiu() -> void:
	var agua: bool = info.get("agua", false)
	Sfx.tocar("splash" if agua else "dano")
	Game.vibrar(300)
	Game.receber_dano(3)
	if Game.vida <= 0:
		_desmaiar(String(info.queda))
		return
	Fala.dizer("%s Vida %d." % [info.queda, Game.vida], "", true)
	var m = mac
	m.position = Vector2(max(checkpoint_x - 70.0, 60.0), 0.0)
	m.vy = 0.0
	m.no_chao = true
	m.cipo = null
	m.seg_atual = null
	m.invuln_t = 1.5
	for s in segs:
		s.afundou = false
		s.afunda_t = -1.0
		if s.x1 > m.position.x:
			s.borda = false
			s.aviso = false
	queue_redraw()


## Recebe dano (de bichos, armadilhas, chefes).
func dano(n: int, motivo: String) -> void:
	if parado == "fim":
		return
	if mac.blind_t > 0.0:
		Sfx.tocar("metalica", -4.0)
		return
	Game.receber_dano(n)
	Sfx.tocar("dano")
	Game.vibrar(250)
	mac.invuln_t = 1.2
	if Game.vida <= 0:
		_desmaiar(motivo)
		return
	var txt := "%s Vida %d." % [motivo, Game.vida]
	if Game.vida <= 4:
		txt += " Vida baixa, pegue bananas!"
	Fala.dizer(txt, "", true)


func _desmaiar(motivo: String) -> void:
	if parado == "fim":
		return
	parado = "fim"
	if Game.piloto:
		print("  [piloto] desmaiou: %s x=%d y=%d no_chao=%s" % [motivo, int(mac.position.x), int(mac.position.y), str(mac.no_chao)])
		for e in ents:
			if e.vivo and e.tipo == "inimigo" and abs(e.position.x - mac.position.x) < 200:
				print("     perto: %s dx=%d y=%d" % [e.sub, int(e.position.x - mac.position.x), int(e.position.y)])
	Sfx.tocar("derrota")
	Game.vibrar(600)
	Fala.dizer(motivo + " O Macaco desmaiou. Vamos tentar a fase de novo!", "", true)
	Game.restaurar_inicio_fase()
	_resultado = "reiniciar"
	_fim_t = 4.0


func dialogo(id: String) -> void:
	var linhas: Array = Dados.DIALOGOS.get(id, [])
	if linhas.is_empty():
		return
	if id == "f9_aliados" and aliados_fase <= 0:
		return
	if not Game.opcoes.dialogos:
		return
	Fala.sequencia(linhas)
	em_dialogo = true


## Fala uma dica só na primeira vez (no jogo inteiro).
func _dica(chave: String, texto: String) -> void:
	if not Game.opcoes.dicas:
		return
	if Game.dicas_ditas.has(chave):
		return
	Game.dicas_ditas[chave] = true
	Fala.dizer(texto)


# =============================================================== cenário

func _atualizar_segs(delta: float) -> void:
	var mudou := false
	for s in segs:
		if s.afunda_t > 0.0:
			s.afunda_t -= delta
			if s.afunda_t <= 0.0:
				s.afundou = true
				mudou = true
				var meio := Vector2((s.x0 + s.x1) / 2.0, 0)
				Sfx.tocar_em("splash" if s.tipo == "folha" else "rachado", meio)
	if mudou:
		queue_redraw()
	# avisos de beirada e buraco
	if parado != "":
		return
	var mx: float = mac.position.x
	var vel := Game.velocidade()
	for s in segs:
		if s.afundou or s.continua or s.x1 < mx or s.x1 - mx > 400.0:
			continue
		var dist: float = s.x1 - mx
		if not s.aviso and dist < 340.0:
			s.aviso = true
			var agua: bool = info.get("agua", false)
			Sfx.tocar_em("splash" if agua else "buraco", Vector2(s.x1 + 50.0, 0), -4.0)
			if agua:
				_dica("agua", "Água à frente! Pule de tronco em tronco.")
			else:
				_dica("buraco", "Buraco à frente! Pule quando ouvir o estalinho.")
		if not s.borda and dist < vel * 0.3 and mac.no_chao:
			s.borda = true
			Sfx.tocar("borda", -2.0)


func _atualizar_ents(delta: float) -> void:
	var mx: float = mac.position.x
	var lista := ents.duplicate()
	for e in lista:
		if not e.vivo:
			continue
		var dx: float = e.position.x - mx
		if dx > 1500.0:
			continue
		match e.tipo:
			"banana":
				_banana(e, dx, delta)
			"inimigo":
				_inimigo(e, dx, delta)
			"armadilha":
				_armadilha(e, dx, delta)
			"objeto":
				_objeto(e, dx, delta)
			"cipo":
				_cipo(e, dx, delta)
			"projetil":
				_projetil(e, delta)
			"fx_chuva":
				e.position.y += 900.0 * delta
				e.rotation += 10.0 * delta
				if e.position.y > 0.0:
					e.vivo = false
			"dialogo":
				if dx <= 0.0:
					e.vivo = false
					dialogo(e.sub)
			"checkpoint":
				if dx <= 0.0 and not e.flag:
					e.flag = true
					checkpoint_x = e.position.x
					Sfx.tocar("checkpoint", -10.0)
			"jaula":
				_jaula(e, dx, delta)
			"arena":
				if dx <= 0.0 and parado == "" and not e.ativo:
					e.ativo = true
					_entrar_arena(e)
			"milharal":
				var dentro: bool = mx >= e.position.x and mx <= e.position.x + e.largura
				if dentro and not mac.no_milharal:
					Sfx.tocar("milho", -6.0)
				mac.no_milharal = dentro
	# limpa o que acabou
	var vivos := []
	for e in ents:
		if e.vivo:
			vivos.append(e)
		elif e.tipo != "jaula" and e.tipo != "checkpoint":
			e.queue_free()
		else:
			vivos.append(e)
	ents = vivos


func _colide(e) -> bool:
	return mac.caixa().intersects(e.caixa())


func _banana(e, dx: float, delta: float) -> void:
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > 0.0 and dx < 330.0:
		e.t_som = 0.9
		var som: String = SONS_BANANA.get(e.sub, "plim")
		if e.sub == "normal" and e.alta:
			som = "plim_alto"
		Sfx.tocar_em(som, e.position, -6.0)
		if e.alta:
			_dica("banana_alta", "Banana no alto! Pule para pegar.")
		elif e.sub == "verde":
			_dica("banana_verde", "Banana verde à frente! Pule por cima.")
		elif e.sub == "metalica":
			_dica("banana_metalica", "Banana metálica à frente! Ela deixa o Macaco blindado.")
	if dx < -60.0:
		return
	if not _colide(e):
		return
	e.vivo = false
	match e.sub:
		"verde":
			Sfx.tocar("azedo")
			dano(2, "Eca! Tá azeda! Banana verde.")
		"metalica":
			Sfx.tocar("metalica")
			mac.blind_t = 8.0
			Game.somar_pontos(5)
			Fala.dizer("Banana metálica! Blindado!", "", true)
		_:
			var valor: int = VALORES.get(e.sub, 1)
			Game.ganhar_banana(valor)
			Sfx.tocar(SONS_BANANA.get(e.sub, "plim"))
			if e.sub == "bronze":
				Fala.dizer("Bronze! Mais 3.", "", true)
			elif e.sub == "prata":
				Fala.dizer("Prata! Mais 10!", "", true)
			if Game.bananas == Game.SACOLA_MAX + 1 and not _avisou_sovaco:
				_avisou_sovaco = true
				Sfx.tocar("sovaco", 0.0)
				Fala.dizer("Sacolinha cheia! Agora vai embaixo do sovaco!")
			elif Game.bananas == Game.CUSTO_CHUVA and not _avisou_chuva:
				_avisou_chuva = true
				Fala.dizer("Dez bananas! A chuva de cascas está pronta: deslize para cima.")


const DICAS_MOV := {
	"chao": "Pule ou jogue casca!", "investida": "Vem correndo! Pule!", "rolante": "Pule!",
	"aereo": "Abaixe!", "alto": "Abaixe!", "pulante": "Pule na hora certa ou jogue casca!",
	"queda": "Desvie para o lado!", "ladrao": "Abaixe, senão ela rouba bananas!",
	"urso": "Pule ou jogue casca! O abraço dele é fatal!",
}


func _inimigo(e, dx: float, delta: float) -> void:
	var def: Dictionary = e.d
	if not e.ativo:
		if dx < 720.0:
			e.ativo = true
			_dica("inimigo_" + e.sub, "%s à frente! %s" % [def.nome, DICAS_MOV.get(e.mov, "")])
		else:
			return
	if e.estado == "escorrega":
		e.t += delta
		e.position.x += 260.0 * delta
		e.rotation += 8.0 * delta
		e.modulate.a = clamp(1.0 - e.t / 0.6, 0.0, 1.0)
		if e.t > 0.6:
			e.vivo = false
		return
	if parado == "jaula" or parado == "arena":
		return
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > -40.0 and dx < 560.0 and e.mov != "queda" and e.mov != "pulante":
		e.t_som = 1.0
		Sfx.tocar_em(String(def.som), e.position, -2.0)
	var vel: float = def.vel
	match e.mov:
		"chao", "urso", "investida", "rolante":
			e.position.x -= vel * delta
		"aereo", "ladrao":
			e.position.x -= vel * delta
			e.position.y = -75.0 + sin(t_total * 4.0 + e.position.x * 0.01) * 6.0
		"pulante":
			e.t += delta
			var c := fmod(e.t, 1.8)
			if c >= 1.3 and not e.flag and dx > -60.0 and dx < 450.0:
				e.flag = true
				Sfx.tocar_em(String(def.som), Vector2(e.position.x, 0), -2.0)
			if c < 0.1:
				e.flag = false
			e.position.y = 40.0 - sin(c / 0.6 * PI) * 180.0 if c < 0.6 else 40.0
		"queda":
			if e.estado == "" and dx < Game.velocidade() * 0.88:
				e.estado = "aviso"
				e.t = 0.0
				Sfx.tocar_em(String(def.som), e.position)
			elif e.estado == "aviso":
				e.t += delta
				if e.t > 0.45:
					e.estado = "caindo"
			elif e.estado == "caindo":
				e.vy += G * delta
				e.position.y += e.vy * delta
				if e.position.y >= -25.0:
					e.position.y = -25.0
					e.estado = "caiu"
					Sfx.tocar_em("estalo", e.position, -6.0)
			elif e.estado == "caiu":
				e.t += delta
				if e.t > 1.5:
					e.vivo = false
			if e.estado != "caindo":
				return
	if dx < -700.0:
		e.vivo = false
		return
	if _colide(e):
		_tocou_inimigo(e)


func _tocou_inimigo(e) -> void:
	if mac.no_milharal:
		return
	if mac.dash_t > 0.0 or mac.invuln_t > 0.0:
		return
	var def: Dictionary = e.d
	# caiu em cima do bicho: ele escorrega e o Macaco quica
	if not mac.no_chao and mac.vy > 0.0 and e.mov != "ladrao" and mac.position.y < e.caixa().position.y + 26.0:
		mac.vy = -480.0
		Sfx.tocar("pulo", -4.0)
		if e.destrutivel():
			_escorregar(e)
		return
	match e.mov:
		"ladrao":
			var perdeu := Game.perder_bananas(2)
			Sfx.tocar_em(String(def.som), e.position)
			mac.invuln_t = 0.8
			e.vivo = false
			Fala.dizer("A gaivota roubou %d bananas!" % perdeu if perdeu > 0 else "A gaivota tentou roubar, mas a sacolinha estava vazia!", "", true)
			return
		"urso":
			if e.position.x < mac.position.x - 4.0:
				return  # o Macaco já passou: o urso só abraça de frente
			Sfx.tocar("rosnado")
			_desmaiar("O urso te abraçou! Acabou!")
			return
	if mac.blind_t > 0.0:
		Sfx.tocar("metalica", -4.0)
		_escorregar(e)
		return
	dano(2, "%s te pegou!" % def.nome)


func _escorregar(e) -> void:
	if e.estado == "escorrega":
		return
	e.estado = "escorrega"
	e.t = 0.0
	Sfx.tocar_em("escorrega", e.position)
	Game.somar_pontos(2)


func _armadilha(e, dx: float, delta: float) -> void:
	var arm: Dictionary = info.armadilha
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > 0.0 and dx < 450.0:
		e.t_som = 1.1
		Sfx.tocar_em(String(arm.som), e.position, -2.0)
		_dica("armadilha_" + String(arm.nome), "%s à frente! Pule!" % arm.nome)
	if mac.invuln_t <= 0.0 and mac.dash_t <= 0.0 and _colide(e):
		dano(2, "%s!" % arm.nome)


func _objeto(e, dx: float, delta: float) -> void:
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > -60.0 and dx < 300.0:
		e.t_som = 1.2
		Sfx.tocar_em("objeto", e.position, -4.0)
		_dica("objeto", "Objeto no chão! Segure o dedo na tela para pegar.")
	if dx < -500.0:
		e.vivo = false


func _cipo(e, dx: float, delta: float) -> void:
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > 0.0 and dx < 420.0:
		e.t_som = 1.0
		Sfx.tocar_em("cipo", e.position, -4.0)
		_dica("cipo", "Cipó à frente! Pule na beirada para se pendurar.")
	var m = mac
	if m.cipo == null and m.cipo_espera <= 0.0 and not m.no_chao and abs(dx) < 80.0 and m.position.y < -40.0:
		m.cipo = e
		m.cipo_t = 0.0
		m.vy = 0.0
		Sfx.tocar("cipo")
		Game.vibrar(60)


func _projetil(e, delta: float) -> void:
	e.position.x += 650.0 * delta
	e.rotation += 12.0 * delta
	e.t += delta
	if e.t > 1.0:
		e.vivo = false
		return
	if chefe != null and not chefe.derrotado and e.position.x >= chefe.position.x - 70.0:
		e.vivo = false
		chefe.atingido(int(e.d.get("forca", 1)))
		return
	for o in ents:
		if not o.vivo or o.tipo != "inimigo" or not o.ativo or o.estado == "escorrega":
			continue
		if o.mov == "queda":
			continue
		if abs(o.position.x - e.position.x) < o.w / 2.0 + 14.0:
			e.vivo = false
			if o.mov == "rolante":
				Sfx.tocar_em("bloqueio", o.position)
			else:
				_escorregar(o)
			return


func _jaula(e, dx: float, delta: float) -> void:
	if e.flag:
		return
	e.t_som -= delta
	if e.t_som <= 0.0 and dx > 0.0 and dx < 420.0:
		e.t_som = 1.0
		Sfx.tocar_em("jaula", e.position, -4.0)
	if parado == "" and dx <= 30.0 and dx > -40.0 and not e.ativo:
		e.ativo = true
		parado = "jaula"
		jaula_atual = e
		dialogo("jaula")
		Fala.dizer("Segure o dedo na tela para abrir a jaula, ou deslize para a direita para seguir.")


func _abrir_jaula() -> void:
	var e = jaula_atual
	if e == null:
		return
	e.flag = true
	e.queue_redraw()
	jaula_atual = null
	parado = ""
	aliados_fase = min(5, aliados_fase + 1)
	Game.aliados = max(Game.aliados, aliados_fase) if num != 8 else aliados_fase
	Sfx.tocar("abrir")
	Sfx.tocar("vitoria", -6.0)
	Game.somar_pontos(5)
	dialogo("aliado_solto")
	if aliados_fase == 5:
		dialogo("aliados_cinco")


func _entrar_arena(e) -> void:
	parado = "arena"
	arena_ent = e
	mac.dash_t = 0.0
	chefe = ChefeS.new()
	chefe.nivel = self
	chefe.id = e.sub
	chefe.position = Vector2(e.position.x + 430.0, 0)
	add_child(chefe)
	chefe.iniciar()


func chefe_derrotado(id: String) -> void:
	var c = chefe
	chefe = null
	get_tree().create_timer(1.6).timeout.connect(c.queue_free)
	var final_da_fase: bool = arena_ent.d.get("final", false)
	if not final_da_fase:
		parado = ""
		arena_ent = null
		return
	if id == "gorila":
		_iniciar_torre()
	else:
		_concluir()


func _concluir() -> void:
	parado = "fim"
	Sfx.tocar("vitoria")
	Game.concluir_fase(num)
	Fala.dizer("Fase concluída! Você tem %d pontos." % Game.pontos, "Narrador")
	em_dialogo = true
	_resultado = "concluida"
	_fim_t = 1.0


# =============================================================== torre final

func _iniciar_torre() -> void:
	parado = "torre"
	torre_x = arena_ent.position.x + 430.0
	torre_passo = 0
	mac.position = Vector2(torre_x - 30.0, 0)
	mac.no_chao = true
	queue_redraw()
	dialogo("torre_inicio")


func _torre_subir() -> void:
	if torre_pedra_t > 0.0:
		Fala.dizer("Desvie primeiro! Deslize para o lado!", "", true)
		return
	torre_passo += 1
	mac.position.y = -torre_passo * 45.0
	Sfx.tocar("escalar", -2.0, 1.0 + torre_passo * 0.08)
	if torre_passo >= 10:
		_topo_da_torre()
		return
	if torre_passo in [3, 6, 8]:
		torre_pedra_t = 1.6
		Sfx.tocar("rachado")
		Fala.dizer("Pedra solta! Deslize para o lado!", "", true)


func _torre(delta: float) -> void:
	if torre_pedra_t > 0.0:
		if mac.dash_t > 0.0:
			torre_pedra_t = 0.0
			Sfx.tocar("ufa")
			Fala.dizer("Ufa! Continue subindo.", "", true)
			return
		torre_pedra_t -= delta
		if torre_pedra_t <= 0.0:
			torre_passo = max(0, torre_passo - 2)
			mac.position.y = -torre_passo * 45.0
			Sfx.tocar("dano")
			Game.vibrar(250)
			Fala.dizer("A pedra te derrubou dois degraus! Suba de novo.", "", true)


func _topo_da_torre() -> void:
	parado = "fim"
	Sfx.tocar("banana_ouro")
	Game.vibrar(800)
	Game.somar_pontos(100)
	queue_redraw()
	dialogo("torre_topo")
	dialogo("final")
	if not Game.opcoes.dialogos:
		Fala.dizer("Você pegou a banana de ouro! O Macaco voltou para a selva como herói.", "Narrador")
		em_dialogo = true
	Game.concluir_fase(num)
	_resultado = "fim"
	_fim_t = 1.5


# =============================================================== ajudas e efeitos

func _aliados(delta: float) -> void:
	if aliados_fase <= 0 or num < 9 or parado != "":
		return
	t_aliado -= delta
	if t_aliado > 0.0:
		return
	t_aliado = max(3.0, 9.0 - aliados_fase)
	for e in ents:
		if e.vivo and e.destrutivel() and e.ativo and e.estado != "escorrega":
			var dx: float = e.position.x - mac.position.x
			if dx > 80.0 and dx < 480.0:
				Sfx.tocar_em("coco", e.position)
				_escorregar(e)
				_dica("aliado_coco", "Seu aliado jogou um coco!")
				return


func _vento(delta: float) -> void:
	if not info.get("vento", false) or parado != "":
		return
	if vento_t > 0.0:
		vento_t -= delta
		return
	t_vento -= delta
	if t_vento <= 0.0:
		t_vento = randf_range(7.0, 11.0)
		vento_t = 1.3
		vento_dir = 1.0 if randf() < 0.6 else -1.0
		Sfx.tocar_em("vento", mac.position + Vector2(-vento_dir * 600.0, -60.0), 0.0)
		_dica("vento", "Vento forte! Ele empurra o Macaco.")


func _chuva_de_cascas() -> void:
	if Game.bananas < Game.CUSTO_CHUVA:
		Fala.dizer("Faltam %d bananas para a chuva de cascas." % (Game.CUSTO_CHUVA - Game.bananas), "", true)
		Sfx.tocar("bloqueio")
		return
	Game.gastar_bananas(Game.CUSTO_CHUVA)
	Sfx.tocar("chuva")
	Game.vibrar(400)
	Fala.dizer("Chuva de cascas!", "Macaco", true)
	for i in 14:
		var fx := _ent("fx_chuva", "", Vector2(mac.position.x + randf_range(-100.0, 900.0), -650.0 - randf() * 300.0))
		fx.z_index = 8
	for e in ents:
		if e.vivo and e.destrutivel() and e.estado != "escorrega":
			var dx: float = e.position.x - mac.position.x
			if dx > -50.0 and dx < 1000.0:
				_escorregar(e)
	if chefe != null:
		chefe.atingido_chuva()


func _jogar() -> void:
	var forca := 1
	var sub := "casca"
	var cor := Color(1, 0.88, 0.2)
	if mac.objeto != "":
		var od: Dictionary = Dados.OBJETOS.get(mac.objeto, {"forca": 1})
		forca = int(od.get("forca", 1))
		cor = od.get("cor", cor)
		sub = mac.objeto
		mac.objeto = ""
	elif not Game.gastar_bananas(1):
		Sfx.tocar("bloqueio")
		Fala.dizer("Sacolinha vazia! Pegue bananas.", "", true)
		return
	Sfx.tocar("jogar")
	var p := _ent("projetil", sub, mac.position + Vector2(24, -40))
	p.d = {"forca": forca, "cor": cor}
	p.z_index = 6


func _pegar() -> void:
	var melhor = null
	var menor := 230.0
	for e in ents:
		if e.vivo and e.tipo == "objeto":
			var dist: float = abs(e.position.x - mac.position.x)
			if dist < menor:
				menor = dist
				melhor = e
	if melhor == null:
		if Game.opcoes.dicas:
			Fala.dizer("Nada para pegar aqui.", "", true)
		return
	mac.objeto = melhor.sub
	melhor.vivo = false
	Sfx.tocar("pegar")
	Fala.dizer("Pegou: %s." % melhor.d.get("nome", melhor.sub), "", true)


func _camera(delta: float) -> void:
	var alvo := Vector2(mac.position.x + 260.0, -160.0)
	if arena_ent != null and (parado == "arena" or chefe != null):
		alvo.x = arena_ent.position.x + 200.0
	if parado == "torre" or (parado == "fim" and torre_x > 0.0):
		alvo = Vector2(torre_x, -160.0 + mac.position.y * 0.9)
	cam.position = cam.position.lerp(alvo, min(1.0, delta * 6.0))
	if fundo != null:
		fundo.queue_redraw()
	aliados_no.queue_redraw()


# =============================================================== gestos e pausa

func gesto(nome: String, direcao: String) -> void:
	if pausado:
		return
	if em_dialogo:
		if nome == "toque" or nome == "toque_duplo":
			Fala.parar()
			em_dialogo = false
		elif nome == "dois_dedos":
			_pausar()
		return
	if parado == "fim":
		return
	match nome:
		"toque":
			_pular()
		"toque_duplo":
			if parado != "torre":
				_jogar()
		"toque_longo":
			if parado == "jaula":
				_abrir_jaula()
			else:
				_pegar()
		"deslize":
			match direcao:
				"cima":
					if parado == "torre":
						_torre_subir()
					else:
						_chuva_de_cascas()
				"baixo":
					if mac.no_chao:
						mac.abaixado_t = 0.8
						Sfx.tocar("abaixar", -4.0)
				"direita", "esquerda":
					if parado == "jaula" and direcao == "direita":
						parado = ""
						jaula_atual = null
						Fala.dizer("Seguindo em frente.", "", true)
						return
					mac.dash_t = 0.35 if direcao == "direita" else 0.4
					mac.dash_dir = 1 if direcao == "direita" else -1
					Sfx.tocar("desviar", -4.0)
		"dois_dedos":
			_pausar()


func situacao() -> String:
	var txt := "Vida %d. Pontos %d. %d bananas na sacolinha" % [Game.vida, Game.pontos, Game.na_sacola()]
	if Game.no_sovaco() > 0:
		txt += " e %d no sovaco" % Game.no_sovaco()
	txt += "."
	if Game.bananas >= Game.CUSTO_CHUVA:
		txt += " Chuva de cascas pronta."
	if mac.objeto != "":
		txt += " Segurando: %s." % Dados.OBJETOS.get(mac.objeto, {}).get("nome", mac.objeto)
	if aliados_fase > 0:
		txt += " Aliados: %d." % aliados_fase
	if mac.blind_t > 0.0:
		txt += " Blindado."
	if chefe != null:
		txt += " %s: faltam %d acertos." % [chefe.d.nome, chefe.hp]
	return txt


func _pausar() -> void:
	if pausado or parado == "fim":
		return
	pausado = true
	Sfx.tocar("menu_ok")
	_menu_pausa = CanvasLayer.new()
	_menu_pausa.layer = 30
	add_child(_menu_pausa)
	var m := MenuS.new()
	m.configurar("Pausa", [
		["Continuar", _retomar],
		["Ouvir a situação de novo", func(): Fala.dizer(situacao(), "", true)],
		["Reiniciar a fase", func(): _sair("reiniciar")],
		["Voltar ao menu principal", func(): _sair("menu")],
	], _retomar, situacao())
	_menu_pausa.add_child(m)


func _retomar() -> void:
	if _menu_pausa != null:
		_menu_pausa.queue_free()
		_menu_pausa = null
	pausado = false
	Gestos.alvo = self
	Fala.dizer("Continuando.", "", true)


func _sair(resultado: String) -> void:
	if _menu_pausa != null:
		_menu_pausa.queue_free()
		_menu_pausa = null
	if resultado == "reiniciar":
		Game.restaurar_inicio_fase()
	Fala.parar()
	terminou.emit(resultado)


# =============================================================== piloto automático (testes)

func _piloto(delta: float) -> void:
	_bot_cd -= delta
	var m = mac
	if parado == "jaula":
		gesto("toque_longo", "")
		return
	if parado == "torre":
		if torre_pedra_t > 0.0:
			if m.dash_t <= 0.0:
				gesto("deslize", "direita")
		elif _bot_cd <= 0.0:
			_bot_cd = 0.3
			gesto("deslize", "cima")
		return
	if chefe != null:
		if chefe.derrotado:
			return
		if chefe.estado == "aviso" and chefe.t < 0.25:
			if not _bot_resp:
				_bot_resp = true
				match chefe.resp:
					"pular":
						gesto("toque", "")
					"abaixar":
						gesto("deslize", "baixo")
					"desviar":
						gesto("deslize", "direita")
		else:
			_bot_resp = false
		if chefe.estado == "tonto" and _bot_cd <= 0.0:
			_bot_cd = 1.2
			if chefe.etapa().get("so_chuva", false) or (Game.bananas >= 12 and randf() < 0.3):
				gesto("deslize", "cima")
			else:
				gesto("toque_duplo", "")
		return
	if parado != "":
		return
	var mx: float = m.position.x
	var s = _seg_em(mx)
	if m.no_chao and s != null:
		if not s.continua and s.x1 - mx < 28.0:
			gesto("toque", "")
		elif s.continua:
			var prox = _seg_em(s.x1 + 10.0)
			if prox != null and prox.tipo == "piso" and s.x1 - mx < 30.0 and s.tipo != "piso":
				gesto("toque", "")
	var vel := Game.velocidade()
	for e in ents:
		if not e.vivo:
			continue
		var dx: float = e.position.x - mx
		if dx < 0.0 or dx > 320.0:
			continue
		match e.tipo:
			"inimigo":
				if not e.ativo or e.estado == "escorrega":
					continue
				var rel: float = vel + float(e.d.vel)
				match e.mov:
					"aereo", "alto", "ladrao":
						if dx < 110.0 + rel * 0.1 and m.abaixado_t <= 0.0:
							gesto("deslize", "baixo")
					"queda":
						if e.estado == "aviso" and m.dash_t <= 0.0:
							gesto("deslize", "direita")
					"pulante":
						if Game.bananas > 0 and dx < 250.0 and _bot_cd <= 0.0:
							_bot_cd = 0.6
							gesto("toque_duplo", "")
					_:
						if dx < 95.0 + rel * 0.15 and m.no_chao:
							gesto("toque", "")
			"armadilha":
				if dx < 85.0 and m.no_chao:
					gesto("toque", "")
			"banana":
				if (e.sub == "verde" or e.alta) and dx < 75.0 and m.no_chao:
					gesto("toque", "")
			"objeto":
				if m.objeto == "" and dx < 100.0:
					gesto("toque_longo", "")


# =============================================================== desenho do cenário

func _draw() -> void:
	if not Arte.tem("chao_" + chave_arte):
		_draw_simples()
		return
	var agua: bool = info.get("agua", false)
	var largura := x_fim + 1600.0
	if agua:
		draw_rect(Rect2(-600, 40, largura, 500), Color(0.08, 0.25, 0.5))
		Arte.preencher(self, "agua", Rect2(-600, 12, largura, 60), true)
	else:
		draw_rect(Rect2(-600, 24, largura, 500), Color(0.04, 0.03, 0.03, 0.92))
	for s in segs:
		if s.afundou:
			continue
		var w: float = s.x1 - s.x0
		match s.tipo:
			"chao":
				Arte.preencher(self, "chao_" + chave_arte, Rect2(s.x0, 0, w, 320), true)
				Arte.preencher(self, "borda_" + chave_arte, Rect2(s.x0 - 3, -14, w + 6, 40), true)
			"tronco":
				Arte.preencher(self, "tronco", Rect2(s.x0, -10, w, 30))
			"folha":
				Arte.preencher(self, "folha", Rect2(s.x0, -8, w, 22))
			"piso":
				Arte.preencher(self, "piso", Rect2(s.x0, 0, w, 320))
	if torre_x > 0.0:
		Arte.desenhar(self, "torre", Vector2(torre_x, 2), "base")
		if parado != "fim":
			Arte.desenhar(self, "banana_ouro", Vector2(torre_x, -545), "centro", 1.6)


## Fundo em camadas: céu fixo, paisagem distante e paisagem próxima com paralaxe.
func _desenhar_fundo() -> void:
	var vis := get_viewport().get_visible_rect().size
	var c := cam.get_screen_center_position()
	Arte.preencher(fundo, "ceu_" + chave_arte, Rect2(c - vis / 2.0, vis))
	_camada(c, vis, "longe_" + chave_arte, 0.2, 40.0)
	_camada(c, vis, "perto_" + chave_arte, 0.5, 14.0)


func _camada(c: Vector2, vis: Vector2, nome: String, f: float, base_y: float) -> void:
	var t := Arte.tamanho(nome)
	var desloc := c.x * (1.0 - f)
	var esq := c.x - vis.x / 2.0 - desloc
	var u: float = floor(esq / t.x) * t.x
	while u < esq + vis.x + t.x:
		Arte.preencher(fundo, nome, Rect2(u + desloc, base_y - t.y, t.x, t.y))
		u += t.x


func _desenhar_aliados() -> void:
	if aliados_fase <= 0 or num < 8 or mac == null:
		return
	for i in aliados_fase:
		var x: float = mac.position.x - 64.0 - i * 36.0
		if parado == "torre" or (parado == "fim" and torre_x > 0.0):
			x = torre_x - 110.0 - i * 36.0
		var y: float = -absf(sin(t_total * 9.0 + i * 1.3)) * 7.0
		Arte.desenhar(aliados_no, "aliado", Vector2(x, y + 2), "base", 0.9)


func _draw_simples() -> void:
	var agua: bool = info.get("agua", false)
	if agua:
		draw_rect(Rect2(-300, 14, x_fim + 1200, 500), Color(0.2, 0.45, 0.8, 0.9))
	else:
		draw_rect(Rect2(-300, 300, x_fim + 1200, 400), Color(0, 0, 0, 0.6))
	var x := 0.0
	while x < x_fim + 600:
		_deco(x)
		x += 380.0
	for s in segs:
		if s.afundou:
			continue
		var w: float = s.x1 - s.x0
		match s.tipo:
			"chao":
				draw_rect(Rect2(s.x0, 0, w, 320), info.chao)
				draw_rect(Rect2(s.x0, 0, w, 12), info.borda)
			"tronco":
				draw_rect(Rect2(s.x0, -6, w, 24), Color(0.45, 0.3, 0.15))
			"folha":
				draw_rect(Rect2(s.x0, -2, w, 14), Color(0.25, 0.7, 0.25))
			"piso":
				draw_rect(Rect2(s.x0, 0, w, 320), info.chao.darkened(0.15))
	if torre_x > 0.0:
		draw_rect(Rect2(torre_x - 60, -500, 120, 500), Color(0.45, 0.38, 0.32))


func _deco(x: float) -> void:
	match String(info.deco):
		"arvore":
			draw_rect(Rect2(x + 40, -260, 26, 260), Color(0.35, 0.22, 0.1, 0.7))
			draw_circle(Vector2(x + 53, -290), 80, Color(0.15, 0.5, 0.2, 0.7))
		"acacia":
			draw_line(Vector2(x + 60, 0), Vector2(x + 70, -200), Color(0.4, 0.28, 0.15, 0.8), 10)
			draw_rect(Rect2(x - 10, -230, 160, 34), Color(0.3, 0.5, 0.2, 0.8))
		"rocha":
			draw_colored_polygon(PackedVector2Array([Vector2(x - 80, 0), Vector2(x + 90, -380), Vector2(x + 260, 0)]), Color(0.55, 0.55, 0.6, 0.6))
			draw_colored_polygon(PackedVector2Array([Vector2(x + 50, -300), Vector2(x + 90, -380), Vector2(x + 130, -300)]), Color(1, 1, 1, 0.8))
		"caverna":
			draw_colored_polygon(PackedVector2Array([Vector2(x, -620), Vector2(x + 30, -470), Vector2(x + 60, -620)]), Color(0.35, 0.3, 0.4))
			draw_circle(Vector2(x + 140, -8), 10, Color(0.3, 1.0, 0.8, 0.9))
			draw_circle(Vector2(x + 160, -6), 7, Color(0.6, 1.0, 0.5, 0.9))
		"celeiro":
			if int(x / 380.0) % 3 == 0:
				draw_rect(Rect2(x, -200, 180, 200), Color(0.7, 0.15, 0.1, 0.8))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 10, -200), Vector2(x + 90, -280), Vector2(x + 190, -200)]), Color(0.5, 0.1, 0.08, 0.8))
			else:
				draw_line(Vector2(x, -40), Vector2(x + 300, -40), Color(0.85, 0.75, 0.55), 6)
				draw_line(Vector2(x, -70), Vector2(x + 300, -70), Color(0.85, 0.75, 0.55), 6)
		"predio":
			var hp := 250.0 + float(int(x) % 3) * 90.0
			draw_rect(Rect2(x, -hp, 220, hp), Color(0.45, 0.47, 0.55, 0.8))
			for j in 4:
				for k in int(hp / 70.0):
					draw_rect(Rect2(x + 20 + j * 50, -hp + 20 + k * 70, 28, 36), Color(1, 0.95, 0.6, 0.6))
		"zoo":
			draw_line(Vector2(x, -110), Vector2(x + 380, -110), Color(0.3, 0.3, 0.3, 0.6), 5)
			for j in 8:
				draw_line(Vector2(x + j * 48, -110), Vector2(x + j * 48, 0), Color(0.3, 0.3, 0.3, 0.6), 4)
		"coqueiro":
			draw_line(Vector2(x + 50, 0), Vector2(x + 90, -260), Color(0.5, 0.35, 0.2, 0.8), 12)
			for a in 5:
				var ang := -PI + a * PI / 4.0
				draw_line(Vector2(x + 90, -260), Vector2(x + 90, -260) + Vector2(cos(ang), sin(ang) * 0.4 + 0.3) * 90.0, Color(0.2, 0.6, 0.25, 0.85), 8)
		"templo":
			draw_rect(Rect2(x + 60, -340, 50, 340), Color(0.55, 0.45, 0.35, 0.7))
			draw_rect(Rect2(x + 40, -360, 90, 24), Color(0.6, 0.5, 0.38, 0.7))
