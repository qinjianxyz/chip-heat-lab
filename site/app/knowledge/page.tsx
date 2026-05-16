import { groupKbByType, loadKbIndex } from "../../lib/kb";

function label(value: string): string {
  return value.replaceAll("_", " ");
}

export default function KnowledgePage() {
  const entries = loadKbIndex();
  const groups = groupKbByType(entries);

  return (
    <section className="doc-layout knowledge-page">
      <p className="eyebrow">GBrain-ready knowledge system</p>
      <h1>Knowledge Base</h1>
      <p className="lead">
        Chip Heat Lab keeps assumptions, demo explanations, source notes, and
        claim boundaries in markdown so the native app, site, and GBrain import
        path all read the same project memory.
      </p>

      <div className="knowledge-summary">
        <div className="metric">
          <strong>{entries.length}</strong>
          <span>indexed KB pages</span>
        </div>
        <div className="metric">
          <strong>{groups.length}</strong>
          <span>knowledge types</span>
        </div>
        <div className="metric">
          <strong>markdown</strong>
          <span>source of truth</span>
        </div>
      </div>

      {groups.map(([type, group]) => (
        <section className="knowledge-group" key={type}>
          <h2>{label(type)}</h2>
          <div className="knowledge-grid">
            {group.map((entry) => (
              <article className="card knowledge-card" key={entry.id}>
                <div className="kb-meta">
                  <span>{label(entry.claim_level)}</span>
                  <code>{entry.path}</code>
                </div>
                <h3>{entry.title}</h3>
                <p>{entry.summary}</p>
                {entry.sources.length > 0 ? (
                  <div className="source-list">
                    <span>Sources</span>
                    {entry.sources.map((source) => (
                      <code key={source}>{source}</code>
                    ))}
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        </section>
      ))}
    </section>
  );
}
