extends Node
## Carrega e desenha as ilustrações da pasta arte/ (geradas por ferramentas/gerar_arte.py).

const ArteInfo := preload("res://scripts/arte_info.gd")

var _tex := {}


func tem(nome: String) -> bool:
	return ArteInfo.INFO.has(nome)


func tex(nome: String) -> Texture2D:
	if _tex.has(nome):
		return _tex[nome]
	var t: Texture2D = null
	var caminho := "res://arte/%s.svg" % nome
	if tem(nome) and ResourceLoader.exists(caminho):
		t = load(caminho)
	_tex[nome] = t
	return t


func tamanho(nome: String) -> Vector2:
	var i: Dictionary = ArteInfo.INFO.get(nome, {})
	if i.is_empty():
		return Vector2(32, 32)
	return Vector2(float(i.w), float(i.h))


## Desenha a ilustração num CanvasItem. ancora: "base" (pé na posição), "centro" ou "topo".
func desenhar(ci: CanvasItem, nome: String, pos: Vector2, ancora := "", escala := 1.0, espelhar := false, cor := Color.WHITE) -> bool:
	var t := tex(nome)
	if t == null:
		return false
	var s := tamanho(nome) * escala
	var a: String = ancora
	if a == "":
		a = String(ArteInfo.INFO.get(nome, {}).get("ancora", "centro"))
	var r: Rect2
	match a:
		"base":
			r = Rect2(pos.x - s.x / 2.0, pos.y - s.y, s.x, s.y)
		"topo":
			r = Rect2(pos.x - s.x / 2.0, pos.y, s.x, s.y)
		_:
			r = Rect2(pos - s / 2.0, s)
	if espelhar:
		r.position.x += r.size.x
		r.size.x = -r.size.x
	ci.draw_texture_rect(t, r, false, cor)
	return true


## Desenha a textura esticada num retângulo (repete se `repetir`).
func preencher(ci: CanvasItem, nome: String, r: Rect2, repetir := false, cor := Color.WHITE) -> bool:
	var t := tex(nome)
	if t == null:
		return false
	ci.draw_texture_rect(t, r, repetir, cor)
	return true
