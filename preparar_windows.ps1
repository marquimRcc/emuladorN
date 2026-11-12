# Script de automação para Windows (PowerShell)
# Executa sem privilégios de Administrador no escopo do usuário

$ErrorActionPreference = "Stop"

$EmuladorDir = "$env:USERPROFILE\Documentos\emulador"
$EglantineDir = "$EmuladorDir\eglantine"
$ZipUrl = "https://github.com/Eglantine-Community/Eglantine/releases/download/v0.1.0-rc3/eglantine-windows-x86_64-pgo.zip"
$ZipFile = "$EmuladorDir\eglantine-windows.zip"

Write-Host "=== Preparando ambiente Eglantine (Windows) ===" -ForegroundColor Cyan

if (!(Test-Path $EmuladorDir)) {
    New-Item -ItemType Directory -Path $EmuladorDir -Force | Out-Null
}

# 1. Download da build correta
if (!(Test-Path "$EglantineDir\eglantine.exe")) {
    Write-Host "[1/4] Baixando build otimizada do Eglantine (OoT Fix)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile
    
    Write-Host "[2/4] Descompactando emulador..." -ForegroundColor Yellow
    Expand-Archive -Path $ZipFile -DestinationPath $EglantineDir -Force
    Remove-Item $ZipFile -Force
} else {
    Write-Host "[1/4] Emulador já instalado em $EglantineDir" -ForegroundColor Green
}

# 2. Configuração do idioma PT-BR e Gráficos
$ConfigDir = "$env:APPDATA\eglantine\config"
if (!(Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

$ConfigFile = "$ConfigDir\qt-config.ini"
Write-Host "[3/4] Aplicando configurações (PT-BR, Docked Mode, GPU Normal)..." -ForegroundColor Yellow

$SettingsToApply = @{
    "language_index" = "17"
    "language_index\default" = "false"
    "region_index" = "1"
    "region_index\default" = "false"
    "use_docked_mode" = "1"
    "use_docked_mode\default" = "false"
    "gpu_accuracy" = "1"
    "gpu_accuracy\default" = "false"
    "fix_bloom_effects" = "true"
    "fix_bloom_effects\default" = "false"
    "scaling_filter" = "1"
    "scaling_filter\default" = "false"
    "frame_gen" = "false"
    "frame_gen\default" = "false"
    "player_0_connected" = "true"
    "player_0_connected\default" = "false"
    "player_0_type" = "0"
    "player_0_type\default" = "false"
}

if (Test-Path $ConfigFile) {
    $Lines = Get-Content $ConfigFile
    $NewLines = @()
    $KeysSeen = @{}
    foreach ($Line in $Lines) {
        $Parts = $Line -split "=", 2
        if ($Parts.Count -ge 1 -and $SettingsToApply.ContainsKey($Parts[0])) {
            $Key = $Parts[0]
            $NewLines += "$Key=$($SettingsToApply[$Key])"
            $KeysSeen[$Key] = $true
        } else {
            $NewLines += $Line
        }
    }
    foreach ($Key in $SettingsToApply.Keys) {
        if (!$KeysSeen.ContainsKey($Key)) {
            $NewLines += "$Key=$($SettingsToApply[$Key])"
        }
    }
    Set-Content -Path $ConfigFile -Value $NewLines
} else {
    $NewLines = @("[Controls]")
    foreach ($Key in $SettingsToApply.Keys) {
        $NewLines += "$Key=$($SettingsToApply[$Key])"
    }
    Set-Content -Path $ConfigFile -Value $NewLines
}

# 3. Aplicar perfil customizado específico do jogo (Bloom fix + High GPU accuracy)
$CustomIni = "$EmuladorDir\config\0400486024DEC000.ini"
if (Test-Path $CustomIni) {
    Write-Host "[4/5] Copiando perfil gráfico do jogo..." -ForegroundColor Yellow
    foreach ($App in @("eglantine", "eden")) {
        $CustomTargetDir = "$env:APPDATA\$App\custom"
        if (!(Test-Path $CustomTargetDir)) {
            New-Item -ItemType Directory -Path $CustomTargetDir -Force | Out-Null
        }
        Copy-Item -Path $CustomIni -Destination "$CustomTargetDir\0400486024DEC000.ini" -Force
    }
}

# 4. Instalação dos patches da comunidade (Dynamic FPS + Max Resolution)
$PatchScript = "$EmuladorDir\instalar_patches.py"
if (Test-Path $PatchScript) {
    Write-Host "[5/5] Instalando patches da comunidade (60 FPS e Resolução Máxima)..." -ForegroundColor Yellow
    if (Get-Command python -ErrorAction SilentlyContinue) {
        python "$PatchScript"
    } elseif (Get-Command py -ErrorAction SilentlyContinue) {
        py "$PatchScript"
    } else {
        Write-Host "Aviso: Python não detectado no PATH do Windows. Execute 'python instalar_patches.py' manualmente após instalar o Python." -ForegroundColor Yellow
    }
}

# 5. Criação do inicializador rápido .bat
$BatFile = "$EmuladorDir\jogar_zelda.bat"
$BatContent = @"
@echo off
set "EMU=$EglantineDir\eglantine.exe"
set "GAME=$EmuladorDir\The Legend of Zelda Ocarina of TIme [04004860224DEC000].nup"

if not exist "%EMU%" (
    echo Erro: Emulador nao encontrado em: %EMU%
    pause
    exit /b 1
)

if not exist "%GAME%" (
    echo Aviso: Arquivo do jogo nao encontrado em: %GAME%
    echo Coloque o arquivo .nup na pasta: $EmuladorDir
    pause
    exit /b 1
)

echo Iniciando Zelda Ocarina of Time no Windows...
start "" "%EMU%" -g "%GAME%"
"@

Set-Content -Path $BatFile -Value $BatContent -Encoding ASCII
Write-Host "Inicializador criado em: $BatFile" -ForegroundColor Green
Write-Host "=== Concluído! Tudo pronto para jogar no Windows ===" -ForegroundColor Cyan
