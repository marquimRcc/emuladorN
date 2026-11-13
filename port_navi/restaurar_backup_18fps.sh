#!/bin/bash
# ==============================================================================
# Script de Restauração para a Versão V2 Estável (18 FPS / 54ms)
# ==============================================================================
set -e

BACKUP_DIR="/home/marcos/Games/Navi_V2_BACKUP_DEFINITIVO_18FPS"
TARGET_DIR="/home/marcos/Games/Navi_V2"

echo "Restaurando backup de 18 FPS de $BACKUP_DIR para $TARGET_DIR..."

if [ ! -d "$BACKUP_DIR" ]; then
    if [ -f "/home/marcos/Games/Navi_V2_BACKUP_DEFINITIVO_18FPS.tar.gz" ]; then
        echo "Extraindo de Navi_V2_BACKUP_DEFINITIVO_18FPS.tar.gz..."
        tar -xzf /home/marcos/Games/Navi_V2_BACKUP_DEFINITIVO_18FPS.tar.gz -C /home/marcos/Games/
        cp -rf "$BACKUP_DIR"/* "$TARGET_DIR/"
    else
        echo "Erro: pasta ou arquivo de backup não encontrado!"
        exit 1
    fi
else
    cp -rf "$BACKUP_DIR"/* "$TARGET_DIR/"
fi

echo "✓ Restauração concluída com sucesso! Configuração de 18 FPS e saves restaurados."
