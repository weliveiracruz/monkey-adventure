extends Node
## Teste do menu, pausa e diálogos (sem piloto automático).
var main
var passo := 0
var t := 0.0

func _ready() -> void:
	main = load("res://scripts/main.gd").new()
	add_child(main)

func _process(delta: float) -> void:
	t += delta
	var acoes := [
		[0.5, "deslize", "direita"], [0.8, "deslize", "direita"], [1.0, "toque", ""],
		[1.2, "deslize", "esquerda"], [1.4, "deslize", "esquerda"],
		[1.6, "toque_duplo", ""],          # Nova aventura (ou Continuar)
		[3.0, "toque", ""],                # pula / pula diálogo
		[20.0, "dois_dedos", ""],          # pausa
		[21.0, "deslize", "direita"], [21.5, "toque_duplo", ""],  # ouvir situação
		[22.0, "deslize", "esquerda"], [22.5, "toque_duplo", ""], # continuar
		[23.0, "toque_duplo", ""],         # joga casca
		[23.5, "deslize", "cima"],         # chuva (faltam bananas)
		[24.0, "deslize", "baixo"], [24.5, "deslize", "direita"],
		[25.0, "dois_dedos", ""], [25.5, "deslize", "direita"], [25.7, "deslize", "direita"], [25.9, "deslize", "direita"],
		[26.2, "toque_duplo", ""],         # voltar ao menu
		[27.0, "deslize", "direita"], [27.2, "deslize", "direita"], [27.4, "deslize", "direita"], [27.6, "toque_duplo", ""], # opções?
		[28.0, "toque_duplo", ""], [28.5, "dois_dedos", ""],
	]
	while passo < acoes.size() and t >= acoes[passo][0]:
		var a = acoes[passo]
		print("t=%.1f gesto %s %s -> alvo %s | falando: %s" % [t, a[1], a[2], str(Gestos.alvo), Fala._label.text])
		Gestos.enviar(a[1], a[2])
		passo += 1
	if t > 30.0:
		print("TESTE MENU OK")
		get_tree().quit(0)
