@echo off
call :principal > "C:\git\monkey adventury\release_log.txt" 2>&1
exit /b

:principal
echo Inicio: %date% %time%
cd /d C:\git
if not exist "C:\git\monkey-adventure\.git" git clone https://github.com/weliveiracruz/monkey-adventure
cd /d C:\git\monkey-adventure
git pull
git tag -a v1.2 -m "Monkey Adventure 1.2 - ilustracoes novas"
git push origin v1.2
echo TAG_STATUS=%errorlevel%
where gh
if %errorlevel%==0 (
  gh release create v1.2 build\MonkeyAdventure.apk --title "Monkey Adventure 1.2" --notes "Versao de teste do Monkey Adventure. Novidades: ilustracoes novas para o Macaco, os bichos, os chefes e os 10 cenarios, com fundo em camadas; dialogos da historia desligados por padrao. 10 fases, jogavel so pelo som. Para instalar, baixe o MonkeyAdventure.apk no celular e permita apps desta fonte. Se usar o TalkBack, suspenda enquanto joga."
  echo RELEASE_STATUS=%errorlevel%
) else (
  echo SEM_GH
)
echo Fim: %date% %time%
exit /b
