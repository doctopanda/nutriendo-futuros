/* Nutriendo Futuros v8. Capas públicas: CLUES (salud) y CCT (escuelas).
 * Selección de distrito OBLIGATORIA. Sin información nominal de pacientes. */
(function(){"use strict";
const map=window.__RD_MAP, L=window.L;
if(!map||!L)return;
const DS=[["01","Hermosillo"],["02","Caborca"],["03","Santa Ana"],["04","Cajeme"],["05","Navojoa"],["06","San Luis Río Colorado"]];
const key=s=>String(s||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").trim().toUpperCase();
const districtByMunicipio={"HERMOSILLO":1,"NOGALES":3,"SAN LUIS RIO COLORADO":6};
const safe=s=>String(s||"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const side=document.querySelector(".sidebar");if(!side)return;
const panel=document.createElement("section");panel.className="nfDistrictPanel";panel.id="nfsDistritalLayers";
panel.innerHTML='<div class="nfLayerEyebrow">NUTRIENDO FUTUROS · SONORA</div>'+
'<h3>Capas por distrito</h3><p>Selecciona un Distrito de Salud para habilitar las capas de establecimientos públicos.</p>'+
'<label class="nfLayerLabel" for="nfDistrict">Distrito sanitario</label>'+
'<select id="nfDistrict"><option value="">Selecciona un distrito…</option>'+DS.map((x,i)=>'<option value="'+(i+1)+'">'+x[0]+' · '+x[1]+'</option>').join("")+'</select>'+
'<label class="nfLayerCheck"><input type="checkbox" id="nfHealth" disabled> 🏥 Centros de salud · CLUES</label>'+
'<label class="nfLayerCheck"><input type="checkbox" id="nfSchools" disabled> 🏫 Escuelas · CCT</label>'+
'<div id="nfLayersStats" class="nfLayersStats">Selecciona un distrito para comenzar.</div>'+
'<details><summary>Importar catálogo oficial de escuelas CCT</summary><p>CSV con CCT, NOMBRE, MUNICIPIO, LATITUD, LONGITUD. El archivo se procesa sólo en memoria, sin subirlo a un servidor.</p><input type="file" id="nfCctFile" accept=".csv,text/csv" disabled><small>Las claves CCT y las coordenadas deben proceder de un catálogo educativo verificado.</small></details>'+
'<a target="_blank" rel="noopener noreferrer" href="https://www.datos.gob.mx/dataset/catalogo_centros_trabajo_sep">Catálogo SEP de centros de trabajo ↗</a>'+
'<p style="margin-bottom:0">Salud: ESTABLECIMIENTO_SALUD_202608 (73 unidades en los 3 municipios disponibles). Otros territorios se habilitarán al integrar polígonos y catálogos aprobados. No se publican casos ni hogares.</p>';
const anchor=side.querySelector("#summary");if(anchor)side.insertBefore(panel,anchor);else side.appendChild(panel);
const sel=panel.querySelector("#nfDistrict"),h=panel.querySelector("#nfHealth"),s=panel.querySelector("#nfSchools"),file=panel.querySelector("#nfCctFile"),status=panel.querySelector("#nfLayersStats");
const schoolLayer=L.layerGroup();let schoolItems=[];
const available=()=>window.__RD_MASTER_FACILITIES||[];
function statusLine(note){const ds=Number(sel.value||0);
 if(!ds){status.textContent="Selecciona un distrito para comenzar.";return;}
 const healthCount=available().filter(f=>districtByMunicipio[key(f.municipio)]===ds).length;
 const schoolCount=schoolItems.filter(f=>districtByMunicipio[key(f.municipio)]===ds).length;
 status.textContent="DS"+String(ds).padStart(2,"0")+" · "+healthCount+" unidades CLUES · "+schoolCount+" escuelas CCT"+(note?" · "+note:"")+(healthCount===0?" · Territorio sin catálogo cargado.":"");
}
function refresh(){const ds=Number(sel.value||0);
 h.disabled=!ds;s.disabled=!ds;file.disabled=!ds;
 if(!ds){h.checked=false;s.checked=false}
 window.NF_SELECTED_DISTRICT=ds;
 window.NF_HEALTH_SELECTED=Boolean(ds&&h.checked);
 if(typeof window.NF_REFRESH_FACILITIES==="function")window.NF_REFRESH_FACILITIES();
 const old=side.querySelector(".healthSection");
 if(old)old.style.display=window.NF_HEALTH_SELECTED?"":"none";
 schoolLayer.clearLayers();
 if(map.hasLayer(schoolLayer))map.removeLayer(schoolLayer);
 if(ds&&s.checked){const schoolIcon=L.divIcon({className:"",html:'<div class="nfSchoolPin">⌂</div>',iconSize:[27,27],iconAnchor:[14,14]});
  for(const row of schoolItems.filter(x=>districtByMunicipio[key(x.municipio)]===ds)){
   const popup="<b>"+safe(row.nombre)+"</b><div>CCT: "+safe(row.cct)+"</div><div>"+safe(row.municipio)+"</div>";
   L.marker([row.lat,row.lon],{icon:schoolIcon,title:"Escuela CCT"}).bindPopup(popup).addTo(schoolLayer);
  }schoolLayer.addTo(map);
 }
 statusLine(s.checked&&!schoolItems.length?"Importa CSV SEP para mostrar escuelas":"");
}
function chooseTerritory(){const mun=document.getElementById("mun");if(!mun)return;
 const ds=Number(sel.value||0),name={1:"Hermosillo",3:"Nogales",6:"San Luis Río Colorado"}[ds]||"";
 const opt=Array.from(mun.options).find(o=>key(o.value||o.textContent)===key(name));
 mun.value=opt&&name?opt.value:"";
 mun.dispatchEvent(new Event("change",{bubbles:true}));
}
sel.addEventListener("change",()=>{h.checked=false;s.checked=false;chooseTerritory();refresh()});
h.addEventListener("change",refresh);s.addEventListener("change",refresh);
function parseCSV(content,sep){const rows=[];let row=[],value="",quoted=false;
 for(let i=0;i<content.length;i++){const ch=content[i];
  if(ch==='"'){if(quoted&&content[i+1]==='"'){value+='"';i++}else quoted=!quoted;continue}
  if(!quoted&&(ch===sep||ch==="\n"||ch==="\r")){if(ch===sep){row.push(value);value="";continue}
    if(ch==="\r"&&content[i+1]==="\n")i++;row.push(value);if(row.some(x=>x.trim()))rows.push(row);row=[];value="";continue}
  value+=ch;
 }row.push(value);if(row.some(x=>x.trim()))rows.push(row);return rows;
}
function normalize(x){const lat=Number(x.LATITUD||x.INMUEBLE_LATITUD),lon=Number(x.LONGITUD||x.INMUEBLE_LONGITUD);
 const cct=String(x.CCT||x.CV_CCT||"").trim(),nombre=String(x.NOMBRE||x.C_NOMBRE||"").trim(),municipio=String(x.MUNICIPIO||x.INMUEBLE_C_NOM_MUN||"").trim();
 if(!/^[A-Z0-9]{6,15}$/i.test(cct)||!nombre||!districtByMunicipio[key(municipio)]||!Number.isFinite(lat)||!Number.isFinite(lon)||lat<26||lat>33||lon< -116||lon> -108)return null;
 return {cct,nombre,municipio,lat,lon};
}
file.addEventListener("change",async e=>{const f=e.target.files?.[0];if(!f)return;
 if(f.size>25*1024*1024){statusLine("CSV supera 25 MB. Filtra primero por Sonora.");return}
 try{const raw=(await f.text()).replace(/^\uFEFF/,""),first=raw.split(/\r?\n/)[0],sep=first.includes(";")&&!first.includes(",")?";":",";
 const rows=parseCSV(raw,sep);if(rows.length<2){statusLine("Archivo vacío");return}
 const heads=rows.shift().map(x=>key(x).replace(/[^A-Z0-9]+/g,"_").replace(/^_|_$/g,""));
 const entries=new Map();for(const vals of rows){const x={};heads.forEach((k,i)=>x[k]=vals[i]||"");const o=normalize(x);if(o)entries.set(o.cct,o)}
 schoolItems=Array.from(entries.values());refresh();statusLine("CSV importado a memoria: "+schoolItems.length+" CCT con coordenadas verificables.");
 }catch(err){statusLine("No fue posible leer el CSV. Comprueba los encabezados.")}
});
window.NF_SELECTED_DISTRICT=0;window.NF_HEALTH_SELECTED=false;refresh();
})();
