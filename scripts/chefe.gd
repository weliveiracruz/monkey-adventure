extends Node2D
## Luta contra um chefe. O chefe avisa com som antes de cada ataque:
##   som subindo = pular, som descendo = abaixar, dois toques = desviar.
## Depois de alguns ataques ele fica tonto, e aí é a hora de jogar.

const Dados := preload("res://scripts/dados.gd")
const RESPOSTAS := {"pular": "Pule!", "abaixar": "Abaixe!", "desviar": "Desvie!"}

var nivel = null
var id := ""
var d: Dictionary = {}
var hp := 3
var hp_max := 3
var estado := "pausa"
var t := 0.0
var idx := 0
var restantes := 3
var resp := ""
var etapa_atual := -1
var anim := 0.0
var derrotado := false
var _avisou_bloqueio := false


func iniciar() -> void:
	d = Dados.CHEFES[id]
	hp = int(d.hp)
	hp_max = hp
	z_index = 4
	nivel.dialogo(id + "_intro")
	estado = "pausa"
	t = 1.2
	restantes = _n_ataques()
	_checar_etapa()


func etapa() -> Dictionary:
	if d.has("etapas"):
		var lista: Array = d.etapas
		var i: int = clamp(hp_max - hp, 0, lista.size() - 1)
		return lista[i]
	return d


func _checar_etapa() -> void:
	if not d.has("etapas"):
		return
	var lista: Array = d.etapas
	var i: int = clamp(hp_max - hp, 0, lista.size() - 1)
	if i == etapa_atual:
		return
	etapa_atual = i
	var e: Dictionary = lista[i]
	Fala.dizer(String(e.fala), "Narrador")
	if e.get("aliados", false) and nivel.aliados_fase > 0:
		nivel.dialogo("gorila_aliados")
	if e.get("so_chuva", false):
		if Game.bananas < Game.CUSTO_CHUVA:
			Game.bananas = Game.CUSTO_CHUVA
			Game.mudou.emit()
			Sfx.tocar("chuva")
			Fala.dizer("Bananas caíram do teto do templo! A sacolinha está cheia.")
		if nivel.aliados_fase > 0:
			nivel.dialogo("gorila_chuva")


func _n_ataques() -> int:
	if nivel.aliados_fase >= 3 and nivel.num >= 9:
		return 2
	return 3


func atualizar(delta: float) -> void:
	anim += delta
	queue_redraw()
	if derrotado:
		t -= delta
		modulate.a = clamp(t / 1.5, 0.0, 1.0)
		return
	if nivel.em_dialogo:
		return
	t -= delta
	match estado:
		"pausa":
			if t <= 0.0:
				if restantes > 0:
					_atacar()
				else:
					_ficar_tonto()
		"aviso":
			if t <= 0.0:
				_impacto()
		"tonto":
			if t <= 0.0:
				Sfx.tocar_em(String(d.som), global_position)
				Fala.dizer(String(d.nome) + " se recuperou!", "", true)
				estado = "pausa"
				t = 1.0
				restantes = _n_ataques()


func _atacar() -> void:
	var et := etapa()
	var lista: Array = et.ataques
	resp = String(lista[idx % lista.size()])
	idx += 1
	Sfx.tocar_em(String(d.som), global_position)
	Sfx.tocar("resp_" + resp, -2.0)
	if Game.opcoes.dicas:
		Fala.dizer(RESPOSTAS[resp], "", true)
	estado = "aviso"
	t = 1.0 if et.get("rapido", false) else 1.5


func _impacto() -> void:
	var m = nivel.mac
	var ok := false
	match resp:
		"pular":
			ok = m.position.y < -45.0
		"abaixar":
			ok = m.abaixado_t > 0.0
		"desviar":
			ok = m.dash_t > 0.0 or m.ultimo_dash < 0.3
	if ok:
		Sfx.tocar("ufa")
	else:
		nivel.dano(2, String(d.nome) + " te acertou!")
	restantes -= 1
	estado = "pausa"
	t = 0.8


func _ficar_tonto() -> void:
	estado = "tonto"
	t = 4.5
	Sfx.tocar_em("tonto", global_position)
	var et := etapa()
	Fala.dizer(String(et.tonto), "", true)
	if Game.bananas == 0 and nivel.mac.objeto == "" and not et.get("so_chuva", false):
		Game.ganhar_banana(1)
		Game.ganhar_banana(1)
		Sfx.tocar("plim")
		Fala.dizer("Caíram duas bananas pra você!")


## Uma casca ou objeto chegou no chefe.
func atingido(forca: int) -> void:
	if derrotado:
		return
	if estado != "tonto":
		Sfx.tocar_em("bloqueio", global_position)
		if not _avisou_bloqueio:
			_avisou_bloqueio = true
			Fala.dizer("Agora não! Espere ele ficar tonto.", "", true)
		return
	if etapa().get("so_chuva", false):
		Sfx.tocar_em("bloqueio", global_position)
		Fala.dizer("Só a chuva de cascas! Deslize para cima!", "", true)
		return
	_levar(forca)


## A chuva de cascas acerta sempre: dobrado se o chefe estiver tonto.
func atingido_chuva() -> void:
	if derrotado:
		return
	_levar(2 if estado == "tonto" else 1)


func _levar(n: int) -> void:
	hp -= n
	Sfx.tocar_em("acertou", global_position)
	Game.vibrar(200)
	Game.somar_pontos(5)
	if hp <= 0:
		hp = 0
		derrotado = true
		t = 1.5
		Sfx.tocar("vitoria")
		Game.somar_pontos(20)
		nivel.dialogo(id + "_fim")
		nivel.chefe_derrotado(id)
		return
	Fala.dizer("Acertou! Faltam %d." % hp, "", true)
	estado = "pausa"
	t = 1.2
	restantes = _n_ataques()
	_checar_etapa()


func _draw() -> void:
	if d.is_empty():
		return
	var w: float = d.w
	var h: float = d.h
	var base_y := 0.0
	if d.get("voa", false) and estado != "tonto":
		base_y = -150.0 + sin(anim * 3.0) * 15.0
	var tremor := 0.0
	if estado == "aviso":
		tremor = sin(anim * 50.0) * 5.0
	var nome := "chefe_" + id
	var r := Rect2(-w / 2.0 + tremor, base_y - h, w, h)
	if Arte.tem(nome):
		var tam := Arte.tamanho(nome)
		var giro := 0.0
		if estado == "tonto":
			giro = sin(anim * 6.0) * 0.08
		elif estado == "aviso":
			giro = -0.06
		var respira := 1.0 + sin(anim * 3.0) * 0.015
		draw_set_transform(Vector2(tremor, base_y), giro, Vector2(1.0, respira))
		Arte.desenhar(self, nome, Vector2(0, 4), "base")
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		r = Rect2(-tam.x / 2.0, base_y - tam.y, tam.x, tam.y)
	else:
		var c: Color = d.cor
		draw_rect(r, c)
		draw_rect(r, c.darkened(0.5), false, 3.0)
		var olho := Vector2(r.position.x + 22, r.position.y + 24)
		draw_circle(olho, 10, Color.WHITE)
		draw_circle(olho, 5, Color.BLACK)
	if estado == "tonto":
		for i in 3:
			var a := anim * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 40.0, r.position.y - 20 + sin(a) * 10.0), 7, Color(1, 0.95, 0.3))
	var fonte := ThemeDB.fallback_font
	var titulo := "%s  %s" % [d.nome, "♥".repeat(max(hp, 0))]
	var pos_t := Vector2(-w / 2.0, r.position.y - 24)
	draw_string_outline(fonte, pos_t, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color(0, 0, 0, 0.8))
	draw_string(fonte, pos_t, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
