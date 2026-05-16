import type { Metadata } from "next";
import Link from "next/link";
import "./styles.css";

export const metadata: Metadata = {
  title: "Chip Heat Lab",
  description: "Engineering simulation for chip design as a simplified early-design thermal intuition demo."
};

const nav = [
  ["Docs", "/docs"],
  ["Model", "/model"],
  ["Knowledge", "/knowledge"],
  ["Non-Claims", "/non-claims"],
  ["Replay", "/replay"]
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="topbar">
          <Link className="brand" href="/">Chip Heat Lab</Link>
          <nav>
            {nav.map(([label, href]) => (
              <Link key={href} href={href}>{label}</Link>
            ))}
          </nav>
        </header>
        <main>{children}</main>
      </body>
    </html>
  );
}
