# Script para configurar Memória Virtual (Pagefile) de 16GB a 32GB no Drive D:
# Evita esgotamento de Virtual Commit (35GB+) e travamentos (VK_ERROR_DEVICE_LOST)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "1. Desativando gerenciamento automatico de pagefile..." -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile = $false}
    }

    Write-Host "2. Configurando pagefiles (Memoria Virtual)..." -ForegroundColor Cyan
    
    # Remove entradas existentes para evitar conflitos de instancia no WMI/CIM
    $existing = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if ($existing) {
        $existing | Remove-CimInstance -ErrorAction SilentlyContinue
    }

    # Drive D: Principal para emulador e jogos (16GB inicial - 32GB maximo)
    # [uint32] obrigatorio devido ao schema CIM de Win32_PageFileSetting
    Write-Host "   -> Criando pagefile em D:\pagefile.sys (16384 MB - 32768 MB)..." -ForegroundColor Green
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name        = "D:\pagefile.sys"
        InitialSize = [uint32]16384
        MaximumSize = [uint32]32768
    } | Out-Null

    # Drive C: Minimo para crash dumps do sistema (2GB inicial - 4GB maximo)
    Write-Host "   -> Criando pagefile em C:\pagefile.sys (2048 MB - 4096 MB)..." -ForegroundColor Green
    New-CimInstance -ClassName Win32_PageFileSetting -Property @{
        Name        = "C:\pagefile.sys"
        InitialSize = [uint32]2048
        MaximumSize = [uint32]4096
    } | Out-Null

    Write-Host "`n[SUCESSO] Pagefiles configurados com exito!" -ForegroundColor Green
    Write-Host "Status atual:" -ForegroundColor Yellow
    Get-CimInstance Win32_PageFileSetting | Format-Table Name, InitialSize, MaximumSize
    Write-Host "DICA: Reinicie o computador para que o Windows inicialize os novos arquivos de paginacao." -ForegroundColor Cyan
} catch {
    Write-Host "`n[ERRO] Ocorreu uma falha: $_" -ForegroundColor Red
}

Write-Host "`nPressione qualquer tecla para fechar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
