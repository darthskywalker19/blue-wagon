import { ThemeToggle } from "@/components/theme-toggle";

const swatches = [
  { name: "Navy", hex: "#0B3A8C", className: "bg-brand-navy" },
  { name: "Blue", hex: "#1D5FE0", className: "bg-brand-blue" },
  { name: "Teal", hex: "#0FA396", className: "bg-brand-teal" },
];

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-10 px-6 py-16">
      <div className="flex w-full max-w-md flex-col gap-8 rounded-2xl border border-border-subtle bg-surface p-8 shadow-(--shadow-elevated)">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm font-medium text-brand-teal">
              Scaffold · Step 1
            </p>
            <h1 className="font-display text-4xl font-bold tracking-[-0.03em] text-brand-navy dark:text-brand-blue-soft">
              Blue Wagon
            </h1>
          </div>
          <ThemeToggle />
        </div>

        <p className="text-muted">
          Project scaffold is running. Brand tokens, font pairing, and the
          persisted light/dark theme are wired up — pages come in later steps.
        </p>

        <ul className="flex gap-4">
          {swatches.map((swatch) => (
            <li key={swatch.name} className="flex flex-col gap-2">
              <span
                className={`h-14 w-20 rounded-lg ${swatch.className} shadow-(--shadow-card)`}
              />
              <span className="text-xs text-muted">
                {swatch.name} {swatch.hex}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </main>
  );
}
