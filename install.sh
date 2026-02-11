#!/bin/bash
set -e

# Descobre o caminho absoluto de onde o script está rodando
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

DEST_DIR="/usr/local/bin"
BIN_DIR="$SCRIPT_DIR/zig-out/bin/packfs"

if ! zig version &> /dev/null; then
    echo "Zig não está instalado ou não foi encontrado."
    echo "Recomenda-se a instalação do Zig 0.13.0"
    exit 1  
fi

echo "Compilando binário packfs..."
cd "$SCRIPT_DIR"
zig build -Doptimize=ReleaseFast
echo "Binário compilado"

echo "Copiando binário packfs para $DEST_DIR"
if ! sudo cp "$BIN_DIR" "$DEST_DIR"; then
    echo "Erro: Falha ao copiar para $DEST_DIR. Verifique as permissões."
    exit 1
fi

if ! packfs --version &> /dev/null; then
    echo "Ocorreu algum erro ao executar 'packfs --version'"
    exit 1
fi

echo "Instalação concluída com sucesso!"
