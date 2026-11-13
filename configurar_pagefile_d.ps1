# Script para configurar Memória Virtual (Pagefile) de 16GB a 32GB no Drive D:
# e 2GB a 4GB no Drive C: (para crash dumps do kernel)
# Evita esgotamento de Virtual Commit (35GB+) e travamentos (VK_ERROR_DEVICE_LOST)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "1. Desativando gerenciamento automatico de pagefile..." -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile = $false}
    }

    Write-Host "2. Configurando pagefiles na memoria do sistema..." -ForegroundColor Cyan
    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    
    # Definicao dos pagefiles: D: (16GB - 32GB para jogos/emulador) e C: (2GB - 4GB para dump de kernel)
    [string[]]$pagingFiles = @(
        'D:\pagefile.sys 16384 32768',
        'C:\pagefile.sys 2048 4096'
    )

    Set-ItemProperty -Path $regPath -Name 'PagingFiles' -Value $pagingFiles

    Write-Host "`n[SUCESSO] Pagefiles configurados com exito!" -ForegroundColor Green
    Write-Host "`nConfiguracao gravada para a inicializacao:" -ForegroundColor Yellow
    $atual = (Get-ItemProperty -Path $regPath).PagingFiles
    foreach ($pf in $atual) {
        Write-Host "   -> $pf" -ForegroundColor Cyan
    }

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "ATENCAO: Reinicie o computador para aplicar as alteracoes!" -ForegroundColor Green
    Write-Host "Apos reiniciar, o Windows alocara o arquivo de 16-32GB no D:" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
} catch {
    Write-Host "`n[ERRO] Ocorreu uma falha: $_" -ForegroundColor Red
}

Write-Host "`nPressione qualquer tecla para fechar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
