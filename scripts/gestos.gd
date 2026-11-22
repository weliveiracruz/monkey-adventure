extends Node
## Reconhece os gestos na tela e manda para quem está ativo (menu ou fase).
##   toque        -> pular / repetir opção do menu
##   toque_duplo  -> jogar casca ou objeto / confirmar no menu
##   toque_longo  -> pegar objeto do chão / abrir jaula
##   deslize      -> "direita", "esquerda", "cima", "baixo"
##   dois_dedos   -> pausa e situação do Macaco
## No computador: Espaço = toque, X ou Enter = toque duplo, Z = toque longo,
## setas = deslizes, Esc ou P = pausa.

const DIST_DESLIZE := 70.0
const TEMPO_LONGO := 0.35
const TEMPO_DUPLO := 0.28

## Objeto que recebe os gestos. Precisa ter o método gesto(nome, direcao).
var alvo: Object = null

var _ini_pos := Vector2.ZERO
var _ini_t := 0.0
var _pressionado := false
var _consumido := false
var _ultimo_toque := -10.0
var _dedos := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _agora() -> float:
	return Time.get_ticks_msec() / 1000.0


func enviar(nome: String, direcao := "") -> void:
	if is_instance_valid(alvo) and alvo.has_method("gesto"):
		alvo.gesto(nome, direcao)


func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		_toque_tela(ev)
	elif ev is InputEventScreenDrag:
		if ev.index == 0 and _pressionado and not _consumido:
			var d: Vector2 = ev.position - _ini_pos
			if d.length() >= DIST_DESLIZE:
				_consumido = true
				enviar("deslize", _direcao(d))
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		_tecla(ev.keycode)


func _toque_tela(ev: InputEventScreenTouch) -> void:
	if ev.pressed:
		_dedos[ev.index] = true
		if _dedos.size() >= 2:
			_consumido = true
			enviar("dois_dedos")
			return
		if ev.index == 0:
			_ini_pos = ev.position
			_ini_t = _agora()
			_pressionado = true
			_consumido = false
	else:
		_dedos.erase(ev.index)
		if ev.index != 0 or not _pressionado:
			return
		_pressionado = false
		if _consumido:
			return
		var d: Vector2 = ev.position - _ini_pos
		if d.length() >= DIST_DESLIZE:
			enviar("deslize", _direcao(d))
			return
		var t := _agora()
		if t - _ultimo_toque <= TEMPO_DUPLO:
			_ultimo_toque = -10.0
			enviar("toque_duplo")
		else:
			_ultimo_toque = t
			enviar("toque")


func _direcao(d: Vector2) -> String:
	if abs(d.x) >= abs(d.y):
		return "direita" if d.x > 0 else "esquerda"
	return "baixo" if d.y > 0 else "cima"


func _tecla(k: int) -> void:
	match k:
		KEY_SPACE:
			enviar("toque")
		KEY_X, KEY_ENTER, KEY_KP_ENTER:
			enviar("toque_duplo")
		KEY_Z:
			enviar("toque_longo")
		KEY_RIGHT:
			enviar("deslize", "direita")
		KEY_LEFT:
			enviar("deslize", "esquerda")
		KEY_UP:
			enviar("deslize", "cima")
		KEY_DOWN:
			enviar("deslize", "baixo")
		KEY_ESCAPE, KEY_P:
			enviar("dois_dedos")


func _process(_delta: float) -> void:
	if _pressionado and not _consumido and _agora() - _ini_t >= TEMPO_LONGO:
		_consumido = true
		enviar("toque_longo")
