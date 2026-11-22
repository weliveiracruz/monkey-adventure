extends Node
## Estado global do jogo: vida, pontos, bananas, aliados, progresso e opções.

const ARQUIVO_SAVE := "user://monkey_save.json"
const VIDA_MAX := 20
const VIDA_INICIAL := 10
const SACOLA_MAX := 10
const CUSTO_CHUVA := 10
const TOTAL_FASES := 10

signal mudou

var vida := VIDA_INICIAL
var pontos := 0
var bananas := 0        ## bananas guardadas (sacolinha + sovaco)
var aliados := 0        ## macacos soltos no zoológico (até 5)
var fase := 1           ## fase atual / para continuar
var fase_liberada := 1  ## maior fase já liberada
var concluiu := false   ## terminou o jogo pelo menos uma vez
var opcoes := {
	"lenta": false,     ## velocidade mais lenta do Macaco
	"dicas": true,      ## dicas faladas ("Pule!", "Abaixe!")
	"vibrar": true,
	"legendas": true,
}

## Usado apenas pelos testes automáticos: o jogo joga sozinho.
var piloto := false
var dano_recebido_teste := 0

var _foto := {}
## Dicas que já foram faladas nesta sessão (cada uma fala só uma vez).
var dicas_ditas := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	carregar()


func nova_aventura() -> void:
	vida = VIDA_INICIAL
	pontos = 0
	bananas = 0
	aliados = 0
	fase = 1
	salvar()


func iniciar_fase(n: int) -> void:
	fase = n
	if vida < VIDA_INICIAL:
		vida = VIDA_INICIAL
	_foto = {"vida": vida, "pontos": pontos, "bananas": bananas, "aliados": aliados}
	salvar()
	mudou.emit()


## Volta ao estado do começo da fase (usado quando o Macaco desmaia).
func restaurar_inicio_fase() -> void:
	if _foto.is_empty():
		return
	vida = max(int(_foto.vida), VIDA_INICIAL)
	pontos = int(_foto.pontos)
	bananas = int(_foto.bananas)
	aliados = int(_foto.aliados)
	mudou.emit()


func concluir_fase(n: int) -> void:
	fase_liberada = clamp(max(fase_liberada, n + 1), 1, TOTAL_FASES)
	fase = clamp(n + 1, 1, TOTAL_FASES)
	if n >= TOTAL_FASES:
		concluiu = true
		fase = TOTAL_FASES
	salvar()


func velocidade() -> float:
	return 170.0 if opcoes.lenta else 230.0


## Pega uma banana. Retorna o valor em pontos de vida.
func ganhar_banana(valor: int) -> int:
	vida = min(VIDA_MAX, vida + valor)
	pontos += valor
	bananas += 1
	mudou.emit()
	return valor


func na_sacola() -> int:
	return min(bananas, SACOLA_MAX)


func no_sovaco() -> int:
	return max(0, bananas - SACOLA_MAX)


func gastar_bananas(n: int) -> bool:
	if bananas < n:
		return false
	bananas -= n
	mudou.emit()
	return true


func perder_bananas(n: int) -> int:
	var perdeu: int = min(n, bananas)
	bananas -= perdeu
	mudou.emit()
	return perdeu


func receber_dano(n: int) -> void:
	vida -= n
	if piloto:
		dano_recebido_teste += n
		vida = max(vida, 1)
	vida = max(vida, 0)
	mudou.emit()


func somar_pontos(n: int) -> void:
	pontos += n
	mudou.emit()


func vibrar(ms: int) -> void:
	if opcoes.vibrar:
		Input.vibrate_handheld(ms)


func salvar() -> void:
	if piloto:
		return
	var dados := {
		"vida": vida, "pontos": pontos, "bananas": bananas, "aliados": aliados,
		"fase": fase, "fase_liberada": fase_liberada, "concluiu": concluiu,
		"opcoes": opcoes,
	}
	var f := FileAccess.open(ARQUIVO_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dados))


func carregar() -> void:
	if not FileAccess.file_exists(ARQUIVO_SAVE):
		return
	var f := FileAccess.open(ARQUIVO_SAVE, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	vida = int(d.get("vida", VIDA_INICIAL))
	pontos = int(d.get("pontos", 0))
	bananas = int(d.get("bananas", 0))
	aliados = int(d.get("aliados", 0))
	fase = clamp(int(d.get("fase", 1)), 1, TOTAL_FASES)
	fase_liberada = clamp(int(d.get("fase_liberada", 1)), 1, TOTAL_FASES)
	concluiu = bool(d.get("concluiu", false))
	var o = d.get("opcoes", {})
	if typeof(o) == TYPE_DICTIONARY:
		for k in opcoes.keys():
			if o.has(k):
				opcoes[k] = bool(o[k])
