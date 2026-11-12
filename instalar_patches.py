#!/usr/bin/env python3
"""
Instalador de Patches da Comunidade para:
The Legend of Zelda: Ocarina of Time (Switch 2 / Remake)
Title ID: 0400486024DEC000
Build ID: E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348

Patches incluídos:
1. Max Resolution:
   - Desativa a lógica de DRS (Dynamic Resolution Scaling) que rebaixa
     a resolução interna para 480p/384p quando há oscilação de GPU,
     mantendo a renderização 3D nítida na resolução máxima nativa.
2. FPS Unlock / Dynamic FPS:
   - Substitui a divisão estática de tempo de quadro por uma rotina dinâmica
     acoplada ao contador de clock do sistema (cntpct_el0 / cntfrq_el0)
     com filtro de suavização temporal.
   - Elimina as quedas abruptas para 20 FPS (double/triple-buffering snap)
     e permite que o jogo rode de 10 FPS até 120+ FPS em tempo real 1:1,
     sem acelerar a física ou desacelerar o jogo.
"""

from pathlib import Path
import os
import struct
import sys

TITLE_ID = "0400486024DEC000"
BUILD_ID = "E0F3CCFAF50065AE4EA01EB5AEB13B1A45DA3348"
NSO_HEADER_SIZE = 0x100

# 1. Patch: Max Resolution
# Pula a checagem de downscaling DRS no módulo 'main'
MAX_RES_OFFSET = 0x805BD0
MAX_RES_BYTES = bytes([0x0F, 0x02, 0x00, 0x14])  # B +0x83C (salta DRS)

# 2. Patch: FPS Unlock / Dynamic FPS
# Gancho no cálculo de delta do motor de jogo
DYNAMIC_FPS_HOOK_OFFSET = 0x6E6CC4
DYNAMIC_FPS_HOOK_BYTES = bytes([0x4F, 0x7D, 0xD5, 0x94])  # bl +0x355F53C -> 0x3C46200

# Rotina de interpolação e adaptação dinâmica inserida no padding executável (128 bytes)
DYNAMIC_FPS_CAVE_OFFSET = 0x3C46200
DYNAMIC_FPS_HEAD = bytes([
    0x28, 0x18, 0x20, 0x1E, 0xCA, 0x92, 0x00, 0xB0, 0x4A, 0x01, 0x38, 0x91, 0x2B, 0xE0, 0x3B,
    0xD5, 0x4C, 0x01, 0x40, 0xF9, 0x4B, 0x01, 0x00, 0xF9, 0xCC, 0x02, 0x00, 0xB4, 0x6B, 0x01,
    0x0C, 0xCB, 0x0D, 0xE0, 0x3B, 0xD5, 0x4E, 0x01, 0x80, 0xD2, 0xAE, 0x09, 0xCE, 0x9A, 0x7F,
    0x01, 0x0E, 0xEB, 0xCB, 0x81, 0x8B, 0x9A, 0x4C, 0x05, 0x40, 0xF9, 0x4C, 0x00, 0x00, 0xB5,
    0xEC, 0x03, 0x0B, 0xAA, 0x6E, 0x01, 0x0C, 0xCB, 0x8C, 0x0D, 0x8E, 0x8B, 0x4C, 0x05, 0x00,
    0xF9, 0x82, 0x01, 0x23, 0x9E, 0xA3, 0x01, 0x23, 0x9E, 0x42, 0x18, 0x23, 0x1E, 0x42, 0x08
])
DYNAMIC_FPS_TAIL = bytes([
    0x21, 0x1E, 0xE3, 0x00, 0x00, 0x1C, 0x42, 0x68, 0x23, 0x1E, 0xC3, 0x00, 0x00, 0x1C, 0x42,
    0x78, 0x23, 0x1E, 0x48, 0x40, 0x20, 0x1E, 0xC0, 0x03, 0x5F, 0xD6, 0x1F, 0x20, 0x03, 0xD5,
    0x0A, 0xD7, 0xA3, 0x3C, 0x00, 0x00, 0xC0, 0x40
])
DYNAMIC_FPS_ROUTINE = DYNAMIC_FPS_HEAD + DYNAMIC_FPS_TAIL
assert len(DYNAMIC_FPS_ROUTINE) == 128


def create_ips32(records):
    """
    Constrói um arquivo binário no formato IPS32 compatível com o PatchManager do Eglantine / Eden.
    records: lista de tuplas (module_offset, bytes_data)
    """
    blob = bytearray(b"IPS32")
    for mod_offset, data in sorted(records, key=lambda x: x[0]):
        nso_offset = mod_offset + NSO_HEADER_SIZE
        blob.extend(struct.pack(">IH", nso_offset, len(data)))
        blob.extend(data)
    blob.extend(b"EEOF")
    return bytes(blob)


def verify_ips32(blob, expected_records):
    """Valida a integridade do binário IPS32 gerado."""
    if not blob.startswith(b"IPS32"):
        raise ValueError("Header IPS32 inválido")
    if not blob.endswith(b"EEOF"):
        raise ValueError("Terminador EEOF ausente")
    
    pos = 5
    parsed = []
    while pos < len(blob) - 4:
        offset, size = struct.unpack_from(">IH", blob, pos)
        pos += 6
        data = blob[pos:pos + size]
        pos += size
        parsed.append((offset - NSO_HEADER_SIZE, data))
    
    assert parsed == sorted(expected_records, key=lambda x: x[0]), "Registros IPS32 divergentes"
    return True


def install_patch(target_dirs, mod_name, records):
    ips_data = create_ips32(records)
    verify_ips32(ips_data, records)
    
    for base_dir in target_dirs:
        mod_exefs = base_dir / TITLE_ID / mod_name / "exefs"
        mod_exefs.mkdir(parents=True, exist_ok=True)
        ips_file = mod_exefs / f"{BUILD_ID}.ips"
        ips_file.write_bytes(ips_data)
        print(f"  [✓] Instalado: {ips_file} ({len(ips_data)} bytes)")


def main():
    home = Path.home()
    if sys.platform == "win32":
        appdata = Path(os.environ.get("APPDATA", home / "AppData" / "Roaming"))
        target_load_dirs = [
            appdata / "eden" / "load",
            appdata / "eglantine" / "load"
        ]
    else:
        target_load_dirs = [
            home / ".local/share/eden/load",
            home / ".local/share/eglantine/load"
        ]
    
    print("=" * 60)
    print("Instalando Patches da Comunidade para:")
    print(f"Title ID: {TITLE_ID}")
    print(f"Build ID: {BUILD_ID}")
    print("=" * 60)
    
    # 1. Instalar Max Resolution
    print("\n1. Aplicando Mod: Max_Resolution...")
    max_res_records = [(MAX_RES_OFFSET, MAX_RES_BYTES)]
    install_patch(target_load_dirs, "Max_Resolution", max_res_records)
    
    # 2. Instalar FPS Unlock (Dynamic FPS)
    print("\n2. Aplicando Mod: FPS_Unlock (Dynamic FPS)...")
    fps_records = [
        (DYNAMIC_FPS_HOOK_OFFSET, DYNAMIC_FPS_HOOK_BYTES),
        (DYNAMIC_FPS_CAVE_OFFSET, DYNAMIC_FPS_ROUTINE)
    ]
    install_patch(target_load_dirs, "FPS_Unlock", fps_records)
    
    print("\n" + "=" * 60)
    print("Todos os patches da comunidade foram instalados com sucesso!")
    print("=" * 60)


if __name__ == "__main__":
    main()
