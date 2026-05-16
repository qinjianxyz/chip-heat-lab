import Link from "next/link";

export default function NotFound() {
  return (
    <section className="doc-layout">
      <h1>Page Not Found</h1>
      <p>
        Return to the Chip Heat Lab design-review cockpit or open the exported
        Rust replay.
      </p>
      <p>
        <Link href="/">Home</Link> · <Link href="/replay">Replay</Link>
      </p>
    </section>
  );
}
