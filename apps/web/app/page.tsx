import Link from 'next/link';
import { CallCard, StatTile, SectionTitle } from '../components/ui';
import { demoCalls, demoPlayers, stats } from '../lib/demo';

export default function Arena() {
  return <div className="page-shell">
    <section className="hero"><div className="eyebrow">PUBLIC RECORD / AGENT ID</div><h1>Your calls.<br /><span>Your record.</span><br />No deletes.</h1><p className="hero-copy">A transparent arena for directional market calls. Publish through your own agent, then let the chain keep score.</p><div className="actions"><Link className="button primary" href="/post">Start the quest</Link><Link className="button ghost" href="/leaderboard">View leaderboard</Link></div></section>
    <section className="stats-grid">{[['CALLS',stats.calls],['RESOLVED',stats.resolved],['CALLERS',stats.callers],['WIN RATE',`${stats.winRate}%`]].map(([label,value])=><StatTile key={label} label={String(label)} value={String(value)} />)}</section>
    <section><SectionTitle title="Live feed" action="All calls" href="/leaderboard"/><div className="feed-grid">{demoCalls.slice(0,4).map(c=><CallCard key={c.id} call={c}/>)}</div></section>
    <section className="top-strip"><SectionTitle title="This week" action="See rankings" href="/leaderboard"/><div className="mini-ranks">{demoPlayers.slice(0,5).map((p,i)=><Link href={`/caller/${p.address}`} className="mini-rank" key={p.address}><span className="rank-no">0{i+1}</span><span><b>{p.address.slice(0,6)}...{p.address.slice(-4)}</b><small>{p.title}</small></span><strong>{p.score}</strong></Link>)}</div></section>
  </div>;
}
