# Compilador LARA

Trabalho da disciplina **Linguagens de Programação II / Compiladores** (INF01083 — UFRGS, 2026/1).

## Integrantes

- Eduarda Waechter
- Joana Campos


## Sobre o projeto

Implementação incremental de um compilador completo para a linguagem **LARA** (*Linguagem Acadêmica Reduzida e Adaptada*), desenvolvida em quatro etapas:

| Etapa | Tema |
|-------|------|
| 1 | Frontend: scanner (flex) + parser (bison) + AST |
| 2 | Geração de TAC básico (expressões e atribuições) |
| 3 | TAC completo (controle de fluxo e funções) |
| 4 | Geração de assembly x86-64 e otimizações |

## Como compilar e executar

```bash
cd etapaN/         # N = número da etapa (1, 2, 3 ou 4)
make               # compila
make test          # executa os testes
./lara < prog.lc   # compila um programa LARA
```

