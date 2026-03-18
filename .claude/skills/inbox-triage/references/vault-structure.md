# Obsidian Vault Directory Structure

```
VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault

00-Inbox/          # Unsorted incoming documents (triage target)
01-Projects/       # Active project documentation
  blog/            # Blog articles, drafts, design docs
    drafts/        # Unfinished article drafts (TODO skeletons)
  giftify/         # Giftify backend project docs
  mdd-calculator/  # MDD Calculator project docs
  lxm/             # LXM project docs
  shago/           # SHAGO project docs
  youtube/         # YouTube content docs
02-Areas/          # Ongoing responsibilities (dailies, etc.)
03-Resources/      # Reference material by topic
  databases/
  design-patterns/
  insights/
  java/
  kotlin/
  kubernetes/
  network/
  spring/
  storages/
  textbooks/
04-Archive/        # Completed/deprecated/low-value documents
```

## Project Classification Hints

| Keyword in filename | Target folder |
|---------------------|---------------|
| GIFTIFY, giftify | 01-Projects/giftify |
| BLOG, blog | 01-Projects/blog |
| MDD | 01-Projects/mdd-calculator |
| PORTFOLIO | 01-Projects/{related-project} |
| SHELL, shell, dev reference | 03-Resources/ |
| setup (one-time completed) | 04-Archive |
| Gemini - (AI note) | 04-Archive |
| TODO skeleton (empty body) | 01-Projects/blog/drafts (if blog draft) or 04-Archive |
