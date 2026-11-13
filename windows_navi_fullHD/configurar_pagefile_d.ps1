# Script para configurar Memória Virtual (Pagefile) de 16GB a 32GB no Drive D:
# Evita esgotamento de Virtual Commit (35GB+) e travamentos (VK_ERROR_DEVICE_LOST)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "1. Desativando gerenciamento automatico de pagefile..." -ForegroundColor Cyan
    Set-CimInstance -Query "Select * from Win32_ComputerSystem" -Property @{AutomaticManagedPagefile=$False}

    Write-Host "2. Verificando pagefiles existentes..." -ForegroundColor Cyan
    $pfs = Get-CimInstance Win32_PageFileSetting
    
    $dPf = $pfs | Where-Object { $_.Name -like "D:*" }
    if (-not $dPf) {
        Write-Host "Criando novo pagefile em D:\pagefile.sys (16384 MB - 32768 MB)..." -ForegroundColor Green
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="D:\pagefile.sys"; InitialSize=16384; MaximumSize=32768}
    } else {
        Write-Host "Atualizando pagefile existente em D:\ (16384 MB - 32768 MB)..." -ForegroundColor Green
        Set-CimInstance -InputObject $dPf -Property @{InitialSize=16384; MaximumSize=32768}
    }

    # Também garante um pagefile mínimo no C: para crash dumps se necessário
    $cPf = $pfs | Where-Object { $_.Name -like "C:*" }
    if (-not $cPf) {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name="C:\pagefile.sys"; InitialSize=2048; MaximumSize=4096}
    }

    Write-Host "`n[SUCESSO] Pagefile configurado com exito no drive D:\ (16 GB inicial / 32 GB maximo)!" -ForegroundColor Green
    Write-Host "Status atual:" -ForegroundColor Yellow
    Get-CimInstance Win32_PageFileSetting | Format-Table Name, InitialSize, MaximumSize
} catch {
    Write-Host "`n[ERRO] Ocorreu uma falha: $_" -ForegroundColor Red
}

Write-Host "`nPressione qualquer tecla para fechar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
