extends Node2D
## Qualquer coisa do cenário: banana, inimigo, objeto, cipó, jaula, armadilha...
## A lógica fica na fase; aqui ficam os dados e o desenho.

var tipo := ""
var sub := ""
var d: Dictionary = {}
var vivo := true
var ativo := false
var estado := ""
var t := 0.0
var t_som := 0.0
var vy := 0.0
var w := 30.0
var h := 30.0
var mov := ""
var cor := Color.WHITE
var alta := false
var flag := false
var largura := 0.0


## Caixa de colisão. Coisas que voam têm o centro na posição; as do chão têm a base.
func caixa() -> Rect2:
	if tipo == "banana" or mov in ["aereo", "alto", "pulante", "queda", "ladrao"]:
		return Rect2(position.x - w / 2.0, position.y - h / 2.0, w, h)
	return Rect2(position.x - w / 2.0, position.y - h, w, h)


func destrutivel() -> bool:
	return tipo == "inimigo" and not (mov in ["rolante", "queda"])


func _draw() -> void:
	match tipo:
		"banana":
			_banana()
		"inimigo":
			_inimigo()
		"objeto", "projetil":
			if sub == "casca":
				draw_arc(Vector2.ZERO, 10, 0.4, PI - 0.4, 8, Color(1, 0.88, 0.2), 6)
			else:
				var c: Color = d.get("cor", Color(0.6, 0.6, 0.6))
				draw_circle(Vector2(0, -8) if tipo == "objeto" else Vector2.ZERO, 9, c)
				draw_arc(Vector2(0, -8) if tipo == "objeto" else Vector2.ZERO, 9, 0, TAU, 12, Color(0, 0, 0, 0.5), 2)
		"armadilha":
			for i in 4:
				var x0 := -24.0 + i * 12.0
				draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 6, -28), Vector2(x0 + 12, 0)]), cor)
		"cipo":
			draw_line(Vector2(0, -420), Vector2(0, 0), Color(0.2, 0.55, 0.15), 5)
			draw_circle(Vector2(0, 0), 8, Color(0.25, 0.6, 0.2))
			for i in 6:
				draw_circle(Vector2(6 if i % 2 == 0 else -6, -60.0 * i - 20), 7, Color(0.3, 0.7, 0.25))
		"jaula":
			draw_rect(Rect2(-55, -120, 110, 120), Color(0.3, 0.3, 0.3, 0.25))
			if not flag:
				draw_circle(Vector2(0, -45), 20, Color(0.45, 0.28, 0.15))
				draw_circle(Vector2(0, -75), 14, Color(0.45, 0.28, 0.15))
				for i in 7:
					var x := -55.0 + i * 18.3
					draw_line(Vector2(x, -120), Vector2(x, 0), Color(0.25, 0.25, 0.28), 4)
			draw_rect(Rect2(-58, -124, 116, 8), Color(0.25, 0.25, 0.28))
		"milharal":
			var n := int(largura / 26.0)
			for i in n:
				var x := 13.0 + i * 26.0
				draw_line(Vector2(x, 0), Vector2(x + sin(i) * 4.0, -150), Color(0.45, 0.65, 0.2), 5)
				draw_circle(Vector2(x + 4, -110), 7, Color(0.95, 0.8, 0.25))
		"checkpoint":
			draw_line(Vector2(0, 0), Vector2(0, -90), Color(0.9, 0.9, 0.9), 3)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -90), Vector2(34, -78), Vector2(0, -66)]), Color(1, 0.85, 0.2))
		"fx_chuva":
			draw_arc(Vector2.ZERO, 12, 0.4, PI - 0.4, 8, Color(1, 0.88, 0.2), 6)


func _banana() -> void:
	var c := Color(1, 0.88, 0.2)
	match sub:
		"bronze":
			c = Color(0.8, 0.5, 0.2)
		"prata":
			c = Color(0.88, 0.88, 0.95)
		"metalica":
			c = Color(0.55, 0.62, 0.72)
		"verde":
			c = Color(0.35, 0.75, 0.2)
	for i in 3:
		draw_arc(Vector2(i * 6 - 6, 0), 13, 0.3, PI - 0.3, 10, c, 6)
	if sub == "metalica" or sub == "prata":
		draw_circle(Vector2(8, -8), 3, Color.WHITE)


func _inimigo() -> void:
	var r: Rect2
	if mov in ["aereo", "alto", "pulante", "queda", "ladrao"]:
		r = Rect2(-w / 2.0, -h / 2.0, w, h)
	else:
		r = Rect2(-w / 2.0, -h, w, h)
	if mov == "alto":
		draw_line(Vector2(0, -h / 2.0), Vector2(0, -400), Color(0.9, 0.9, 0.9, 0.6), 1)
	if mov in ["aereo", "ladrao"]:
		var asa := sin(Time.get_ticks_msec() / 70.0) * 12.0
		draw_line(Vector2(-4, 0), Vector2(-w * 0.7, -asa), cor.darkened(0.2), 5)
		draw_line(Vector2(4, 0), Vector2(w * 0.7, -asa), cor.darkened(0.2), 5)
	if mov == "queda":
		draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, -h / 2.0), Vector2(w / 2.0, -h / 2.0), Vector2(0, h / 2.0)]), cor)
		return
	if mov == "rolante":
		draw_rect(r, cor)
		draw_circle(Vector2(-w * 0.3, 0), 9, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(w * 0.3, 0), 9, Color(0.1, 0.1, 0.1))
		return
	draw_rect(r, cor)
	draw_rect(r, cor.darkened(0.4), false, 2.0)
	var olho := Vector2(r.position.x + 8, r.position.y + 8)
	draw_circle(olho, 5, Color.WHITE)
	draw_circle(olho, 2.5, Color.BLACK)
	if sub == "zebra":
		for i in 4:
			draw_line(Vector2(-w / 2.0 + 14 + i * 14, -h), Vector2(-w / 2.0 + 10 + i * 14, 0), Color.BLACK, 4)
