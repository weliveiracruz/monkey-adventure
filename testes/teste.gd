extends Node
## Teste automático: o "piloto" joga as 10 fases sozinho e confere se nada quebra.
## Rodar:  godot --headless --fixed-fps 60 --path . res://testes/teste.tscn

const FaseS := preload("res://scripts/fase.gd")

var fase_atual := 1
var f = null
var frames := 0
var tentativas := 0
var resultados := []
const MAX_FRAMES := 60 * 60 * 12


func _ready() -> void:
	Game.piloto = true
	Game.nova_aventura()
	var inicio := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fase="):
			inicio = int(a.substr(7))
	_iniciar(inicio)


func _iniciar(n: int) -> void:
	fase_atual = n
	frames = 0
	Game.iniciar_fase(n)
	f = FaseS.new()
	f.num = n
	f.terminou.connect(_terminou)
	add_child(f)


func _terminou(res: String) -> void:
	var dados := "fase %d -> %s | %d s de jogo | vida %d | pontos %d | bananas %d | aliados %d | dano %d" % [
		fase_atual, res, int(frames / 60.0), Game.vida, Game.pontos, Game.bananas, Game.aliados, Game.dano_recebido_teste]
	print(dados)
	resultados.append(res)
	Game.dano_recebido_teste = 0
	f.queue_free()
	f = null
	if res == "reiniciar":
		tentativas += 1
		if tentativas > 3:
			print("FALHOU: muitas tentativas na fase %d" % fase_atual)
			get_tree().quit(1)
			return
		_iniciar.call_deferred(fase_atual)
		return
	tentativas = 0
	if res == "fim":
		print("TESTE OK: o jogo foi do começo ao fim.")
		get_tree().quit(0)
		return
	if res == "concluida" and fase_atual < 10:
		_iniciar.call_deferred(fase_atual + 1)
		return
	print("FALHOU: resultado inesperado " + res)
	get_tree().quit(1)


func _process(_delta: float) -> void:
	frames += 1
	if frames > MAX_FRAMES:
		var info := ""
		if f != null:
			info = "x=%d parado=%s chefe=%s" % [int(f.mac.position.x), f.parado, str(f.chefe != null)]
		print("FALHOU: tempo esgotado na fase %d %s" % [fase_atual, info])
		get_tree().quit(1)
