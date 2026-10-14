// Runs each page's inline script against a stubbed DOM and checks the hand-off.
// Usage: bun tools/test-handoff.mjs   (or node)
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
let failures = 0;
const check = (ok, label) => { console.log(`${ok ? "PASS" : "FAIL"}  ${label}`); if (!ok) failures++; };

function run(page, hash) {
  const html = readFileSync(join(root, page, "index.html"), "utf8");
  const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const els = {};
  const el = (id) => (els[id] ??= { id, attrs: {}, style: {}, hidden: id === "broken", textContent: "", listeners: {},
    setAttribute(k, v) { this.attrs[k] = v; }, removeAttribute(k) { delete this.href; delete this.attrs[k]; },
    addEventListener(t, f) { this.listeners[t] = f; } });
  for (const id of ["broken", "copy", "status"]) el(id);
  el("open").href = page === "join" ? "circa://join" : "circa://invite";
  const copied = [];
  const doc = { getElementById: el };
  const loc = { hash, href: `https://join.ourcirca.com/${page}/${hash}` };
  const nav = { clipboard: { writeText: (t) => { copied.push(t); return Promise.resolve(); } } };
  new Function("document", "location", "navigator", script)(doc, loc, nav);
  return { els, copied };
}

const T = "a".repeat(64);
let r = run("invite", "#" + T);
check(r.els.open.href === `circa://invite?token=${T}`, "invite page hands the fragment token to circa://invite?token=");
check(r.els.broken.hidden === true, "…and shows no 'incomplete' warning");
r = run("join", "#" + T);
check(r.els.open.href === `circa://join#${T}`, "join page hands the fragment token to circa://join#");
await r.els.copy.listeners.click();
check(r.copied[0] === `https://join.ourcirca.com/join/#${T}`, "copy button copies the page's own link");
for (const page of ["invite", "join"]) {
  for (const bad of ["", "#", "#short", "#" + "a".repeat(200), "#abc def ghi jkl mno pqr", "#<script>alert(1)</script>", "#" + "a".repeat(20) + "&x=1", "#" + "a".repeat(20) + "/../x"]) {
    r = run(page, bad);
    check(r.els.open.href === undefined && r.els.broken.hidden === false, `${page}: malformed code ${JSON.stringify(bad.slice(0, 24))} → no hand-off, 'incomplete' shown`);
  }
}
console.log(failures ? `\n${failures} FAILED` : "\nALL PASSED");
process.exit(failures ? 1 : 0);
