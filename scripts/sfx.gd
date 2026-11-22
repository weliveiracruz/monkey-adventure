extends Node
## Sons do jogo, todos sintetizados por código (não precisa de arquivos de áudio).
## Cada elemento do jogo tem um som próprio, e os sons das coisas do cenário
## saem posicionados: à esquerda, à direita ou à frente do Macaco.

const TAXA := 22050

var _cache := {}
var _def := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool2d: Array[AudioStreamPlayer2D] = []
var _i := 0
var _i2 := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_definir()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for i in 14:
		var p2 := AudioStreamPlayer2D.new()
		p2.max_distance = 1500.0
		p2.attenuation = 1.2
		p2.panning_strength = 1.6
		add_child(p2)
		_pool2d.append(p2)


## Toca um som sem posição (interface, Macaco).
func tocar(nome: String, vol_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(nome)
	if s == null:
		return
	var p := _pool[_i]
	_i = (_i + 1) % _pool.size()
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()


## Toca um som numa posição do mundo (sai pelo lado em que a coisa está).
func tocar_em(nome: String, pos: Vector2, vol_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(nome)
	if s == null:
		return
	var p := _pool2d[_i2]
	_i2 = (_i2 + 1) % _pool2d.size()
	p.stream = s
	p.global_position = pos
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()


func existe(nome: String) -> bool:
	return _def.has(nome)


func _stream(nome: String) -> AudioStreamWAV:
	if _cache.has(nome):
		return _cache[nome]
	if not _def.has(nome):
		push_warning("Som desconhecido: " + nome)
		return null
	var s := _gerar(_def[nome])
	_cache[nome] = s
	return s


# ---------------------------------------------------------------- síntese

## Uma parte de um som: frequência inicial e final, duração, forma de onda,
## volume, atraso e tremolo.
func p(f0: float, f1: float, d: float, onda := "sen", v := 0.6, ini := 0.0, trem := 0.0) -> Dictionary:
	return {"f0": f0, "f1": f1, "d": d, "onda": onda, "v": v, "ini": ini, "trem": trem}


## Repete uma parte várias vezes com intervalo.
func rep(parte: Dictionary, vezes: int, intervalo: float) -> Array:
	var r := []
	for k in vezes:
		var c := parte.duplicate()
		c.ini = parte.ini + k * intervalo
		r.append(c)
	return r


## Sequência de notas (arpejo).
func notas(freqs: Array, d: float, onda := "sen", v := 0.5, intervalo := -1.0) -> Array:
	var r := []
	if intervalo < 0:
		intervalo = d * 0.9
	for k in freqs.size():
		r.append(p(freqs[k], freqs[k], d, onda, v, k * intervalo))
	return r


func _gerar(partes: Array) -> AudioStreamWAV:
	var total := 0.0
	for pa in partes:
		total = max(total, pa.ini + pa.d)
	var n := int(total * TAXA) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	for pa in partes:
		var i0 := int(pa.ini * TAXA)
		var len_ := int(pa.d * TAXA)
		var fase := 0.0
		var ruido := 0.0
		var a: float = clamp(pa.f0 / TAXA * 6.0, 0.02, 1.0)
		for k in len_:
			var t := float(k) / TAXA
			var prog: float = t / pa.d
			var f: float = lerp(pa.f0, pa.f1, prog)
			fase += f / TAXA
			fase -= floor(fase)
			var x := 0.0
			match pa.onda:
				"sen":
					x = sin(fase * TAU)
				"quad":
					x = 1.0 if fase < 0.5 else -1.0
				"serra":
					x = fase * 2.0 - 1.0
				"ruido":
					ruido += (randf() * 2.0 - 1.0 - ruido) * a
					x = ruido * 2.2
			var env: float = min(1.0, t / 0.006) * pow(1.0 - prog, 0.7)
			if pa.trem > 0.0:
				env *= 0.55 + 0.45 * sin(t * TAU * pa.trem)
			var idx := i0 + k
			if idx < n:
				buf[idx] += x * env * pa.v
	var dados := PackedByteArray()
	dados.resize(n * 2)
	for k in n:
		dados.encode_s16(k * 2, int(clamp(buf[k], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = TAXA
	s.stereo = false
	s.data = dados
	return s


func _definir() -> void:
	var D := _def
	# --- bananas e itens
	D["plim"] = [p(1320, 1760, 0.12)]
	D["plim_alto"] = [p(1760, 2350, 0.12)]
	D["plim_bronze"] = [p(880, 880, 0.1), p(1320, 1320, 0.14, "sen", 0.6, 0.09)]
	D["plim_prata"] = notas([1320, 1760, 2093], 0.1, "sen", 0.6, 0.07)
	D["metalica"] = [p(440, 440, 0.45, "quad", 0.3, 0.0, 30.0), p(660, 660, 0.45, "quad", 0.2, 0.0, 30.0)]
	D["azedo"] = [p(200, 190, 0.35, "serra", 0.35), p(213, 203, 0.35, "serra", 0.35)]
	D["sovaco"] = [p(85, 70, 0.45, "quad", 0.45, 0.0, 22.0)]
	D["banana_ouro"] = notas([523, 659, 784, 1047, 1319, 1568], 0.16, "sen", 0.5, 0.12) + [p(2600, 3200, 1.0, "sen", 0.2, 0.6, 10.0)]
	# --- Macaco
	D["passo"] = [p(160, 90, 0.04, "sen", 0.22)]
	D["passo_eco"] = [p(160, 90, 0.04, "sen", 0.22), p(160, 90, 0.04, "sen", 0.09, 0.14), p(160, 90, 0.04, "sen", 0.04, 0.28)]
	D["pulo"] = [p(400, 700, 0.08, "sen", 0.25)]
	D["toc"] = [p(320, 140, 0.07, "sen", 0.8)]
	D["papel"] = [p(3000, 3000, 0.28, "ruido", 0.35, 0.0, 18.0)]
	D["splash"] = [p(1500, 300, 0.35, "ruido", 0.5)]
	D["buraco"] = [p(400, 200, 0.5, "ruido", 0.35)]
	D["borda"] = [p(2200, 2200, 0.03, "quad", 0.35)]
	D["cipo"] = [p(180, 260, 0.35, "serra", 0.3, 0.0, 12.0)]
	D["jogar"] = [p(800, 2400, 0.15, "ruido", 0.35)]
	D["escorrega"] = [p(1000, 180, 0.45, "sen", 0.5)]
	D["dano"] = [p(220, 110, 0.3, "quad", 0.4)]
	D["abaixar"] = [p(500, 300, 0.08, "sen", 0.25)]
	D["desviar"] = [p(500, 1500, 0.12, "ruido", 0.25)]
	D["chuva"] = notas([2093, 1760, 1568, 1319, 1175, 1047, 880, 784], 0.12, "sen", 0.4, 0.08)
	D["vitoria"] = notas([523, 659, 784, 1047], 0.16, "sen", 0.5, 0.14)
	D["derrota"] = notas([392, 330, 262], 0.25, "serra", 0.35, 0.22)
	D["checkpoint"] = [p(660, 660, 0.08), p(990, 990, 0.12, "sen", 0.6, 0.08)]
	D["objeto"] = [p(1800, 2200, 0.06, "sen", 0.35), p(2200, 1800, 0.06, "sen", 0.35, 0.08)]
	D["pegar"] = [p(600, 1200, 0.1, "quad", 0.3)]
	D["jaula"] = [p(400, 400, 0.25, "quad", 0.25, 0.0, 8.0)]
	D["abrir"] = [p(300, 900, 0.3, "serra", 0.35)]
	D["escalar"] = [p(500, 700, 0.1, "sen", 0.4)]
	D["milho"] = [p(2500, 2500, 0.3, "ruido", 0.2, 0.0, 12.0)]
	D["vento"] = [p(300, 700, 0.9, "ruido", 0.35, 0.0, 2.0)]
	D["blindagem_fim"] = [p(660, 330, 0.3, "quad", 0.25)]
	# --- combate com chefes
	D["tonto"] = [p(500, 700, 0.8, "sen", 0.4, 0.0, 6.0)]
	D["acertou"] = [p(300, 600, 0.1, "quad", 0.45), p(900, 900, 0.15, "sen", 0.5, 0.08)]
	D["bloqueio"] = [p(150, 150, 0.15, "quad", 0.4)]
	D["ufa"] = [p(600, 300, 0.2, "ruido", 0.25)]
	D["resp_pular"] = [p(300, 900, 0.35, "sen", 0.5)]
	D["resp_abaixar"] = [p(1400, 400, 0.35, "sen", 0.5)]
	D["resp_desviar"] = [p(700, 700, 0.08, "quad", 0.4), p(700, 700, 0.08, "quad", 0.4, 0.15)]
	# --- menu
	D["menu_mover"] = [p(900, 900, 0.04, "sen", 0.3)]
	D["menu_ok"] = [p(700, 1400, 0.12, "sen", 0.4)]
	# --- avisos dos bichos e perigos
	D["chocalho"] = [p(5000, 5000, 0.45, "ruido", 0.35, 0.0, 25.0)]
	D["riso_macaco"] = [p(700, 700, 0.07, "quad", 0.3), p(900, 900, 0.07, "quad", 0.3, 0.09), p(700, 700, 0.07, "quad", 0.3, 0.18), p(1000, 1000, 0.09, "quad", 0.3, 0.27)]
	D["pio"] = [p(620, 520, 0.25, "sen", 0.5), p(560, 480, 0.35, "sen", 0.5, 0.35)]
	D["papagaio"] = [p(1800, 1200, 0.15, "quad", 0.3), p(1600, 1100, 0.15, "quad", 0.3, 0.2)]
	D["piranha"] = [p(1200, 400, 0.2, "ruido", 0.4), p(200, 200, 0.06, "quad", 0.4, 0.22)]
	D["bolhas"] = [p(300, 500, 0.05, "sen", 0.4), p(350, 600, 0.05, "sen", 0.4, 0.12), p(280, 520, 0.05, "sen", 0.4, 0.25), p(400, 700, 0.05, "sen", 0.4, 0.36)]
	D["galope"] = rep(p(150, 100, 0.05, "sen", 0.6), 4, 0.13)
	D["hiena"] = rep(p(1100, 1300, 0.08, "quad", 0.3), 5, 0.1)
	D["trombeta"] = [p(320, 520, 0.6, "serra", 0.45, 0.0, 5.0)]
	D["rugido"] = [p(140, 90, 0.8, "serra", 0.4, 0.0, 9.0), p(400, 200, 0.8, "ruido", 0.3)]
	D["rugido_curto"] = [p(200, 130, 0.4, "serra", 0.4, 0.0, 10.0)]
	D["rolando"] = [p(120, 80, 0.6, "ruido", 0.5)]
	D["balido"] = [p(520, 480, 0.45, "serra", 0.3, 0.0, 11.0)]
	D["grito_aguia"] = [p(2100, 1500, 0.4, "sen", 0.4)]
	D["rosnado"] = [p(95, 85, 0.7, "serra", 0.45, 0.0, 14.0)]
	D["grito_gaviao"] = [p(2800, 2000, 0.3, "quad", 0.25), p(2800, 2000, 0.3, "quad", 0.25, 0.35)]
	D["estalo"] = [p(4000, 4000, 0.05, "ruido", 0.6), p(2000, 2000, 0.04, "quad", 0.3, 0.06)]
	D["fio"] = [p(1300, 400, 0.6, "sen", 0.25)]
	D["guincho"] = rep(p(3200, 3400, 0.06, "quad", 0.22), 4, 0.09)
	D["cacarejo"] = rep(p(750, 650, 0.08, "quad", 0.3), 4, 0.1)
	D["bode"] = [p(420, 380, 0.4, "serra", 0.35, 0.0, 9.0)]
	D["latido"] = [p(420, 260, 0.1, "quad", 0.45), p(420, 260, 0.1, "quad", 0.45, 0.2)]
	D["bufa"] = [p(600, 300, 0.5, "ruido", 0.5), p(90, 70, 0.5, "serra", 0.3)]
	D["buzina"] = [p(440, 440, 0.4, "quad", 0.3), p(554, 554, 0.4, "quad", 0.3)]
	D["campainha"] = [p(2500, 2500, 0.3, "sen", 0.35, 0.0, 25.0)]
	D["pombo"] = [p(400, 420, 0.3, "sen", 0.3, 0.0, 12.0)]
	D["chiado"] = [p(6000, 6000, 0.4, "ruido", 0.3)]
	D["rede"] = [p(800, 1600, 0.5, "ruido", 0.3, 0.0, 6.0)]
	D["apito"] = [p(2800, 2800, 0.35, "sen", 0.35, 0.0, 40.0)]
	D["flamingo"] = [p(900, 800, 0.12, "quad", 0.3), p(900, 800, 0.12, "quad", 0.3, 0.16)]
	D["pinguim"] = [p(900, 300, 0.4, "sen", 0.4)]
	D["clique"] = rep(p(3000, 3000, 0.02, "quad", 0.4), 4, 0.08)
	D["gaivota"] = [p(1600, 1000, 0.2, "sen", 0.35), p(1500, 900, 0.2, "sen", 0.35, 0.25)]
	D["agua_viva"] = [p(600, 900, 0.15, "sen", 0.3), p(500, 800, 0.15, "sen", 0.25, 0.18)]
	D["onda"] = [p(200, 800, 0.6, "ruido", 0.4)]
	D["casco"] = [p(110, 90, 0.6, "sen", 0.5, 0.0, 8.0)]
	D["babuino"] = rep(p(800, 600, 0.06, "quad", 0.3), 3, 0.1)
	D["gorila"] = rep(p(80, 70, 0.12, "sen", 0.8), 4, 0.18)
	D["lanca"] = [p(2500, 1800, 0.08, "quad", 0.35), p(3000, 3000, 0.04, "quad", 0.2, 0.1)]
	D["rachado"] = [p(1500, 800, 0.3, "ruido", 0.5, 0.0, 30.0)]
	D["espinho"] = [p(1800, 1800, 0.05, "quad", 0.3), p(1500, 1500, 0.05, "quad", 0.3, 0.08)]
	D["rinoceronte"] = [p(100, 80, 0.6, "serra", 0.45), p(500, 250, 0.5, "ruido", 0.35)]
	D["coco"] = [p(250, 150, 0.08, "sen", 0.6)]
