# human-writing

Skill de opencode para que la salida no tenga las marcas típicas de texto
generado por IA. Basada en
[Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).

## Qué cubre

- léxico y muletillas que delatan a un modelo (inglés y español)
- construcciones: paralelismo negativo, regla de tres, colas de participio,
  verbos inflados, atribuciones vagas, relleno de importancia
- formato: em dash, comillas curvas, emoji, negritas inline, Title Case
- comentarios y docstrings de código
- commits, PRs, issues, README y docs
- autorevisión obligatoria antes de responder

## Instalación

Ya está en `~/.config/opencode/skills/human-writing/`. opencode la descubre al
arrancar.

## Uso

Manual:

```
/skill human-writing
```

Automático: `~/.config/opencode/AGENTS.md` la declara obligatoria, así que se
aplica a todos los modelos y sesiones sin invocarla.

## Verificar que carga

```bash
python -c "import yaml,sys;print(yaml.safe_load(open('$HOME/.config/opencode/skills/human-writing/SKILL.md').read().split('---')[1]))"
```
