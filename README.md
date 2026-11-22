# Monkey Adventure

A aventura do Macaco atrás da banana de ouro. Jogo de aventura para Android, feito no Godot 4.4.1, pensado para ser jogado só pelo som: cada coisa tem o seu som, os sons saem do lado em que as coisas estão, o celular vibra nos momentos importantes e todos os diálogos e avisos são falados em português pela voz do próprio celular, com legenda na tela.

## Instalar no celular

O arquivo pronto é `build/MonkeyAdventure.apk`.

1. Copie o `MonkeyAdventure.apk` para o celular (cabo USB, Google Drive, WhatsApp para você mesmo, etc.).
2. No celular, abra o arquivo. O Android vai pedir para permitir a instalação de apps desta fonte: permita.
3. Abra o Monkey Adventure.

Dicas:

- Use fones de ouvido. Os sons saem da esquerda ou da direita, conforme o lugar das coisas.
- Se você usa o TalkBack, suspenda ele enquanto joga (atalho: segurar as duas teclas de volume por 3 segundos). O jogo fala sozinho e os gestos do jogo não funcionam com o TalkBack ligado. Ao sair do jogo, ligue de novo pelo mesmo atalho.
- O jogo usa a voz do Android. Se não estiver em português, ajuste em Configurações, Acessibilidade ou Sistema, Saída de conversão de texto em voz.

Esta é uma versão de teste (assinada com chave de depuração). Para publicar na Play Store, é preciso gerar uma versão com chave própria (veja mais abaixo).

## Como jogar

O Macaco corre sozinho. Você reage ao que ouve.

| Gesto | O que faz | No computador |
| --- | --- | --- |
| Toque | Pular (e pular um diálogo) | Espaço |
| Toque duplo | Jogar casca de banana ou o objeto que está segurando | X ou Enter |
| Segurar o dedo | Pegar objeto do chão, abrir jaula | Z |
| Deslizar para baixo | Abaixar | Seta para baixo |
| Deslizar para a direita | Correr rápido (desviar) | Seta para a direita |
| Deslizar para a esquerda | Recuar (desviar) | Seta para a esquerda |
| Deslizar para cima | Chuva de cascas (com 10 bananas) / subir a torre | Seta para cima |
| Dois dedos na tela | Pausa e situação do Macaco | Esc ou P |

Nos menus: deslize para a direita ou esquerda para escolher, toque para repetir, toque duas vezes para confirmar, dois dedos para voltar. O botão voltar do Android abre a pausa.

Nos chefes: som subindo é para pular, som descendo é para abaixar, dois toques é para desviar. Quando o chefe fica tonto, jogue!

Bananas: cacho normal vale 1 ponto de vida, bronze 3, prata 10. A metálica deixa o Macaco blindado por 8 segundos. A verde tira vida. A sacolinha guarda 10 bananas; o resto vai para baixo do sovaco.

Os diálogos da história (Vovô Macaco, chefes, narrador) vêm desligados. Para ouvir a história, ligue em Opções, "Diálogos da história". Os avisos de jogo, como "Pule!" e as dicas, continuam funcionando.

Nas opções também dá para deixar o Macaco mais lento, desligar as dicas faladas, a vibração e as legendas. O progresso é salvo sozinho ao fim de cada fase.

## As 10 fases

1. Selva (tutorial com o Vovô Macaco), chefe Coruja
2. Rio (troncos, folhas que afundam, piranhas), chefe Crocodilo
3. Savana (zebras, hienas), meio-chefe Elefante, chefes Leoa e Leão
4. Montanha (vento, pedras, águia, urso do abraço fatal), chefe Gavião
5. Caverna (escura, eco, estalactites, aranhas, cristais), chefe Morcegos gigantes
6. Fazenda (galinhas, bode, cachorro, milharal), chefe Touro
7. Cidade (telhados, carros, feira com bananas à vontade), chefe Carrocinha
8. Zoológico (5 jaulas com macacos para soltar), chefe Rinoceronte
9. Praia (caranguejos, gaivotas ladras, ondas, aliados jogam cocos), chefe Tartaruga gigante
10. Templo do Gorila-chefe (pisos que caem, lanças), luta final em 3 etapas e a torre da banana de ouro

## O que tem na pasta

- `project.godot`: configuração do projeto.
- `cenas/main.tscn`: cena inicial.
- `scripts/dados.gd`: tudo o que é conteúdo: o mapa de cada fase, os bichos, os objetos, os chefes e todos os diálogos. É aqui que se mexe para mudar o jogo.
- `scripts/fase.gd`: a fase: movimento, bichos, itens, sons de aviso, chefes e torre.
- `scripts/chefe.gd`: a luta contra os chefes.
- `scripts/sfx.gd`: todos os sons, sintetizados por código (não há arquivos de áudio).
- `scripts/fala.gd`: voz e legendas.
- `scripts/gestos.gd`: reconhecimento dos gestos e do teclado.
- `scripts/game.gd`: vida, pontos, bananas, aliados, progresso salvo e opções.
- `scripts/menu.gd`, `scripts/main.gd`: menus e troca de telas.
- `scripts/macaco.gd`, `scripts/entidade.gd`: desenho do Macaco e das coisas do cenário.
- `testes/`: testes automáticos (o piloto automático joga as 10 fases).
- `export_presets.cfg`: configuração da exportação para Android.
- `Monkey Adventure - Roteiro e Plano.md`: o roteiro completo.

### Como ler o mapa de uma fase (em `dados.gd`)

Cada palavra é um trecho, da esquerda para a direita: `_` chão, `B` buraco, `C` cipó, `T` tronco, `F` folha que afunda, `~` água, `P` piso que cai, `H` milharal, `b` banana (`b^` no alto), `z` bronze, `s` prata, `m` metálica, `v` verde, `o:pedra` objeto, `e:cobra` inimigo, `a` armadilha, `J` jaula, `K` ponto de retorno, `D:nome` diálogo, `FEIRA`, `M:chefe` meio-chefe, `X:chefe` chefe final.

## Jogar no computador (teste rápido)

1. Baixe o Godot 4.4.1 para Windows em https://godotengine.org/download/archive/4.4.1-stable/ (arquivo `Godot_v4.4.1-stable_win64.exe.zip`) e extraia.
2. No terminal, rode:

```
Godot_v4.4.1-stable_win64.exe --path "C:\git\monkey adventury"
```

O jogo abre numa janela e fala pela voz do Windows. Use as teclas da tabela acima.

## Testes automáticos

```
Godot_v4.4.1-stable_win64_console.exe --headless --fixed-fps 60 --path "C:\git\monkey adventury" res://testes/teste.tscn
```

O piloto automático joga as 10 fases e termina com "TESTE OK" se nada quebrar. `res://testes/teste_menu.tscn` testa menus, pausa e opções.

## Gerar o APK de novo (depois de mudar o jogo)

Precisa de: Godot 4.4.1, os modelos de exportação 4.4.1, o JDK 17 e o Android SDK.

1. Modelos de exportação: baixe `Godot_v4.4.1-stable_export_templates.tpz` na mesma página do Godot. É um zip: extraia o conteúdo da pasta `templates` para `%APPDATA%\Godot\export_templates\4.4.1.stable\`.
2. JDK 17: instale o Temurin 17 (https://adoptium.net) e defina a variável `JAVA_HOME`.
3. Android SDK: instale o Android Studio, ou só as "command line tools", com `platform-tools` e `build-tools`. Defina a variável `ANDROID_HOME` apontando para a pasta do SDK.
4. Rode:

```
Godot_v4.4.1-stable_win64_console.exe --headless --path "C:\git\monkey adventury" --export-debug "Android" build\MonkeyAdventure.apk
```

Antes, em `export_presets.cfg`, troque `package/signed=false` por `package/signed=true` para o Godot assinar com a chave de depuração.

## Publicar na Play Store (depois)

1. Crie uma chave própria (guarde a senha e o arquivo, sem ela não dá para atualizar o app):

```
keytool -genkey -v -keystore monkey-release.keystore -alias monkey -keyalg RSA -keysize 2048 -validity 10000
```

2. Configure a chave em `export_presets.cfg` (opções `keystore/release`, `keystore/release_user`, `keystore/release_password`), aumente `version/code` a cada envio e exporte com `--export-release`. A Play Store pede o formato AAB, que exige ativar `gradle_build/use_gradle_build=true` e `gradle_build/export_format=1`.
