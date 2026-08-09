# Rebuilding front-door-endstate-20260808.docx

From this directory:
1. Extract + render the diagrams (mermaid-cli via npx; use an isolated npm cache to
   sidestep the root-owned ~/.npm — the CLD-00029 class):
   `python3 -c "import re,os; src=open('../front-door-endstate-20260808.md').read(); [open(f'mmd/{n}.mmd','w').write(b) for n,b in zip(['m1-arrivals','m2-fresh-request','m3-designer-lane','m4-second-pass','m5-decision-reentry','m6-executor-lane'], re.findall(r'\x60\x60\x60mermaid\n(.*?)\x60\x60\x60', src, re.S))]"`
   then per file: `npm_config_cache=$PWD/npm-cache npx -y @mermaid-js/mermaid-cli -i mmd/X.mmd -o mmd/X.png -b white -t neutral -w 2600 --scale 2`
2. `python3 build-endstate-docx.py` (expects mmd/*.png beside it; writes the .docx one level up).
Built 2026-08-08, Code session 1b62176a. The .md is the living copy; the .docx is a snapshot.
