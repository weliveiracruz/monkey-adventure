@echo off
call :principal > "C:\git\monkey adventury\release_log.txt" 2>&1
exit /b

:principal
echo Inicio: %date% %time%
cd /d C:\git
if not exist "C:\git\monkey-adventure\.git" git clone https://github.com/weliveiracruz/monkey-adventure
cd /d C:\git\monkey-adventure
git pull
git tag -a v1.3 -m "Monkey Adventure 1.3 - opcao para desligar a narracao"
git push origin v1.3
echo TAG_STATUS=%errorlevel%
where gh
if %errorlevel%==0 (
  gh release create v1.3 build\MonkeyAdventure.apk --title "Monkey Adventure 1.3" --notes "Versao de teste do Monkey Adventure. Novidades: opcao em Opcoes para desligar a narracao do jogo; ilustracoes novas para o Macaco, os bichos, os chefes e os 10 cenarios, com fundo em camadas; dialogos da historia desligados por padrao. 10 fases, jogavel so pelo som. Para instalar, baixe o MonkeyAdventure.apk no celular e permita apps desta fonte. Se usar o TalkBack, suspenda enquanto joga."
  echo RELEASE_STATUS=%errorlevel%
) else (
  echo SEM_GH
)
echo Fim: %date% %time%
exit /b
