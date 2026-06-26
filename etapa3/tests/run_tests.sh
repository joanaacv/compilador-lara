#!/usr/bin/env bash
# run_tests.sh — Testes de execução da Etapa 3 (Final)
# INF01083 — Linguagens de Programação II / Compiladores — 2026/1
#
# Para cada programa .lc em tests/valid/:
#   1. Compila para assembly: ./compilador < prog.lc > _test.s
#   2. Monta e linka:         gcc _test.s -o _test_bin -no-pie
#   3. Executa e compara saída com .expected
#
# Dica de depuração: ./compilador -tac < prog.lc  (imprime TAC em vez de asm)
#
# Nota: os testes de execução requerem Linux x86-64 com gcc.
# Em macOS, apenas a geração de assembly é verificada (execução é pulada).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPILER="$SCRIPT_DIR/../compilador"

if [ ! -x "$COMPILER" ]; then
    echo "ERRO: '$COMPILER' não encontrado. Execute 'make' primeiro."
    exit 1
fi

passed=0
failed=0
skipped=0

# Estratégia de execução do assembly x86-64 Linux:
#  - Em Linux: usa gcc nativo + execução direta.
#  - Caso contrário: usa Docker (linux/amd64) com a imagem gcc:bookworm.
LINUX=0
USE_DOCKER=0
if [[ "$(uname)" == "Linux" ]]; then
    LINUX=1
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    USE_DOCKER=1
    DOCKER_IMAGE="gcc:bookworm"
    # Pré-baixa a imagem (silencioso se já existe) para não poluir a saída do primeiro teste.
    if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "[INFO] Baixando imagem Docker $DOCKER_IMAGE (linux/amd64) — primeira execução..."
        docker pull --platform linux/amd64 "$DOCKER_IMAGE" >/dev/null 2>&1 || {
            echo "ERRO: falha ao baixar $DOCKER_IMAGE. Verifique a conexão / Docker Desktop."
            exit 1
        }
    fi
fi

# build_and_run <arquivo.s> <stdout_file>
# Retorna 0 se montagem+link funcionaram (independente do exit code do programa),
# gravando a saída em <stdout_file>. Retorna 2 em erro de link/montagem.
build_and_run() {
    local sfile="$1"
    local outfile="$2"
    if [ "$LINUX" -eq 1 ]; then
        gcc "$sfile" -o /tmp/_test_e3_bin -no-pie 2>/dev/null || return 2
        /tmp/_test_e3_bin > "$outfile" 2>/dev/null
        rm -f /tmp/_test_e3_bin
        return 0
    fi
    # USE_DOCKER: monta dentro de um container linux/amd64.
    # Usa um marker para diferenciar "gcc falhou" de "exit code != 0 do programa".
    docker run --rm --platform linux/amd64 \
        -v "$(dirname "$sfile")":/work -w /work "$DOCKER_IMAGE" \
        bash -c "gcc $(basename "$sfile") -o /tmp/_bin -no-pie 2>/dev/null || exit 99; /tmp/_bin" \
        > "$outfile" 2>/dev/null
    local rc=$?
    [ "$rc" -eq 99 ] && return 2
    return 0
}

echo "=== Testes VÁLIDOS (execução) ==="
for f in "$SCRIPT_DIR/valid/"*.lc; do
    base="${f%.lc}"
    expected="${base}.expected"
    name="$(basename "$f")"

    if [ ! -f "$expected" ]; then
        echo "PULANDO (sem .expected): $name"
        continue
    fi

    # Gera assembly
    "$COMPILER" < "$f" > /tmp/_test_e3.s 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "FALHOU (compilação): $name"
        failed=$((failed+1))
        continue
    fi

    if [ "$LINUX" -eq 0 ] && [ "$USE_DOCKER" -eq 0 ]; then
        echo "SKIP (execução requer Linux ou Docker): $name"
        skipped=$((skipped+1))
        continue
    fi

    # Monta, linka e executa (nativo no Linux, ou via Docker linux/amd64)
    build_and_run /tmp/_test_e3.s /tmp/_test_e3_out
    rc=$?
    if [ "$rc" -eq 2 ]; then
        echo "FALHOU (link/montagem): $name"
        failed=$((failed+1))
        continue
    fi

    # Compara saída
    actual=$(cat /tmp/_test_e3_out)
    expected_val=$(cat "$expected")

    if [ "$actual" = "$expected_val" ]; then
        echo "OK: $name"
        passed=$((passed+1))
    else
        echo "FALHOU: $name"
        echo "  esperado: $(printf '%s' "$expected_val" | head -5)"
        echo "  obtido:   $(printf '%s' "$actual"       | head -5)"
        failed=$((failed+1))
    fi
    rm -f /tmp/_test_e3_out
done

echo ""
echo "=== Testes INVÁLIDOS (devem rejeitar) ==="
for f in "$SCRIPT_DIR/invalid/"*.lc; do
    name="$(basename "$f")"
    "$COMPILER" < "$f" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "OK (rejeitado): $name"
        passed=$((passed+1))
    else
        echo "FALHOU (deveria rejeitar): $name"
        failed=$((failed+1))
    fi
done

rm -f /tmp/_test_e3.s

echo ""
echo "=== Resultado: $passed OK  $failed FALHOU  $skipped SKIP ==="
[ "$failed" -eq 0 ]
