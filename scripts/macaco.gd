extends Node2D
## O herói: o Macaco. Aqui ficam o estado dele e o desenho.

var vy := 0.0
var no_chao := true
var coyote := 0.0
var buffer_pulo := 0.0
var abaixado_t := 0.0
var dash_t := 0.0
var dash_dir := 1
var ultimo_dash := 10.0
var invuln_t := 0.0
var blind_t := 0.0
var cipo = null
var cipo_t := 0.0
var cipo_espera := 0.0
var lanc_t := 0.0
var objeto := ""
var seg_atual = null
var no_milharal := false
var anim := 0.0


func _ready() -> void:
	z_index = 5


func tick(delta: float) -> void:
	anim += delta
	coyote = max(0.0, coyote - delta)
	buffer_pulo = max(0.0, buffer_pulo - delta)
	abaixado_t = max(0.0, abaixado_t - delta)
	invuln_t = max(0.0, invuln_t - delta)
	lanc_t = max(0.0, lanc_t - delta)
	cipo_espera = max(0.0, cipo_espera - delta)
	if dash_t > 0.0:
		dash_t -= delta
		if dash_t <= 0.0:
			ultimo_dash = 0.0
	else:
		ultimo_dash += delta
	if blind_t > 0.0:
		blind_t -= delta
		if blind_t <= 0.0:
			Sfx.tocar("blindagem_fim")
			Fala.dizer("A blindagem acabou.")
	queue_redraw()


func altura() -> float:
	return 35.0 if abaixado_t > 0.0 else 70.0


func caixa() -> Rect2:
	var h := altura()
	return Rect2(position.x - 18, position.y - h, 36, h)


func _draw() -> void:
	var marrom := Color(0.45, 0.28, 0.15)
	var bege := Color(0.85, 0.7, 0.5)
	if invuln_t > 0.0 and int(anim * 14.0) % 2 == 0:
		marrom.a = 0.45
		bege.a = 0.45
	var h := altura()
	var corrida := sin(anim * 16.0) * 6.0 if no_chao else 0.0
	# rabo
	draw_arc(Vector2(-22, -h * 0.45), 16, PI * 0.5, PI * 1.6, 10, marrom, 4)
	# pernas
	draw_line(Vector2(-8, -h * 0.3), Vector2(-8 + corrida, 0), marrom, 7)
	draw_line(Vector2(8, -h * 0.3), Vector2(8 - corrida, 0), marrom, 7)
	# corpo
	draw_rect(Rect2(-16, -h * 0.8, 32, h * 0.55), marrom)
	draw_rect(Rect2(-9, -h * 0.72, 18, h * 0.38), bege)
	# cabeça
	var cab := Vector2(4, -h * 0.85)
	draw_circle(cab, 17, marrom)
	draw_circle(cab + Vector2(-15, -2), 7, marrom)
	draw_circle(cab + Vector2(17, -2), 7, marrom)
	draw_circle(cab + Vector2(3, 5), 10, bege)
	draw_circle(cab + Vector2(-2, -4), 4, Color.WHITE)
	draw_circle(cab + Vector2(9, -4), 4, Color.WHITE)
	draw_circle(cab + Vector2(-1, -4), 2, Color.BLACK)
	draw_circle(cab + Vector2(10, -4), 2, Color.BLACK)
	# sacolinha
	draw_rect(Rect2(-24, -h * 0.55, 12, 14), Color(0.8, 0.6, 0.2))
	# objeto na mão
	if objeto != "":
		draw_circle(Vector2(22, -h * 0.55), 7, Color(0.7, 0.7, 0.7))
	# blindagem
	if blind_t > 0.0:
		draw_arc(Vector2(0, -h * 0.5), 34, 0, TAU, 24, Color(0.8, 0.85, 0.95, 0.8), 4)
	# braço no cipó
	if cipo != null:
		draw_line(Vector2(4, -h * 0.8), to_local(cipo.global_position), marrom, 6)
