@echo off
call :principal > "C:\git\monkey adventury\release_log.txt" 2>&1
exit /b

:principal
echo Inicio: %date% %time%
cd /d C:\git
if not exist "C:\git\monkey-adventure\.git" git clone https://github.com/weliveiracruz/monkey-adventure
cd /d C:\git\monkey-adventure
git pull
git tag -a v1.1 -m "Monkey Adventure 1.1 - dialogos da historia desligados por padrao"
git push origin v1.1
echo TAG_STATUS=%errorlevel%
where gh
if %errorlevel%==0 (
  gh release create v1.1 build\MonkeyAdventure.apk --title "Monkey Adventure 1.1" --notes "Versao de teste do Monkey Adventure. Novidade: os dialogos da historia vem desligados; para ouvir, ligue em Opcoes, Dialogos da historia. 10 fases, jogavel so pelo som. Para instalar, baixe o MonkeyAdventure.apk no celular e permita apps desta fonte. Se usar o TalkBack, suspenda enquanto joga."
  echo RELEASE_STATUS=%errorlevel%
) else (
  echo SEM_GH
)
echo Fim: %date% %time%
exit /b
