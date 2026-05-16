export default function DocsPage() {
  return (
    <article className="doc-layout">
      <h1>Docs</h1>
      <p>
        Chip Heat Lab is a self-contained demo with one Rust solver path, one
        SwiftUI app, one replay site, and one GBrain-importable knowledge base.
      </p>
      <h2>Run Locally</h2>
      <pre><code>{`cargo test --quiet
cargo run --quiet -p chip_heat_cli -- --input scenarios/flagship.json
python3 scripts/generate_kb_index.py
bash scripts/export_snapshots.sh`}</code></pre>
      <h2>App Packaging</h2>
      <p>
        Run `bash scripts/prepare_macos_resources.sh`, then open the Swift
        package in Xcode for signing and archive export.
      </p>
    </article>
  );
}
