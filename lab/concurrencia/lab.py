#!/usr/bin/env python3
"""NF-SEC-2026-012: two independent PostgreSQL sessions, zero pip dependencies."""
import concurrent.futures
import datetime as dt
import json
import pathlib
import subprocess
import sys
import uuid
ROOT=pathlib.Path(__file__).resolve().parent
BASE=['docker','compose','-f',str(ROOT/'compose.yaml'),'exec','-T','db','psql','-X','-U','nf_test','-d','nf_lab','-v','ON_ERROR_STOP=1','-q','-t','-A']
def db(query):
    p=subprocess.run(BASE+['-c',query],capture_output=True,text=True,timeout=90)
    if p.returncode: raise RuntimeError('Postgres rejected a test: '+p.stderr[-700:])
    return p.stdout.strip()
def reset():
    db('TRUNCATE demo.paciente; UPDATE demo.contador SET ultimo=0;')
def pair(a,b):
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        f=[pool.submit(db,"SELECT demo.registrar(%s::smallint, '%s');"%(d,k)) for d,k in (a,b)]
        return [json.loads(x.result()) for x in f]
def main():
    seed=uuid.uuid4().hex
    cases=[
      ('identidad_repetida_mismo_ds',(6,'TEST-'+seed+'A'),(6,'TEST-'+seed+'A')),
      ('identidad_repetida_diferente_ds',(1,'TEST-'+seed+'B'),(6,'TEST-'+seed+'B')),
      ('identidades_distintas_mismo_ds',(6,'TEST-'+seed+'C'),(6,'TEST-'+seed+'D'))
    ]
    output=[]
    for label,a,b in cases:
        reset()
        rs=pair(a,b)
        new=[x for x in rs if x.get('estado')=='nuevo']
        review=[x for x in rs if x.get('estado')=='requiere_revision']
        count=int(db('SELECT count(*) FROM demo.paciente'))
        unique=db('SELECT count(*)=count(DISTINCT folio) FROM demo.paciente')=='t'
        if label=='identidades_distintas_mismo_ds':
            ok=len(new)==2 and len(review)==0 and count==2 and unique and int(db('SELECT ultimo FROM demo.contador WHERE distrito=6'))==2 and sorted(x['folio'] for x in new)==['NF-DS6-00000001','NF-DS6-00000002']
        else:
            ok=len(new)==1 and len(review)==1 and count==1 and unique and int(db('SELECT sum(ultimo) FROM demo.contador'))==1
        if not ok: raise AssertionError('FAIL: '+label)
        print('PASS',label)
        output.append({'test':label,'status':'PASS','new':len(new),'review':len(review),'rows':count})
    reset()
    if db('SELECT count(*) FROM demo.paciente')!='0': raise AssertionError('Cleanup failed')
    report={'suite':'NF-SEC-2026-012','mode':'local_postgres_simulation','utc':dt.datetime.now(dt.timezone.utc).isoformat(),'passed':len(output),'failed':0,'scenarios':output,'limitations':'Critical section model only; not full Supabase Auth or RLS.'}
    dest=ROOT/'results'/'nf_concurrency_results.json'
    dest.parent.mkdir(exist_ok=True)
    dest.write_text(json.dumps(report,indent=2),encoding='utf8')
    print('Resultado:',dest)
if __name__=='__main__':
    try: main()
    except Exception as e:
        print('FAIL',str(e),file=sys.stderr)
        sys.exit(1)
