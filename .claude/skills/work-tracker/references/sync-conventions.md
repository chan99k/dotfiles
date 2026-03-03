# Work Tracker Sync Conventions

## Backlog Item Format (with External Links)

Each backlog item includes an `외부 링크` field for tracking synced external IDs:

```markdown
### N. 항목 제목
- **현상**: 무엇이 문제인지
- **원인 추정**: 왜 발생하는지
- **개선안**: 해결 방안
- **관련 코드**: `파일명.java:라인번호`
- **외부 링크**: GH#123, things://ABC-DEF
- **우선순위**: 높음/중간/낮음
- **상태**: 미착수/진행중/완료
```

## External ID Formats

| System | Format | Example |
|--------|--------|---------|
| GitHub Issues | `GH#<number>` | `GH#42` |
| Things 3 | `things://<uuid>` | `things://ABC-DEF-123` |

## Status Mapping (2-State)

| Backlog Status | GitHub Issue | Things 3 |
|----------------|-------------|----------|
| 미착수 | open | incomplete |
| 진행중 | open | incomplete |
| 완료 | closed | completed |

Note: 미착수 and 진행중 both map to open/incomplete externally.
The distinction only exists in the local backlog.

## Sync Direction by Mode

### start (Session Start - Pull Bias)
```
Priority: External -> Local

1. Read external systems for new/changed items
2. Compare with local backlog
3. Present diff to user:
   - NEW: Items in external but not in local
   - CHANGED: Status differs between local and external
   - GONE: Items closed/completed externally but open locally
4. Apply changes only after user confirmation
```

### add (Mid-Session - Bidirectional)
```
Priority: Local + External simultaneously

1. User describes new item
2. Create in local backlog with next available number
3. Create in selected external system(s)
4. Record external IDs in backlog item's 외부 링크 field
```

### end (Session End - Push Bias)
```
Priority: Local -> External

1. Scan local backlog for items changed during session
2. Compare with external state
3. Present diff to user:
   - COMPLETED: Items marked 완료 locally but still open externally
   - NEW: Items added locally without external links
   - MODIFIED: Items with changed priority/description
4. Apply changes only after user confirmation
```

### sync (Full Bidirectional)
```
1. Execute 'start' flow (pull)
2. Execute 'end' flow (push)
3. Resolve any remaining discrepancies interactively
```

## Conflict Resolution

When both local and external have changed:
- ALWAYS present both versions to the user
- Show a clear comparison table
- Ask which version to keep (or how to merge)
- Never auto-resolve conflicts

Example conflict presentation:
```
[충돌] #42 닉네임 무시 버그
  로컬:  상태=완료, 우선순위=높음
  외부:  GH#123 open, label=bug
  --> 어느 쪽을 반영할까요? (로컬/외부/건너뛰기)
```

## Context Detection Logic

```
1. Check CWD and parent directories for .git
   - Follow symlinks when searching
   - git rev-parse --show-toplevel

2. If .git found:
   MODE = PROJECT
   - SSoT: .serena/memories/*.md (backlog files)
   - If no .serena/memories, check docs/backlog.md
   - External: GitHub Issues (via gh CLI)
   - Supplementary: Things 3 (for personal reminders)

3. If no .git:
   MODE = PERSONAL
   - Primary: Things 3 (via MCP)
   - No local backlog file (Things IS the source)
```

## GitHub Issues Integration (gh CLI)

### Reading Issues
```bash
gh issue list --state open --json number,title,labels,state,body --limit 100
gh issue list --state closed --json number,title,labels,state,body --limit 50
```

### Creating Issues
```bash
gh issue create --title "제목" --body "본문" [--label "bug,priority:high"]
```

### Closing Issues
```bash
gh issue close <number> --comment "완료: <reason>"
```

### Label Convention for Priority
- `priority:high` -> 높음
- `priority:medium` -> 중간
- `priority:low` -> 낮음

## Things 3 Integration (MCP)

### Reading Todos
- `mcp__things__get_todos` - all todos
- `mcp__things__search_todos` - search by text
- `mcp__things__search_advanced` - filter by status/tag/date

### Creating Todos
- `mcp__things__add_todo` with:
  - title: backlog item title
  - notes: full backlog content (현상, 원인, 개선안)
  - tags: ["work-tracker", project-name]
  - when: "today" for 진행중, "anytime" for 미착수

### Updating Todos
- `mcp__things__update_todo` with:
  - completed: true for 완료
  - when: "today" when starting work

### Tag Convention
- `work-tracker` tag on all synced items
- Project-specific tag (e.g., `giftify`, `personal`)
