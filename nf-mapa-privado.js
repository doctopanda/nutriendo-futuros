(()=>{'use strict';
let folioLayer=null;const owner=location.origin;
window.addEventListener('message',function(ev){
 if(ev.origin!==owner||ev.source!==window.parent||!ev.data||ev.data.type!=='NF_PRIVATE_FOLIOS_V1')return;
 const map=window.__RD_MAP;
 if(!map||!window.L)return;
 if(folioLayer){map.removeLayer(folioLayer);folioLayer=null}
 const list=Array.isArray(ev.data.items)?ev.data.items.slice(0,200):[];
 if(!list.length)return;
 folioLayer=L.layerGroup().addTo(map);
 const points=[];
 for(const x of list){
  if(!/^NF-DS[1-6]-[0-9]{8}$/.test(String(x.folio||'')))continue;
  if(x.origen_coordenadas!=='hospital_referencia_verificado')continue;
  if(x.lat==null||x.lon==null||!Number.isFinite(Number(x.lat))||!Number.isFinite(Number(x.lon)))continue;
  const lat=Number(x.lat),lon=Number(x.lon);if(lat<25||lat>33||lon< -115||lon> -108)continue;
  const marker=L.circleMarker([lat,lon],{radius:8,color:'#0e614d',fillColor:x.datos_incompletos?'#f1a34a':'#52a977',fillOpacity:.9,weight:2});
  const div=document.createElement('div');const strong=document.createElement('strong');strong.textContent=x.folio;div.append(strong);const p=document.createElement('p');p.textContent='Unidad institucional verificada · DS'+x.distrito_id+' · '+(x.pendientes||0)+' pendientes';div.append(p);
  marker.bindPopup(div);marker.addTo(folioLayer);points.push([lat,lon]);
 }
 if(points.length&&points.length<150)map.fitBounds(points,{padding:[40,40],maxZoom:11});
});
})();