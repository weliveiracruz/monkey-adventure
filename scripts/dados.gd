extends RefCounted
## Todos os dados do Monkey Adventure: fases, bichos, objetos, chefes e diálogos.
##
## Como ler o "mapa" de cada fase (cada palavra é um trecho, da esquerda para a direita):
##   _        chão (200 px)              B   buraco          C   cipó sobre um vão
##   T        tronco no rio              F   folha que afunda ~   água entre troncos
##   P        piso que cai               H   milharal (esconderijo)
##   b  b^    banana normal (no chão / no alto)   z z^  bronze   s s^  prata
##   m        banana metálica (blindagem)         v     banana verde (tira vida)
##   o:nome   objeto no chão para tacar           e:nome  inimigo
##   a        armadilha da fase                    J      jaula com macaco preso
##   K        ponto de retorno                     D:id   diálogo
##   FEIRA    feira cheia de bananas
##   M:chefe  meio-chefe (a fase continua depois) X:chefe  chefe final da fase

const FASES := [
	{
		"nome": "A Selva", "ceu": Color(0.55, 0.82, 0.62), "chao": Color(0.36, 0.25, 0.14),
		"borda": Color(0.2, 0.6, 0.2), "deco": "arvore", "passo": "passo",
		"queda": "Caiu da árvore!", "armadilha": {"nome": "Espinhos", "som": "espinho"},
		"layout": "_ _ D:f1_inicio _ D:tut_banana b _ b _ b _ D:tut_pulo _ B _ b _ B _ D:tut_alta b^ _ b^ _ K _ D:tut_cipo _ C _ b _ C _ z _ K _ D:tut_jogar _ e:cobra _ b _ e:cobra _ D:tut_pegar o:graveto _ _ e:cobra _ K _ D:tut_verde v _ b _ v _ B _ D:bagunceiro e:bagunceiro _ b _ e:bagunceiro _ D:tut_abaixar _ e:papagaio _ b _ e:papagaio _ K _ D:tut_desviar _ a _ b _ C _ e:bagunceiro _ b b b _ D:tut_chuva _ o:frutinha _ b b _ K _ _ X:coruja",
	},
	{
		"nome": "O Rio", "ceu": Color(0.6, 0.85, 0.95), "chao": Color(0.4, 0.3, 0.18),
		"borda": Color(0.3, 0.65, 0.3), "deco": "arvore", "passo": "passo", "agua": true,
		"queda": "Caiu na água!", "armadilha": {"nome": "Espinhos", "som": "espinho"},
		"layout": "_ _ D:f2_inicio _ b _ T ~ T b ~ T ~ T z ~ T _ K _ D:f2_folha T ~ F ~ T b ~ F ~ T ~ T _ o:pedrinha _ K D:f2_piranha T ~ e:piranha T ~ T b ~ e:piranha T ~ F ~ T _ C _ b _ K _ D:f2_garca _ s _ T ~ F ~ T ~ e:piranha T b ~ T ~ F ~ T _ b _ o:concha_rio _ C _ b b _ K _ _ X:crocodilo",
	},
	{
		"nome": "A Savana", "ceu": Color(0.98, 0.82, 0.5), "chao": Color(0.75, 0.6, 0.3),
		"borda": Color(0.7, 0.65, 0.25), "deco": "acacia", "passo": "passo",
		"queda": "Caiu no buraco!", "armadilha": {"nome": "Espinhos", "som": "espinho"},
		"layout": "_ _ D:f3_inicio _ b _ e:zebra _ b _ B _ e:zebra _ e:zebra _ z _ K _ D:f3_hiena e:hiena _ b^ _ e:hiena _ o:pedra _ B _ b _ K _ _ M:elefante _ b _ e:zebra _ C _ s _ e:hiena _ m _ e:hiena _ e:zebra _ b b _ K _ o:galho _ _ M:leoa _ b b _ K _ _ X:leao",
	},
	{
		"nome": "A Montanha", "ceu": Color(0.72, 0.8, 0.92), "chao": Color(0.45, 0.43, 0.42),
		"borda": Color(0.85, 0.88, 0.9), "deco": "rocha", "passo": "passo", "vento": true,
		"queda": "Caiu da montanha!", "armadilha": {"nome": "Pedras pontudas", "som": "espinho"},
		"layout": "_ _ D:f4_inicio _ b _ e:pedra _ b _ B _ e:cabra _ z^ _ K _ D:f4_aguia _ e:aguia _ b _ e:pedra _ B _ e:aguia _ o:pinha _ K _ D:f4_urso _ e:urso _ b _ B _ s^ _ e:cabra _ C _ _ e:urso _ m _ K _ e:aguia _ e:pedra _ b b _ B _ o:pedra _ e:urso _ b _ K _ _ X:gaviao",
	},
	{
		"nome": "A Caverna", "ceu": Color(0.1, 0.08, 0.15), "chao": Color(0.25, 0.22, 0.28),
		"borda": Color(0.4, 0.35, 0.5), "deco": "caverna", "passo": "passo_eco", "escuro": true,
		"queda": "Caiu num buraco da caverna!", "armadilha": {"nome": "Pedras pontudas", "som": "espinho"},
		"layout": "_ _ D:f5_inicio _ b _ e:estalactite _ b _ B _ D:f5_cogumelo _ e:morcego _ z _ K _ D:f5_aranha _ e:aranha _ b _ e:estalactite _ B _ e:aranha _ D:f5_cristal o:cristal _ K _ e:morcego _ s _ e:estalactite _ C _ b^ _ e:aranha _ m _ K _ e:morcego _ e:estalactite _ b b _ o:cristal _ K _ _ X:morcegos",
	},
	{
		"nome": "A Fazenda", "ceu": Color(0.62, 0.85, 1.0), "chao": Color(0.5, 0.35, 0.2),
		"borda": Color(0.4, 0.7, 0.25), "deco": "celeiro", "passo": "passo",
		"queda": "Caiu no buraco!", "armadilha": {"nome": "Ancinho", "som": "espinho"},
		"layout": "_ _ D:f6_inicio _ b _ e:galinha _ o:ovo _ b _ B _ e:galinha _ z _ K _ D:f6_cachorro _ e:cachorro _ b _ D:f6_milharal H e:cachorro _ b _ B _ o:espiga _ K _ D:f6_bode _ e:bode _ s^ _ e:galinha _ C _ e:bode _ m _ H _ b b _ K _ o:ovo _ o:espiga _ b b b _ K _ _ X:touro",
	},
	{
		"nome": "A Cidade", "ceu": Color(0.7, 0.75, 0.82), "chao": Color(0.35, 0.35, 0.38),
		"borda": Color(0.6, 0.6, 0.62), "deco": "predio", "passo": "passo",
		"queda": "Caiu do telhado!", "armadilha": {"nome": "Bueiro aberto", "som": "espinho"},
		"layout": "_ _ D:f7_inicio _ b _ e:pombo _ C _ b _ e:gato _ C _ z _ K _ D:f7_gato e:gato _ b^ _ e:pombo _ o:latinha _ K _ D:f7_rua _ e:carro _ b _ e:bicicleta _ B _ e:cachorro _ s _ e:carro _ o:tampinha _ K _ D:f7_feira FEIRA D:f7_feira_fim _ e:pombo _ e:gato _ m _ K _ _ X:carrocinha",
	},
	{
		"nome": "O Zoológico", "ceu": Color(0.68, 0.88, 0.75), "chao": Color(0.55, 0.45, 0.3),
		"borda": Color(0.35, 0.65, 0.3), "deco": "zoo", "passo": "passo",
		"queda": "Caiu no fosso!", "armadilha": {"nome": "Grade", "som": "espinho"},
		"layout": "_ _ D:f8_inicio _ b _ J _ e:tratador _ b _ B _ J _ e:flamingo _ z _ K _ D:f8_pinguim _ e:pinguim _ b _ J _ o:balde _ e:tratador _ B _ s _ J _ e:pinguim _ C _ e:flamingo _ o:peixinho _ K _ J _ m _ b b _ e:tratador _ K _ _ X:rinoceronte",
	},
	{
		"nome": "A Praia", "ceu": Color(0.55, 0.85, 1.0), "chao": Color(0.93, 0.85, 0.6),
		"borda": Color(0.97, 0.92, 0.7), "deco": "coqueiro", "passo": "passo",
		"queda": "Caiu num buraco na areia!", "armadilha": {"nome": "Água-viva", "som": "agua_viva"},
		"layout": "_ _ D:f9_inicio _ b _ e:caranguejo _ o:coco _ b _ a _ D:f9_gaivota _ e:gaivota _ z _ B _ e:onda _ K _ D:f9_aliados _ e:caranguejo _ b _ a _ e:gaivota _ o:concha _ C _ s _ e:onda _ e:caranguejo _ K _ a _ m _ e:gaivota _ b b _ o:coco _ K _ _ X:tartaruga",
	},
	{
		"nome": "O Templo do Gorila-chefe", "ceu": Color(0.55, 0.25, 0.18), "chao": Color(0.4, 0.33, 0.28),
		"borda": Color(0.6, 0.5, 0.35), "deco": "templo", "passo": "passo_eco",
		"queda": "Caiu num buraco do templo!", "armadilha": {"nome": "Lanças", "som": "lanca"},
		"layout": "_ _ D:f10_inicio _ b _ e:babuino _ D:f10_piso _ P _ b _ P _ K _ D:f10_lanca _ a _ e:gorilinha _ z _ B _ e:babuino _ P _ o:pedra_templo _ K _ a _ e:babuino _ s _ C _ e:gorilinha _ P _ a _ m _ K _ o:estatua _ b b b _ e:babuino _ K _ _ X:gorila",
	},
]

## mov: chao (anda), investida (corre), rolante (não escorrega), aereo (voa baixo),
## alto (parado na altura da cabeça), pulante (pula da água), queda (cai do teto),
## ladrao (rouba bananas), urso (abraço fatal)
const INIMIGOS := {
	"cobra": {"nome": "Cobra", "mov": "chao", "som": "chocalho", "cor": Color(0.3, 0.6, 0.2), "w": 50, "h": 24, "vel": 50},
	"bagunceiro": {"nome": "Macaco bagunceiro", "mov": "chao", "som": "riso_macaco", "cor": Color(0.65, 0.45, 0.3), "w": 34, "h": 50, "vel": 40},
	"papagaio": {"nome": "Papagaio", "mov": "aereo", "som": "papagaio", "cor": Color(0.9, 0.2, 0.2), "w": 40, "h": 30, "vel": 140},
	"piranha": {"nome": "Piranha", "mov": "pulante", "som": "piranha", "cor": Color(0.8, 0.3, 0.3), "w": 32, "h": 28, "vel": 0},
	"zebra": {"nome": "Zebra", "mov": "investida", "som": "galope", "cor": Color(0.95, 0.95, 0.95), "w": 70, "h": 60, "vel": 280},
	"hiena": {"nome": "Hiena", "mov": "chao", "som": "hiena", "cor": Color(0.75, 0.62, 0.4), "w": 56, "h": 40, "vel": 90},
	"pedra": {"nome": "Pedra rolando", "mov": "rolante", "som": "rolando", "cor": Color(0.5, 0.5, 0.5), "w": 50, "h": 50, "vel": 260},
	"cabra": {"nome": "Cabra", "mov": "investida", "som": "balido", "cor": Color(0.85, 0.85, 0.82), "w": 54, "h": 50, "vel": 200},
	"aguia": {"nome": "Águia", "mov": "aereo", "som": "grito_aguia", "cor": Color(0.4, 0.28, 0.15), "w": 50, "h": 30, "vel": 180},
	"urso": {"nome": "Urso", "mov": "urso", "som": "rosnado", "cor": Color(0.3, 0.2, 0.12), "w": 60, "h": 64, "vel": 40},
	"estalactite": {"nome": "Estalactite", "mov": "queda", "som": "estalo", "cor": Color(0.6, 0.6, 0.7), "w": 30, "h": 50, "vel": 0},
	"aranha": {"nome": "Aranha", "mov": "alto", "som": "fio", "cor": Color(0.1, 0.1, 0.1), "w": 36, "h": 30, "vel": 0},
	"morcego": {"nome": "Morcego", "mov": "aereo", "som": "guincho", "cor": Color(0.4, 0.2, 0.5), "w": 40, "h": 24, "vel": 170},
	"galinha": {"nome": "Galinha", "mov": "chao", "som": "cacarejo", "cor": Color(1, 1, 1), "w": 34, "h": 34, "vel": 70},
	"bode": {"nome": "Bode", "mov": "investida", "som": "bode", "cor": Color(0.8, 0.7, 0.55), "w": 56, "h": 52, "vel": 210},
	"cachorro": {"nome": "Cachorro", "mov": "investida", "som": "latido", "cor": Color(0.55, 0.35, 0.2), "w": 56, "h": 44, "vel": 260},
	"pombo": {"nome": "Pombo", "mov": "aereo", "som": "pombo", "cor": Color(0.55, 0.6, 0.7), "w": 36, "h": 26, "vel": 130},
	"gato": {"nome": "Gato", "mov": "chao", "som": "chiado", "cor": Color(0.95, 0.6, 0.2), "w": 44, "h": 34, "vel": 110},
	"carro": {"nome": "Carro", "mov": "rolante", "som": "buzina", "cor": Color(0.85, 0.15, 0.15), "w": 110, "h": 55, "vel": 340},
	"bicicleta": {"nome": "Bicicleta", "mov": "rolante", "som": "campainha", "cor": Color(0.2, 0.4, 0.9), "w": 70, "h": 60, "vel": 220},
	"tratador": {"nome": "Tratador", "mov": "chao", "som": "apito", "cor": Color(0.3, 0.5, 0.3), "w": 40, "h": 80, "vel": 55},
	"flamingo": {"nome": "Flamingo", "mov": "chao", "som": "flamingo", "cor": Color(1, 0.5, 0.7), "w": 36, "h": 70, "vel": 40},
	"pinguim": {"nome": "Pinguim", "mov": "investida", "som": "pinguim", "cor": Color(0.1, 0.1, 0.15), "w": 36, "h": 44, "vel": 240},
	"caranguejo": {"nome": "Caranguejo", "mov": "chao", "som": "clique", "cor": Color(0.9, 0.3, 0.2), "w": 44, "h": 24, "vel": 70},
	"gaivota": {"nome": "Gaivota", "mov": "ladrao", "som": "gaivota", "cor": Color(0.97, 0.97, 0.97), "w": 44, "h": 26, "vel": 170},
	"onda": {"nome": "Onda", "mov": "rolante", "som": "onda", "cor": Color(0.5, 0.75, 1), "w": 90, "h": 50, "vel": 200},
	"babuino": {"nome": "Babuíno", "mov": "chao", "som": "babuino", "cor": Color(0.55, 0.5, 0.3), "w": 42, "h": 50, "vel": 120},
	"gorilinha": {"nome": "Gorila capanga", "mov": "investida", "som": "gorila", "cor": Color(0.25, 0.25, 0.28), "w": 60, "h": 70, "vel": 220},
}

const OBJETOS := {
	"graveto": {"nome": "graveto", "forca": 1, "cor": Color(0.5, 0.35, 0.2)},
	"frutinha": {"nome": "frutinha", "forca": 1, "cor": Color(0.8, 0.1, 0.4)},
	"pedrinha": {"nome": "pedrinha", "forca": 1, "cor": Color(0.6, 0.6, 0.6)},
	"concha_rio": {"nome": "concha de rio", "forca": 1, "cor": Color(0.9, 0.85, 0.8)},
	"pedra": {"nome": "pedra", "forca": 1, "cor": Color(0.5, 0.5, 0.5)},
	"galho": {"nome": "galho seco", "forca": 1, "cor": Color(0.55, 0.4, 0.25)},
	"pinha": {"nome": "pinha", "forca": 1, "cor": Color(0.45, 0.3, 0.15)},
	"cristal": {"nome": "cristal", "forca": 2, "cor": Color(0.5, 0.9, 1.0)},
	"ovo": {"nome": "ovo", "forca": 1, "cor": Color(1, 0.97, 0.88)},
	"espiga": {"nome": "espiga de milho", "forca": 1, "cor": Color(1, 0.85, 0.2)},
	"latinha": {"nome": "latinha", "forca": 1, "cor": Color(0.75, 0.75, 0.8)},
	"tampinha": {"nome": "tampinha", "forca": 1, "cor": Color(0.9, 0.2, 0.2)},
	"balde": {"nome": "balde", "forca": 1, "cor": Color(0.3, 0.5, 0.9)},
	"peixinho": {"nome": "peixinho", "forca": 1, "cor": Color(0.6, 0.7, 0.85)},
	"coco": {"nome": "coco", "forca": 1, "cor": Color(0.45, 0.3, 0.15)},
	"concha": {"nome": "concha", "forca": 1, "cor": Color(1, 0.8, 0.75)},
	"pedra_templo": {"nome": "pedra do templo", "forca": 1, "cor": Color(0.6, 0.5, 0.4)},
	"estatua": {"nome": "pedaço de estátua", "forca": 2, "cor": Color(0.75, 0.7, 0.6)},
}

## Resposta de cada ataque: "pular", "abaixar" ou "desviar".
const CHEFES := {
	"coruja": {"nome": "Coruja", "hp": 3, "som": "pio", "cor": Color(0.55, 0.42, 0.3), "w": 100, "h": 110, "voa": true,
		"ataques": ["abaixar", "abaixar", "desviar"], "tonto": "A coruja pousou no galho! Toque duas vezes para jogar a casca!"},
	"crocodilo": {"nome": "Crocodilo", "hp": 3, "som": "bolhas", "cor": Color(0.25, 0.5, 0.25), "w": 200, "h": 70,
		"ataques": ["pular", "desviar", "pular"], "tonto": "O crocodilo abriu a boca! Jogue agora!"},
	"elefante": {"nome": "Elefante", "hp": 2, "som": "trombeta", "cor": Color(0.6, 0.6, 0.65), "w": 170, "h": 170,
		"ataques": ["abaixar", "pular"], "tonto": "O elefante cansou! Jogue agora!"},
	"leoa": {"nome": "Leoa", "hp": 2, "som": "rugido_curto", "cor": Color(0.85, 0.65, 0.35), "w": 130, "h": 90,
		"ataques": ["desviar", "pular"], "tonto": "A leoa parou para respirar! Jogue agora!"},
	"leao": {"nome": "Leão", "hp": 3, "som": "rugido", "cor": Color(0.8, 0.55, 0.2), "w": 150, "h": 110,
		"ataques": ["abaixar", "pular", "desviar"], "tonto": "O leão errou o salto e ficou tonto! Jogue agora!"},
	"gaviao": {"nome": "Gavião", "hp": 3, "som": "grito_gaviao", "cor": Color(0.45, 0.35, 0.25), "w": 110, "h": 80, "voa": true,
		"ataques": ["desviar", "abaixar"], "tonto": "O gavião pousou na rocha! Jogue agora!"},
	"morcegos": {"nome": "Morcegos gigantes", "hp": 3, "som": "guincho", "cor": Color(0.35, 0.2, 0.45), "w": 160, "h": 70, "voa": true,
		"ataques": ["abaixar", "desviar", "abaixar"], "tonto": "Os morcegos estão pendurados descansando! Jogue agora!"},
	"touro": {"nome": "Touro", "hp": 3, "som": "bufa", "cor": Color(0.35, 0.2, 0.15), "w": 160, "h": 120,
		"ataques": ["desviar", "desviar", "pular"], "tonto": "O touro bateu na cerca e ficou tonto! Jogue casca, ovo, espiga, ou solte a chuva de cascas!"},
	"carrocinha": {"nome": "Carrocinha", "hp": 3, "som": "rede", "cor": Color(0.3, 0.35, 0.6), "w": 70, "h": 150,
		"ataques": ["desviar", "pular"], "tonto": "O carrocinha se enrolou na própria rede! Jogue a casca!"},
	"rinoceronte": {"nome": "Rinoceronte", "hp": 3, "som": "rinoceronte", "cor": Color(0.5, 0.5, 0.52), "w": 190, "h": 120,
		"ataques": ["desviar", "pular", "desviar"], "tonto": "O rinoceronte prendeu o chifre na grade! Jogue agora!"},
	"tartaruga": {"nome": "Tartaruga gigante", "hp": 3, "som": "casco", "cor": Color(0.3, 0.55, 0.35), "w": 200, "h": 110,
		"ataques": ["pular", "desviar"], "tonto": "A tartaruga pôs a cabeça pra fora! Jogue agora!"},
	"gorila": {"nome": "Gorila-chefe", "hp": 3, "som": "gorila", "cor": Color(0.2, 0.2, 0.22), "w": 190, "h": 210,
		"ataques": ["pular", "abaixar"], "tonto": "O gorila está tonto!",
		"etapas": [
			{"ataques": ["pular", "abaixar"], "fala": "O gorila está arremessando pedras! Pule ou abaixe!", "tonto": "O gorila parou para bater no peito! Jogue agora!"},
			{"ataques": ["pular", "desviar"], "fala": "O gorila está pulando e fazendo o chão tremer!", "tonto": "O gorila tropeçou! Jogue agora!", "aliados": true},
			{"ataques": ["desviar", "pular", "abaixar"], "fala": "O gorila ficou furioso! Agora só a chuva de cascas derruba ele. Quando ele ficar tonto, deslize para cima!",
				"tonto": "O gorila está tonto! Chuva de cascas! Deslize para cima!", "rapido": true, "so_chuva": true},
		]},
}

const DIALOGOS := {
	# ---------------------------------------------------------- Fase 1, selva
	"f1_inicio": [
		["Narrador", "Roubaram a banana de ouro, que protege a floresta!"],
		["Vovô Macaco", "Neto, a banana de ouro protege nossa floresta. Traga ela de volta!"],
		["Macaco", "Pode deixar, vovô! Sem ela a selva vai murchar. Eu vou atrás!"],
		["Vovô Macaco", "Eu vou te ensinando pelo caminho. Você corre sozinho. Ouça os sons: cada coisa tem o seu."],
	],
	"tut_banana": [["Vovô Macaco", "Ouviu esse plim? É um cacho de banana. Passe por ele para pegar. Cada cacho dá vida e vai para a sacolinha."]],
	"tut_pulo": [["Vovô Macaco", "Esse som de vento é um buraco. Quando ouvir o estalinho na beirada, toque na tela para pular!"]],
	"tut_alta": [["Vovô Macaco", "O plim mais agudo é uma banana no alto. Pule para pegar!"]],
	"tut_cipo": [["Vovô Macaco", "Esse rangido é um cipó. Pule na beirada que você se pendura e atravessa sozinho."]],
	"tut_jogar": [["Vovô Macaco", "Esse chocalho é uma cobra! Pule por cima dela, ou toque duas vezes na tela para jogar uma casca de banana. Ela escorrega!"]],
	"tut_pegar": [["Vovô Macaco", "Essas duas notinhas são um objeto no chão. Segure o dedo na tela para pegar. Depois toque duas vezes para tacar."]],
	"tut_verde": [["Vovô Macaco", "Cuidado! Esse som azedo é banana verde. Pule por cima, não coma!"]],
	"bagunceiro": [["Macaco bagunceiro", "Ei, essa banana aí é minha!"]],
	"tut_abaixar": [["Vovô Macaco", "Esse grito é um papagaio voando baixo. Deslize o dedo para baixo para se abaixar!"]],
	"tut_desviar": [["Vovô Macaco", "Deslize para a direita para dar uma corrida rápida, ou para a esquerda para recuar. Isso é desviar! E cuidado com os espinhos: pule!"]],
	"tut_chuva": [["Vovô Macaco", "Com dez bananas guardadas, deslize para cima e solte a chuva de cascas! E com dois dedos na tela você pausa e ouve como está."]],
	"coruja_intro": [
		["Coruja", "Uhuu... ninguém passa pela minha árvore sem resposta, macaquinho!"],
		["Vovô Macaco", "Ouça o que ela vai fazer e responda. Quando ela pousar, jogue a casca!"],
	],
	"coruja_fim": [["Coruja", "Uhuu... você é esperto. O gorila foi pro rio!"], ["Macaco", "Valeu, coruja! Lá vou eu!"]],
	# ---------------------------------------------------------- Fase 2, rio
	"f2_inicio": [["Macaco", "O rio! Vou pular de tronco em tronco."], ["Macaco", "Tronco firme... tronco firme..."]],
	"f2_folha": [["Macaco", "Cuidado com as folhas, elas afundam! Se ouvir som de papel molhado, pule logo! Tronco firme... tronco firme... ops, folha não!"]],
	"f2_piranha": [["Piranha", "Nhac nhac, que macaco gostoso!"]],
	"f2_garca": [["Garça", "O gorila passou por aqui rio abaixo, corre!"]],
	"crocodilo_intro": [["Crocodilo", "Hehe, vem nadar comigo..."], ["Macaco", "Vou ouvir as bolhas pra saber de onde ele sai!"]],
	"crocodilo_fim": [["Crocodilo", "Ai, minha boca! Tá bom, pode passar!"], ["Macaco", "Rumo à savana!"]],
	# ---------------------------------------------------------- Fase 3, savana
	"f3_inicio": [["Macaco", "Ufa, que calor! Cadê uma acácia pra eu subir?"], ["Zebra", "Sai da frente que a manada vem aí!"]],
	"f3_hiena": [["Hiena", "Hahaha! Olha o tamanho dele!"]],
	"elefante_intro": [["Elefante", "Saia do meu caminho, pequeno!"]],
	"elefante_fim": [["Elefante", "Tá bom, tá bom! Pode passar."]],
	"leoa_intro": [["Leoa", "Você é rápido, mas eu sou mais."]],
	"leoa_fim": [["Leoa", "Grr... vou chamar o chefe!"]],
	"leao_intro": [["Leão", "Aqui quem manda sou eu. Grrr!"]],
	"leao_fim": [["Leão", "Você venceu, macaco. O gorila subiu a montanha."], ["Macaco", "Então eu subo também!"]],
	# ---------------------------------------------------------- Fase 4, montanha
	"f4_inicio": [["Cabra", "Méééé! Aqui em cima é meu território!"], ["Macaco", "Esse vento quase me levou!"]],
	"f4_aguia": [["Águia", "Lá de cima eu vejo tudo, macaco."]],
	"f4_urso": [["Urso", "Vem cá, me dá um abraço..."], ["Macaco", "Abraço de urso? Nem pensar! Se ele me abraçar, acabou!"]],
	"gaviao_intro": [["Gavião", "Você nunca vai chegar ao topo!"]],
	"gaviao_fim": [["Gavião", "Minhas penas! O gorila fugiu pela caverna!"], ["Macaco", "Então lá vou eu, no escuro!"]],
	# ---------------------------------------------------------- Fase 5, caverna
	"f5_inicio": [["Macaco", "Tá escuro demais... vou seguir o eco."], ["Eco", "Eco... eco... eco..."]],
	"f5_cogumelo": [["Macaco", "Esses cogumelos brilhantes mostram o caminho!"], ["Eco", "Caminho... caminho... caminho..."]],
	"f5_aranha": [["Aranha", "Fiquei tecendo essa teia a semana toda pra você!"]],
	"f5_cristal": [["Macaco", "Um cristal! Esse acerta mais forte!"]],
	"morcegos_intro": [["Morcegos", "Iiiih! Intruso!"]],
	"morcegos_fim": [["Morcegos", "Iiih! Vai embora, vai embora!"], ["Macaco", "Já vou! Tem luz lá na frente: uma fazenda!"]],
	# ---------------------------------------------------------- Fase 6, fazenda
	"f6_inicio": [["Galinha", "Cocoricó! Larga meus ovos!"], ["Macaco", "Desculpa, dona galinha, é por uma boa causa!"]],
	"f6_cachorro": [["Cachorro", "Au au! Ladrão de milho!"]],
	"f6_milharal": [["Macaco", "Um milharal! Aqui dentro ninguém me vê."]],
	"f6_bode": [["Bode", "Béé! Vou te dar uma cabeçada!"]],
	"touro_intro": [["Touro", "Vermelho? Não. Macaco? Também serve!"], ["Macaco", "Quando ele bufar, eu desvio. Aí ele bate na cerca!"]],
	"touro_fim": [["Touro", "Muuu... minha cabeça..."], ["Macaco", "A estrada leva pra cidade!"]],
	# ---------------------------------------------------------- Fase 7, cidade
	"f7_inicio": [["Macaco", "Quanto barulho! Vou seguir a buzina."], ["Pombo", "Pruu! Esse pão é nosso!"]],
	"f7_gato": [["Gato", "Fsss! Telhado é coisa de gato!"]],
	"f7_rua": [["Macaco", "Cuidado com os carros! Ouviu buzina, pule!"]],
	"f7_feira": [["Feirante", "Olha a banana, freguês!"], ["Macaco", "Uma feira cheia de bananas! Vou pegar quantas eu quiser!"]],
	"f7_feira_fim": [["Feirante", "Ei, volta aqui!"]],
	"carrocinha_intro": [["Carrocinha", "Um macaco solto na cidade? Vem pra rede!"], ["Macaco", "Pega eu se puder!"]],
	"carrocinha_fim": [["Carrocinha", "Escorreguei de novo!"], ["Macaco", "Dizem que o gorila passou pelo zoológico."]],
	# ---------------------------------------------------------- Fase 8, zoológico
	"f8_inicio": [["Tratador", "Fugiu um macaco! Fecha os portões!"], ["Macaco", "Tem macacos presos aqui! Vou soltar todos."]],
	"f8_pinguim": [["Pinguim", "Lá vou eu escorregando!"]],
	"jaula": [["Macaco preso", "Me solta, irmão! Eu vou com você!"]],
	"aliado_solto": [["Macaco aliado", "Valeu! Tô contigo até o fim!"]],
	"aliados_cinco": [["Macaco aliado", "Somos cinco agora, ninguém segura a gente!"]],
	"rinoceronte_intro": [["Rinoceronte", "Ninguém foge do meu zoológico!"], ["Macaco", "Quem quer liberdade? Vamos juntos!"]],
	"rinoceronte_fim": [["Rinoceronte", "Meu chifre! Preso de novo!"], ["Macaco", "O gorila foi pra praia!"]],
	# ---------------------------------------------------------- Fase 9, praia
	"f9_inicio": [["Macaco", "A praia! Ouço as ondas."], ["Caranguejo", "Clic clic! Cuidado com o beliscão!"]],
	"f9_gaivota": [["Gaivota", "Valeu pela banana, otário!"], ["Macaco", "Gaivota ladra! Quando ela gritar, me abaixo."]],
	"f9_aliados": [["Macaco aliado", "Deixa que eu jogo os cocos lá de cima!"]],
	"tartaruga_intro": [["Tartaruga gigante", "Tenho 200 anos de paciência, macaco."], ["Tartaruga gigante", "Dentro do meu casco eu sou invencível."]],
	"tartaruga_fim": [["Tartaruga gigante", "Hum... você tem coragem. O templo do gorila fica no vulcão."], ["Macaco", "É a grande final!"]],
	# ---------------------------------------------------------- Fase 10, templo
	"f10_inicio": [["Narrador", "O templo do gorila-chefe, no alto do vulcão."], ["Babuíno", "O chefe não quer visitas!"]],
	"f10_piso": [["Macaco", "Cuidado, esse piso vai cair! Ouviu o rachado, corra sem parar!"]],
	"f10_lanca": [["Macaco", "Lanças na parede! Ouço o clique e pulo."]],
	"gorila_intro": [
		["Gorila-chefe", "Você chegou longe, macaquinho, mas acaba aqui!"],
		["Gorila-chefe", "A banana de ouro é minha!"],
		["Macaco", "Ela é da selva, e eu vim buscá-la!"],
	],
	"gorila_aliados": [["Macaco aliado", "Ei, gorilão, aqui!"]],
	"gorila_chuva": [["Macaco aliado", "Agora, Macaco! Solta a chuva de cascas!"]],
	"gorila_fim": [["Gorila-chefe", "Não! Minha banana!"], ["Narrador", "O gorila-chefe caiu! A banana de ouro está no alto da torre."]],
	"torre_inicio": [["Macaco", "A torre! Vou escalar."], ["Narrador", "Deslize para cima para subir. Se ouvir uma pedra solta, deslize para o lado!"]],
	"torre_topo": [["Macaco", "A banana de ouro! Finalmente!"]],
	"final": [
		["Narrador", "O Macaco voltou para a selva como herói."],
		["Animais da selva", "Viva o Macaco! Viva o nosso herói!"],
		["Vovô Macaco", "Eu sabia que você conseguiria, neto."],
		["Macaco", "Hum... só uma mordidinha."],
		["Narrador", "E o Macaco ficou mais forte que o gorila! Fim. Obrigado por jogar Monkey Adventure!"],
	],
}

const COMO_JOGAR := [
	"O Macaco corre sozinho. Você só reage ao que ouve.",
	"Toque na tela para pular. Ouviu o vento de um buraco e o estalinho da beirada, pule.",
	"Toque duas vezes para jogar uma casca de banana. Os bichos escorregam.",
	"Segure o dedo na tela para pegar um objeto do chão. Depois toque duas vezes para tacar.",
	"Deslize para baixo para se abaixar. Deslize para a direita para correr rápido, ou para a esquerda para recuar: isso é desviar.",
	"Deslize para cima para soltar a chuva de cascas, quando tiver dez bananas guardadas.",
	"Toque com dois dedos para pausar e ouvir sua vida, seus pontos e suas bananas.",
	"Cacho normal vale 1 ponto de vida. Bronze vale 3. Prata vale 10. A metálica deixa o Macaco blindado. A verde tira vida.",
	"Nos chefes, ouça o aviso: som subindo é para pular, som descendo é para abaixar, dois toques é para desviar. Quando o chefe ficar tonto, jogue!",
	"Cuidado com o abraço do urso: se ele abraçar, acabou.",
	"Use fones de ouvido: os sons saem do lado em que as coisas estão.",
	"Se você usa o TalkBack, suspenda ele enquanto joga. O jogo fala sozinho.",
]
