export const holes = Array.from({length:18},(_,i)=>({number:i+1,par:[4,5,3,4,4,3,5,4,4,4,3,5,4,4,3,4,5,4][i],stroke:[9,3,15,1,11,17,5,13,7,10,16,4,2,12,18,8,6,14][i]}));
export const samplePlayers=[{id:'p1',name:'Alex',hi:12.4},{id:'p2',name:'Jordan',hi:8.1},{id:'p3',name:'Taylor',hi:16.2},{id:'p4',name:'Casey',hi:4.6}];
export const uid=()=>crypto.randomUUID();
export const courseHandicap=(hi,slope,rating,par)=>Math.round(Number(hi)*Number(slope)/113+Number(rating)-Number(par));
export const handicap=(p,round)=>courseHandicap(p.hi,p.tee_slope??round.slope,p.tee_rating??round.rating,p.tee_par??round.par);
export function strokesAt(hcp,strokeIndex){return Math.floor(hcp/18)+(strokeIndex<=((hcp%18)+18)%18?1:0)}
export const netAt=(score,hcp,strokeIndex)=>score==null?null:score-strokesAt(hcp,strokeIndex);
export function totals(round,p){let gross=0,net=0,played=0,points=0; for(const h of round.holes){const s=round.scores[p.id]?.[h.number];if(s==null)continue;played++;gross+=s;const n=netAt(s,handicap(p,round),h.stroke);net+=n;points+=Math.max(0,2+h.par-n)}return {gross,net,played,points,netToPar:net-round.holes.filter(h=>round.scores[p.id]?.[h.number]!=null).reduce((v,h)=>v+h.par,0)}}
export function skins(round){const result=Object.fromEntries(round.players.map(p=>[p.id,0]));let carry=0;let pending=0;for(const h of round.holes){const all=round.players.map(p=>({id:p.id,score:netAt(round.scores[p.id]?.[h.number],handicap(p,round),h.stroke)}));if(all.some(x=>x.score==null))continue;const low=Math.min(...all.map(x=>x.score));const winners=all.filter(x=>x.score===low);if(winners.length===1){result[winners[0].id]+=1+carry;carry=0}else carry++;pending++}return {result,carry,completed:pending}}
export function nassau(round){if(round.players.length!==2)return null;const [a,b]=round.players;const sections=[[1,9],[10,18],[1,18]];return sections.map(([start,end],i)=>{let diff=0,played=0;for(const h of round.holes.filter(h=>h.number>=start&&h.number<=end)){const x=round.scores[a.id]?.[h.number],y=round.scores[b.id]?.[h.number];if(x==null||y==null)continue;played++;const na=netAt(x,handicap(a,round),h.stroke),nb=netAt(y,handicap(b,round),h.stroke);diff+=Math.sign(nb-na)}return {name:['Front 9','Back 9','Overall'][i],diff,played}})}
export function makeRound(){return {id:uid(),name:'Saturday Game',course:'Sample Golf Club',tee:'White',slope:132,rating:71.8,par:72,holes:structuredClone(holes),players:structuredClone(samplePlayers),scores:{},games:['grossSkins'],createdAt:new Date().toISOString(),commissionerToken:uid()}}

// A Nassau unit has its own start/end and match score. Presses are separate matches.
export function matchUnits(round,aId,bId,presses=[] ,handicaps=null){
 const units=[{id:'front',name:'Front',start:1,end:9},{id:'back',name:'Back',start:10,end:18},{id:'overall',name:'Overall',start:1,end:18},...presses.map(p=>({...p,name:`${p.parent} press · H${p.start}`}))];
 return units.map(u=>{let diff=0,played=0;for(let n=u.start;n<=u.end;n++){const h=round.holes[n-1],a=round.scores[aId]?.[n],b=round.scores[bId]?.[n];if(a==null||b==null)continue;const ha=handicaps?.[aId]??handicap(round.players.find(p=>p.id===aId),round),hb=handicaps?.[bId]??handicap(round.players.find(p=>p.id===bId),round);diff+=Math.sign(netAt(b,hb,h.stroke)-netAt(a,ha,h.stroke));played++}return {...u,diff,played,complete:played===u.end-u.start+1,winner:played===u.end-u.start+1?Math.sign(diff):0}})
}
// A press can begin only after a consecutively completed hole in its parent section.
// A team two points down qualifies in Canyon; an individual two holes down qualifies in Pigeon.
export function pressEligible(unit,round){
 if(!unit || unit.complete || Math.abs(unit.diff)<2)return false;
 const next=unit.start+unit.played;
 if(next>unit.end)return false;
 // Avoid initiating a press after a gap in the scorecard.
 return true;
}
export function pressStart(unit){return unit.start+unit.played}

export function payout(units,unitValue,sweep=false){const originals=units.filter(u=>['front','back','overall'].includes(u.id));const decided=units.filter(u=>u.complete);let net=decided.reduce((sum,u)=>sum+u.winner*Number(unitValue),0);const swept=originals.length===3&&originals.every(u=>u.complete&&u.winner!==0&&u.winner===originals[0].winner);if(sweep&&swept)net+=originals[0].winner*Number(unitValue);return {net,swept}}
// Canyon Game: total team handicap difference goes to the higher-course-handicap golfer on the higher-handicap team.
export function canyonHandicaps(round,teamA,teamB){const all=[...teamA,...teamB];const h=Object.fromEntries(all.map(id=>[id,0]));if(teamA.length!==2||teamB.length!==2||new Set(all).size!==4)return h;const raw=id=>handicap(round.players.find(p=>p.id===id),round);const a=teamA.reduce((s,id)=>s+raw(id),0),b=teamB.reduce((s,id)=>s+raw(id),0);if(a===b)return h;const high=a>b?teamA:teamB;const recipient=[...high].sort((x,y)=>raw(y)-raw(x))[0];h[recipient]=Math.abs(a-b);return h}
// Canyon Game: two independent points per hole: lowest net low-ball and lowest net high-ball.
// Ties in either comparison award zero points. A completed Nassau unit uses the point differential.
export function canyonUnits(round,teamA,teamB,presses=[]){
 const h=canyonHandicaps(round,teamA,teamB);
 const units=[{id:'front',name:'Front',start:1,end:9},{id:'back',name:'Back',start:10,end:18},{id:'overall',name:'Overall',start:1,end:18},...presses.map(p=>({...p,name:p.name||`${p.parent} press · H${p.start}`}))];
 return units.map(u=>{
  let diff=0,played=0,pointsA=0,pointsB=0;
  for(let n=u.start;n<=u.end;n++){
   const hole=round.holes.find(x=>x.number===n);
   if(!hole||[...teamA,...teamB].some(id=>round.scores[id]?.[n]==null))continue;
   const pair=ids=>ids.map(id=>netAt(round.scores[id][n],h[id],hole.stroke)).sort((a,b)=>a-b);
   const a=pair(teamA),b=pair(teamB);
   for(let i=0;i<2;i++){
    if(a[i]<b[i]){diff++;pointsA++}
    else if(b[i]<a[i]){diff--;pointsB++}
   }
   played++;
  }
  return {...u,diff,played,pointsA,pointsB,complete:played===u.end-u.start+1,winner:played===u.end-u.start+1?Math.sign(diff):0};
 });
}

// Team dots are recorded independently per hole; disabled dots never affect payout.
export function canyonDotTotals(canyon){
 if(!canyon?.dotsEnabled)return {a:0,b:0,net:0};
 const entries=Object.values(canyon.holeDots||{});
 const a=entries.reduce((n,v)=>n+Math.max(0,Number(v?.a)||0),0);
 const b=entries.reduce((n,v)=>n+Math.max(0,Number(v?.b)||0),0);
 return {a,b,net:(a-b)*Math.max(0,Number(canyon.dotUnit)||0)};
}

// Skins are provisional until all rostered players have entered the hole.
// Ties award no skin, and skins never carry over to another hole.
export function skinLeaders(round,kind='gross',playerIds=round.players.map(p=>p.id)){
 const result=Object.fromEntries(playerIds.map(id=>[id,0]));
 const holes=[];let completed=0;
 for(const h of round.holes){
  const entries=playerIds.map(id=>{
   const player=round.players.find(p=>p.id===id);
   const raw=round.scores[id]?.[h.number];
   return {id,score:raw==null||!player?null:kind==='net'?netAt(raw,handicap(player,round),h.stroke):raw};
  });
  const scored=entries.filter(v=>v.score!=null);
  const final=playerIds.length>0&&scored.length===playerIds.length;
  if(final)completed++;
  const lowest=scored.length?Math.min(...scored.map(v=>v.score)):null;
  const winners=scored.filter(v=>v.score===lowest);
  const winner=winners.length===1?winners[0]:null;
  if(winner)result[winner.id]++;
  holes.push({hole:h.number,winner,final,entered:scored.length,expected:playerIds.length,tied:winners.length>1});
 }
 return {result,carry:0,completed,holes};
}
export function grossSkins(round,playerIds=round.players.map(p=>p.id)){return skinLeaders(round,'gross',playerIds)}
export function netSkins(round,playerIds=round.players.map(p=>p.id)){return skinLeaders(round,'net',playerIds)}

// Match-play Pigeon strokes are relative to the low player, including plus handicaps.
export function pigeonHandicaps(round,aId,bId){
 const a=handicap(round.players.find(p=>p.id===aId),round);
 const b=handicap(round.players.find(p=>p.id===bId),round);
 const low=Math.min(a,b);
 return {[aId]:a-low,[bId]:b-low};
}

// Foursome scoring: one format selected by commissioner for the entire round.
// Each hole is provisional until all four golfers have entered a score.
export function teamStrokePlay(round,players,format='none'){
 if(!round||players.length!==4||format==='none')return {played:0,toPar:0,holes:[]};
 let played=0,toPar=0;const holes=[];
 for(const hole of round.holes){
  const entries=players.map(p=>{const gross=round.scores[p.id]?.[hole.number];return {id:p.id,gross,net:gross==null?null:netAt(gross,handicap(p,round),hole.stroke)}});
  const complete=entries.every(x=>x.gross!=null);
  if(!complete)continue;
  let score,baseline;
  if(format==='gross-net'){
   score=Math.min(...entries.flatMap(a=>entries.filter(b=>b.id!==a.id).map(b=>a.gross+b.net)));
   baseline=2*hole.par;
  }else if(format==='beast'){
   const sorted=[...entries].sort((a,b)=>a.net-b.net);
   const best=sorted[0];
   const bonus=sorted.slice(1).reduce((sum,x)=>sum+Math.max(0,hole.par-x.net),0);
   score=best.net-bonus;
   baseline=hole.par;
  }else{
   score=entries.map(x=>x.net).sort((a,b)=>a-b).slice(0,2).reduce((a,b)=>a+b,0);
   baseline=2*hole.par;
  }
  const relative=score-baseline;
  toPar+=relative;played++;holes.push({hole:hole.number,score,toPar:relative});
 }
 return {played,toPar,holes};
}
