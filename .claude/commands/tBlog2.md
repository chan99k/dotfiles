---
description: Use when a completed workthrough, decision record, or translated technical document needs to be published to the personal Astro blog.
argument-hint: "<file path or filename>"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# tBlog2: Workthrough to Blog Publisher

## MISSION

Transform a workthrough document into an Astro blog post and write it to the blog content directory.
No git commit or deploy -- file creation only.

## VAULT PATH
```
VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/chan99k's vault/chan99k's vault
```

## BLOG PROJECT

- Path: `/Users/chan99/WebstormProjects/chan99k's blog/chan99k.github.io/`
- Content dir: `src/content/blog/`
- Framework: Astro 5 + Netlify

## FRONTMATTER SCHEMA

```yaml
---
title: string        # from first H1 heading (strip markdown syntax)
description: string  # from TL;DR section (first 3 sentences max)
pubDate: "YYYY-MM-DD"
tags: ["category/topic", ...]
draft: false
---
```

Tag vocabulary (hierarchical, extensible):
- `개발/Spring`, `개발/Java`, `개발/TypeScript`, `개발/Kotlin`, `개발/패턴`, etc.
- `디버깅` -- troubleshooting posts
- `아키텍처`, `아키텍처/분산시스템` -- architectural decisions
- `TIL` -- short learning notes
- `의사결정` -- decision records
- `인프라` -- infrastructure, deployment, k8s
- `번역/기술문서` -- translated technical documents

Users can create new tags following the `category/topic` pattern.

## PROCESS

### STEP 1: Locate Source

If `$ARGUMENTS` is provided:
- Absolute path: use directly
- Filename only: search `$VAULT/00-Inbox/` and `$VAULT/03-Resources/` for matching files

If not provided: list recent files from `$VAULT/00-Inbox/`, ask user to select.

### STEP 2: Extract Metadata

Read the file and extract:
1. **title**: First H1 heading text. Strip `# ` prefix and all markdown syntax (inline code, links, bold).
2. **description**: TL;DR section content. Keep up to 3 sentences. If no TL;DR, use `Highlights / Summary` section. If neither exists, ask user.
3. **pubDate**: From filename `YYMMDD` prefix, convert to `20YY-MM-DD`. If date cannot be parsed, use today.
4. **source** (optional): If Obsidian frontmatter has a `source:` field, add `> 원문: [title](url)` line after the H1 heading.

### STEP 3: Generate Slug

Parse filename with regex: `^(\d{6})-([A-Za-z][\w-]*)-(\d{2})-(.+)\.md$`

```
260220-GIFTIFY-01-hv000151-valid-validated-debugging.md
^^^^^^ ^^^^^^^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
date   scope    seq description

Result: 2026-02-20-hv000151-valid-validated-debugging.md
```

Fallback patterns (try in order):
1. `YYMMDD-SCOPE-NN-desc.md` -> `20YY-MM-DD-desc.md`
2. `YYMMDD-SCOPE-desc.md` -> `20YY-MM-DD-desc.md` (no sequence)
3. `YYMMDD-desc.md` -> `20YY-MM-DD-desc.md` (no scope)
4. Free-form filename (e.g., `Saga distributed transactions pattern.md`) -> `{pubDate}-{lowercase-hyphenated-title}.md`
5. Cannot parse -> ask user for desired slug

If target file already exists, ask user: overwrite or append suffix (e.g., `-v2`).

### STEP 4: Suggest Tags

Analyze content keywords and suggest 2-4 tags. Present to user via AskUserQuestion:

```
question: "블로그 태그를 선택해주세요. 제안: [tag1, tag2, tag3]"
header: "Tags"
multiSelect: true
options: [suggested tags + "직접 입력" option]
```

User can select multiple and add custom tags via the Other option.

### STEP 5: Transform Content

Apply these transformations. Preserve all other content unchanged.

**5a. Add frontmatter**

Insert frontmatter block at the very top, followed by a blank line before H1:

```markdown
---
title: "..."
description: "..."
pubDate: "YYYY-MM-DD"
tags: [...]
draft: false
---

# Original H1 heading
```

**5b. References table -> link list**

If a `## References` section contains a markdown table with `| Claim | Source | Credibility |` columns:

Before:
```markdown
| Some claim | [Link Text](url) | High |
```

After:
```markdown
- [Link Text](url) -- Some claim
```

Drop the Credibility column. If table has different columns, preserve as-is.

**5c. Lesson checkboxes -> plain bullets**

Convert both checked and unchecked task list items:
- `- [ ] text` -> `- text`
- `- [x] text` -> `- text`

**5d. Obsidian image syntax -> standard markdown + copy**

Convert Obsidian wiki-link images and copy files:
1. Find all `![[filename.ext]]` patterns in the document
2. Convert to `![alt text](/images/filename.ext)`
3. Copy image files from `$VAULT/_attachments/` to `{BLOG_PATH}/public/images/`
4. If image not found in `_attachments/`, warn user

**5e. Strip Obsidian frontmatter**

Remove the source Obsidian YAML frontmatter (id, aliases, tags, author, created_at, source, etc.) and replace with blog frontmatter schema.

### STEP 6: Write and Report

1. Verify blog content dir exists: `{BLOG_PATH}/src/content/blog/`
2. Write transformed file to: `{BLOG_PATH}/src/content/blog/{slug}`
3. Verify file was written (check existence)
4. Report to user:
   - File path created
   - Frontmatter preview (title, tags, pubDate)
   - Word count
   - "블로그 레포에서 직접 커밋/배포해주세요."

## SOURCE DIRECTORIES

- Primary: `$VAULT/00-Inbox/` (Obsidian vault)
- Legacy: `docs/workthrough/` (workspace, fallback only)

## ERROR HANDLING

- Source not found: list available files in workthrough dir
- No H1 or TL;DR: ask user to provide title/description manually
- Blog dir not accessible: show full path and error message
- File already exists at target: ask user to overwrite or rename
