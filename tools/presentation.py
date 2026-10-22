"""Offline presentation layer. Charts below use recorded, unmodified results."""
from pathlib import Path
import base64, csv, html, json, re

ROOT=Path(__file__).resolve().parents[1]
OWNER='alejandropedersen123-collab'

def records(path):
    with path.open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))

def style(root):
    assets=root/'docs/assets'
    font=base64.b64encode((assets/'InterVariable.woff2').read_bytes()).decode()
    return '@font-face{font-family:Inter;font-style:normal;font-weight:100 900;font-display:swap;src:url(data:font/woff2;base64,'+font+") format('woff2')}\n"+(assets/'theme.css').read_text(encoding='utf-8')

def mesh(root):
    return '<div class="atmosphere">'+(root/'docs/assets/mesh.svg').read_text(encoding='utf-8')+'</div>'

def instrument(root):
    summary=json.loads((root/'results/summary.json').read_text())
    if root.name=='bearing-watch-matlab':
        data=records(root/'results/test_predictions.csv'); maximum=max(float(r['Score']) for r in data)*1.15
        points=''.join(f'<circle cx="{12+i*396/(len(data)-1):.2f}" cy="{142-float(r["Score"])*120/maximum:.2f}" r="1.9" fill="'+('#b9b9f9' if r['Label']=='healthy' else '#f96bee')+'"/>' for i,r in enumerate(data))
        chart='<svg viewBox="0 0 420 165" role="img" aria-label="Scores de las 206 ventanas de evaluación"><path d="M12 22H408M12 82H408M12 142H408" stroke="#ffffff14"/>'+points+'</svg>'
        return panel('bearing_watch / evaluación',str(summary['testWindows']),'ventanas analizadas',chart,'<span>Sano</span><span>Defecto inducido</span>','CWRU · 4 registros de prueba','Calibración independiente')
    data=records(root/'results/nominal.csv')
    points=' '.join(f'{12+float(r["time"])*24.75:.2f},{142-float(r["position"])*172:.2f}' for r in data[::8])
    chart='<svg viewBox="0 0 420 165" role="img" aria-label="Posición medida durante el ciclo nominal"><path d="M12 30H408M12 86H408M12 142H408" stroke="#ffffff14"/><path d="M24 142V30H148V142H408" stroke="#ffffff36" fill="none" stroke-dasharray="4 5"/><polyline points="'+points+'" fill="none" stroke="#b9b9f9" stroke-width="2.5"/><text x="12" y="162" fill="#c9d5e7" font-size="9">0 s</text><text x="390" y="162" fill="#c9d5e7" font-size="9">16 s</text></svg>'
    nominal=next(r for r in summary['results'] if r['scenario']=='nominal')
    return panel('servo_cell / ciclo nominal',f'{nominal["cycleTime"]:.2f}','segundos por ciclo',chart,'<span>Posición medida</span><span>Recorrido de 0,65 m</span>','Simulink · solver ode4','11 escenarios aprobados')

def panel(label,number,unit,chart,legend,left,right):
    return '<aside class="instrument"><div class="instrument-head"><span>'+label+'</span><span class="dots" aria-hidden="true"><i></i><i></i><i></i></span></div><div class="instrument-main"><div class="instrument-kicker">Resultado local verificado</div><div class="instrument-number">'+number+' <span>'+unit+'</span></div>'+chart+'<div class="legend">'+legend+'</div></div><div class="instrument-foot"><span>'+left+'</span><span>'+right+'</span></div></aside>'

def document(root,title,content,nav,footer):
    license_text=(root/'docs/assets/Inter-LICENSE.txt').read_text(encoding='utf-8')
    return '<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><title>'+html.escape(title)+'</title><!-- Embedded Inter font: '+license_text.replace('--','—')+' --><style>'+style(root)+'</style></head><body><a class="skip" href="#main">Saltar al contenido</a>'+mesh(root)+nav+'<main id="main">'+content+footer+'</main></body></html>'

def page(title,content,script):
    repo='https://github.com/'+OWNER+'/'+ROOT.name
    nav='<div class="topbar"><a class="brand" href="'+repo+'"><span class="brandmark">AP</span>Alejandro Pedersen</a><nav aria-label="Navegación del proyecto"><a class="nav-secondary" href="'+repo+'#readme">Documentación</a><a class="nav-pill" href="'+repo+'">Código en GitHub ↗</a></nav></div>'
    intro,rest=content.split('</header>',1)
    intro=intro.replace('<header>','<header class="hero"><div>',1)
    hero_links='<div class="hero-links"><a class="button" href="#explorar">Explorar la demo <span aria-hidden="true">&nbsp;→</span></a><a href="'+repo+'/blob/main/docs/defensa-es.md">Guía técnica ↗</a></div>'
    content=intro+hero_links+'</div>'+instrument(ROOT)+'</header>'+rest.replace('<section class="card">','<section class="card" id="explorar">',1)
    # Markdown documentation is readable on GitHub; demo data remain embedded offline.
    def source_link(match):
        path=match.group(1)
        path=path[3:] if path.startswith('../') else 'docs/'+path
        return 'href="'+repo+'/blob/main/'+path+'"'
    content=re.sub(r'href="([^":]+\.(?:md|json|csv))"',source_link,content)
    footer='<footer><span>Alejandro Pedersen · Portfolio de automatización<br>MATLAB R2026a Update 5 · Resultados reproducibles</span><span>Código MIT · Inter bajo SIL OFL<br>Creado con asistencia de IA · <a href="'+repo+'/blob/main/docs/design-system.md">Sistema visual</a></span></footer>'
    return document(ROOT,title,content,nav,footer).replace('</body>','<script>'+script+'</script></body>')
