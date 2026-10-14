# circa-links

Static GitHub Pages site for **`join.ourcirca.com`** — Circa's invitation-link host.

It serves exactly three things:

| Path | What it is |
|---|---|
| `/.well-known/apple-app-site-association` | Associates `/join/` and `/invite/` with the Circa app (`G588ZXG856.com.pinzo.circa`) so iOS opens those links in the app. |
| `/invite/` | Fallback page for the one-time, email-bound invitation. Hands off to `circa://invite?token=…`. |
| `/join/` | Fallback page for the persistent Circle link. Hands off to `circa://join#…`. |

The invitation code lives only in the URL **fragment** (`#…`), which browsers never send to a server. The pages store, log and send nothing; a Content-Security-Policy pinned to the exact inline script/style hashes blocks everything else.

Legacy hosts keep working and are **not** touched by this repo: `bugsybell.github.io` (`/join/`, `/invite/`, the AASA) and `bugsybell.github.io/circa-legal/` (Privacy / Terms).

## Editing

Pages are generated. Edit `tools/page.template.html`, `tools/style.css` or `tools/script.*.js`, then:

```sh
python3 tools/build.py          # rewrites invite/index.html and join/index.html and re-pins the CSP hashes
sh tools/verify-site.sh         # local checks (files, CSP hashes, hand-off logic)
```

## Deploy (one-off)

1. **Create the repo** `bugsybell/circa-links` on GitHub (public — GitHub Pages on a free account needs a public repo; nothing here is secret).
2. **Publish** from this folder:
   ```sh
   cd ~/Desktop/Henry/circa-links
   git init && git add . && git commit -m "Circa invitation link host"
   git branch -M main
   git remote add origin https://github.com/bugsybell/circa-links.git
   git push -u origin main
   ```
3. **Turn on Pages:** repo → *Settings → Pages* → Source **Deploy from a branch**, Branch **main**, folder **/ (root)**. The `CNAME` file already names `join.ourcirca.com`; confirm it shows as the custom domain. (GitHub will say DNS isn't configured yet until step 5 — expected.)
4. *(Recommended)* **Verify the domain** so nobody else can claim it on GitHub: *Your profile → Settings → Pages → Add a domain* → `join.ourcirca.com`; GitHub shows a TXT record — add it in GoDaddy as host `_github-pages-challenge-bugsybell.join` with the value GitHub gives you.
5. **Add the DNS record** in GoDaddy (below). Nothing else changes in DNS.
6. Wait for GitHub's DNS check to pass (minutes to an hour), then tick **Enforce HTTPS** in *Settings → Pages* (certificate is issued automatically).
7. **Verify live:**
   ```sh
   sh tools/verify-site.sh https://join.ourcirca.com
   curl -sS https://app-site-association.cdn-apple.com/a/v1/join.ourcirca.com   # Apple's cached copy — what iOS really uses
   ```
   Apple's CDN can lag the origin by up to ~24 h after first publication.

## The DNS record

In GoDaddy → *My Products → ourcirca.com → DNS → Add New Record*:

| Field | Value |
|---|---|
| Type | **CNAME** |
| Name / Host | **join** |
| Value / Points to | **bugsybell.github.io** |
| TTL | 1 Hour (or default) |

That is the **only** record to add (plus the optional TXT in step 4). Do **not** edit or delete the `@`/`www` records, the MX (Google Workspace), the SPF/DMARC/verification TXT records, or the `send` / `resend._domainkey` records (Resend). `join.ourcirca.com` has no existing record, so nothing is replaced. Do not set a custom domain on the `bugsybell.github.io` user site or the `circa-legal` repo.
