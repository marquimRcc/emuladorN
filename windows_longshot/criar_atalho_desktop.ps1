# Script de automacao para criacao de atalho na Area de Trabalho (Windows Nativo)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$icoPath = Join-Path $scriptDir "longshot.ico"
$batPath = Join-Path $scriptDir "jogar_zelda_longshot.bat"

# Diretorios de Area de Trabalho (Padrao e OneDrive)
$desktops = @(
    [Environment]::GetFolderPath("Desktop"),
    "$env:USERPROFILE\OneDrive\Área de Trabalho",
    "$env:USERPROFILE\Desktop"
) | Select-Object -Unique

$sh = New-Object -ComObject WScript.Shell

foreach ($d in $desktops) {
    if (Test-Path $d) {
        $lnkPath = Join-Path $d "Zelda Ocarina of Time - Longshot 3.0.lnk"
        $sc = $sh.CreateShortcut($lnkPath)
        $sc.TargetPath = $batPath
        $sc.WorkingDirectory = $scriptDir
        $sc.IconLocation = "$icoPath,0"
        $sc.Description = "The Legend of Zelda: Ocarina of Time - Longshot 3.0 (Windows Nativo)"
        $sc.Save()
        Write-Output "Atalho criado com sucesso em: $lnkPath"
    }
}

# Notifica o Shell para atualizar o cache de icones
$sig = @"
[DllImport("shell32.dll")]
public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
"@
$shell32 = Add-Type -MemberDefinition $sig -Name "ShellRefresher" -Namespace "Win32" -PassThru
$shell32::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero) # SHCNE_ASSOCCHANGED
Write-Output "Notificacao de atualizacao de icones enviada ao Windows Explorer."
