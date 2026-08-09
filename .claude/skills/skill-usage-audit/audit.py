#!/usr/bin/env python3
"""스킬 사용량 감사 — 세션 트랜스크립트에서 Skill 호출 사실만 집계한다.

판정(보관/삭제/통합/설명개선)은 하지 않는다. 판정은 스킬의 몫이다.
데이터 소스는 ~/.claude/telemetry/ 가 아니다 — 그쪽은 등록 이벤트이자
전송 실패분만 남아 사용량 신호가 없다. 실제 호출은 트랜스크립트에만 있다.
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

CLAUDE_HOME = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
PROJECTS_DIR = CLAUDE_HOME / "projects"
SKILLS_DIR = CLAUDE_HOME / "skills"
ARCHIVE_LEDGER = SKILLS_DIR / "_archive" / "ARCHIVED.json"


DOTFILES_SKILLS = Path.home() / "dotfiles" / ".claude" / "skills"
AGENTS_SKILLS = Path.home() / ".agents" / "skills"


def owner_of(real_path):
    """스킬의 소유처. 아카이브 절차가 소유처마다 다르다.

    dotfiles : 심링크 제거 + dotfiles 내 이동. 되돌리기 쉬움.
    agents   : 크로스 런타임 공유물. 다른 런타임이 쓰고 있을 수 있음.
    plugin   : 마켓플레이스 소유. 옮겨도 갱신 시 되살아난다 -> 아카이브 불가.
    """
    s = str(real_path)
    if s.startswith(str(DOTFILES_SKILLS)):
        return "dotfiles"
    if s.startswith(str(AGENTS_SKILLS)):
        return "agents"
    if "/plugins/" in s:
        return "plugin"
    return "other"


def installed_skills():
    """~/.claude/skills 의 개인 스킬 목록. 이름 -> 실체 경로."""
    out = {}
    if not SKILLS_DIR.is_dir():
        return out
    for entry in SKILLS_DIR.iterdir():
        if entry.name.startswith(".") or entry.name == "_archive":
            continue
        if not (entry / "SKILL.md").is_file():
            continue
        out[entry.name] = entry.resolve()
    return out


def archived_skills():
    """아카이브 대장. 이름 -> 아카이브 시각.

    아카이브된 스킬은 그 시점부터 호출이 0이 되는 게 당연하다.
    대장 없이 재측정하면 자기실현적으로 '역시 안 쓰인다'가 나온다.
    """
    if not ARCHIVE_LEDGER.is_file():
        return {}
    try:
        return json.loads(ARCHIVE_LEDGER.read_text())
    except (json.JSONDecodeError, OSError):
        return {}


def scan_invocations(since=None):
    """트랜스크립트에서 Skill tool_use 를 긁는다.

    returns: 이름 -> {"calls": n, "first": ts, "last": ts, "sessions": set}
    """
    stats = defaultdict(lambda: {"calls": 0, "first": None, "last": None, "sessions": set()})
    if not PROJECTS_DIR.is_dir():
        return stats

    for path in PROJECTS_DIR.rglob("*.jsonl"):
        try:
            with path.open(errors="ignore") as fh:
                for line in fh:
                    # 값싼 사전 필터 — 5900개 파일을 파싱하지 않기 위해
                    if '"Skill"' not in line:
                        continue
                    try:
                        rec = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    msg = rec.get("message") or {}
                    content = msg.get("content")
                    if not isinstance(content, list):
                        continue
                    ts = rec.get("timestamp", "")
                    if since and ts and ts < since:
                        continue
                    for block in content:
                        if not isinstance(block, dict):
                            continue
                        if block.get("type") != "tool_use" or block.get("name") != "Skill":
                            continue
                        name = (block.get("input") or {}).get("skill")
                        if not name:
                            continue
                        s = stats[name]
                        s["calls"] += 1
                        s["sessions"].add(rec.get("sessionId") or path.stem)
                        if ts:
                            if s["first"] is None or ts < s["first"]:
                                s["first"] = ts
                            if s["last"] is None or ts > s["last"]:
                                s["last"] = ts
        except OSError:
            continue
    return stats


def cross_references(skills):
    """다른 스킬 문서가 이 스킬을 참조하는 횟수.

    0회 호출이 곧 무용은 아니다. 하위 스킬로 참조되는 스킬은
    Skill 툴을 거치지 않고 본문에서 인용되어 실행될 수 있다.
    """
    refs = defaultdict(set)
    docs = []
    for name, real in skills.items():
        for md in real.rglob("*.md"):
            try:
                docs.append((name, md.read_text(errors="ignore")))
            except OSError:
                continue
    for name in skills:
        pattern = re.compile(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])")
        for owner, text in docs:
            if owner == name:
                continue
            if pattern.search(text):
                refs[name].add(owner)
    return refs


def days_since(ts):
    if not ts:
        return None
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except ValueError:
        return None
    return (datetime.now(timezone.utc) - dt).days


def build_report(days=None):
    since = None
    if days:
        since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    skills = installed_skills()
    archived = archived_skills()
    stats = scan_invocations(since)
    refs = cross_references(skills)

    rows = []
    for name, real in sorted(skills.items()):
        s = stats.get(name, {"calls": 0, "first": None, "last": None, "sessions": set()})
        # 참조자에 그 참조자의 호출수를 붙인다. 방향("A가 나를 참조")과
        # 그 참조자가 살아있는지를 한 칸에서 동시에 읽히게 하기 위함.
        cited_by = sorted(
            ({"skill": r, "calls": stats.get(r, {}).get("calls", 0)} for r in refs.get(name, ())),
            key=lambda x: -x["calls"],
        )
        rows.append({
            "skill": name,
            "owner": owner_of(real),
            "calls": s["calls"],
            "sessions": len(s["sessions"]),
            "first_used": (s["first"] or "")[:10] or None,
            "last_used": (s["last"] or "")[:10] or None,
            "days_idle": days_since(s["last"]),
            "cited_by": cited_by,
            "live_citers": [c["skill"] for c in cited_by if c["calls"] > 0],
            "path": str(real),
        })

    # 설치돼 있지 않은데 호출된 것 — 플러그인/내장 스킬
    external = sorted(
        ({"skill": n, "calls": v["calls"], "last_used": (v["last"] or "")[:10] or None}
         for n, v in stats.items() if n not in skills),
        key=lambda r: -r["calls"],
    )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "window_days": days,
        "transcript_files": sum(1 for _ in PROJECTS_DIR.rglob("*.jsonl")) if PROJECTS_DIR.is_dir() else 0,
        "personal_skills": rows,
        "external_skills": external,
        "archived": archived,
    }


def print_table(report, unused_only=False):
    rows = report["personal_skills"]
    if unused_only:
        rows = [r for r in rows if r["calls"] == 0]
    rows.sort(key=lambda r: (r["calls"], r["skill"]))

    print(f"# 스킬 사용량 감사  ({report['generated_at'][:10]}"
          + (f", 최근 {report['window_days']}일" if report["window_days"] else ", 전체 기간") + ")")
    print(f"트랜스크립트 {report['transcript_files']}개 / 개인 스킬 {len(report['personal_skills'])}개")
    if report["archived"]:
        print(f"아카이브 대장: {len(report['archived'])}개 (재측정 시 제외 대상)")
    print()
    print(f"{'호출':>4} {'세션':>4} {'유휴일':>6}  {'최종사용':10}  {'소유':8} {'스킬':32} "
          f"이_스킬을_참조하는_스킬(그쪽_호출수)")
    print("-" * 118)
    for r in rows:
        idle = r["days_idle"]
        cite = ", ".join(f"{c['skill']}({c['calls']})" for c in r["cited_by"]) or "-"
        print(f"{r['calls']:>4} {r['sessions']:>4} {(str(idle) if idle is not None else '-'):>6}  "
              f"{(r['last_used'] or '-'):10}  {r['owner']:8} {r['skill']:32} {cite}")

    zero = [r for r in report["personal_skills"] if r["calls"] == 0]
    print()
    print(f"호출 0회: {len(zero)}/{len(report['personal_skills'])}개")
    protected = [r["skill"] for r in zero if r["live_citers"]]
    if protected:
        print(f"  호출 0회지만 살아있는 스킬이 참조 중 → 아카이브 금지: {', '.join(protected)}")
    plugin_owned = [r["skill"] for r in report["personal_skills"] if r["owner"] == "plugin"]
    if plugin_owned:
        print(f"  플러그인 소유 → 아카이브 대상 아님(비활성화로만 처리): {', '.join(plugin_owned)}")
    agents_owned = [r["skill"] for r in report["personal_skills"] if r["owner"] == "agents"]
    if agents_owned:
        print(f"  ~/.agents 공유물 → 다른 런타임 사용 여부 확인 필요: {', '.join(agents_owned)}")


def verdict(name, premise, did_work, superseded_by):
    """관측 사실 -> 판정. 판정을 문서 표에 적어두면 회차마다 다르게 해석되므로
    여기서 계산해 내려준다. 판단 층은 사실만 답하고 판정은 받는다.
    """
    report = build_report()
    row = next((r for r in report["personal_skills"] if r["skill"] == name), None)
    if row is None:
        return 1, f"'{name}' 은 설치된 개인 스킬이 아니다."

    if row["owner"] == "plugin":
        return 0, f"판정: keep — {name} 은 플러그인 소유. 아카이브 대상이 아니다(비활성화로 처리)."
    if row["owner"] == "agents":
        return 0, (f"판정: needs-decision — {name} 은 ~/.agents 공유물. "
                   "다른 런타임 사용 여부는 여기서 알 수 없다. 사용자에게 넘겨라.")
    if row["calls"] > 0 or row["live_citers"]:
        why = f"호출 {row['calls']}회" if row["calls"] else f"살아있는 참조자 {', '.join(row['live_citers'])}"
        return 0, f"판정: keep — {name} ({why})"

    if premise == "unmet":
        return 0, (f"판정: needs-decision — {name}: 전제 미충족(미도입). "
                   "스킬 결함이 아니라 워크플로 도입 여부의 문제다. 사용자에게 넘겨라.")
    if did_work:
        return 0, (f"판정: revise — {name}: 그 작업을 했는데 안 불렸다(트리거 부적합). "
                   "description 을 고칠 일이지 지울 일이 아니다.")
    if superseded_by:
        sup = next((r for r in report["personal_skills"] if r["skill"] == superseded_by), None)
        if sup is None:
            return 1, f"'{superseded_by}' 는 설치된 개인 스킬이 아니다. 대체 주장이 성립하지 않는다."
        if sup["calls"] == 0:
            return 1, (f"대체 불성립: {superseded_by} 도 호출 0회다. 둘 다 안 쓰이는 것이지 대체가 아니다.\n"
                       f"  {name} 을 미도입/수요소멸 중 무엇인지 다시 판정하라.")
        return 0, f"판정: archive — {name}: {superseded_by}({sup['calls']}회)로 대체됨"

    return 0, f"판정: archive — {name}: 전제 충족인데 그 작업 자체를 하지 않음(수요 소멸)"


def archive(name, reason, force=False):
    """스킬을 아카이브한다. 심링크를 끊는 것이 노출을 끊는 유일한 수단이다.

    거부 조건은 문서가 아니라 여기서 강제한다 — 판단 층이 규칙을 어겨도
    사고가 나지 않도록.
    """
    report = build_report()
    row = next((r for r in report["personal_skills"] if r["skill"] == name), None)
    if row is None:
        return 1, f"거부: '{name}' 은 설치된 개인 스킬이 아니다."
    if row["owner"] == "plugin":
        return 1, (f"거부: '{name}' 은 플러그인 소유({row['path']}).\n"
                   "  옮겨도 마켓플레이스 갱신 시 되살아난다. 플러그인 비활성화로 처리할 것.")
    if row["owner"] != "dotfiles":
        return 1, (f"거부: '{name}' 은 {row['owner']} 소유({row['path']}).\n"
                   "  다른 런타임이 공유 중일 수 있다. 수동으로 확인 후 처리할 것.")
    if row["live_citers"] and not force:
        return 1, (f"거부: '{name}' 을 살아있는 스킬이 참조 중 — "
                   f"{', '.join(row['live_citers'])}.\n  끊으면 그쪽 워크플로가 깨진다.")
    if row["calls"] > 0 and not force:
        return 1, f"거부: '{name}' 은 호출 {row['calls']}회(최종 {row['last_used']}). --force 필요."
    if not reason:
        return 1, "거부: --reason 필수. 근거 없는 아카이브는 나중에 복구 판단을 못 한다."

    link = SKILLS_DIR / name
    src = Path(row["path"])
    dest = DOTFILES_SKILLS.parent / "skills-archive" / name
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return 1, f"거부: 아카이브 위치에 이미 존재 — {dest}"

    src.rename(dest)
    if link.is_symlink():
        link.unlink()

    ledger = archived_skills()
    ledger[name] = {
        "archived_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "reason": reason,
        "calls_at_archive": row["calls"],
        "last_used": row["last_used"],
        "restored_from": str(dest),
    }
    ARCHIVE_LEDGER.parent.mkdir(parents=True, exist_ok=True)
    ARCHIVE_LEDGER.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n")
    return 0, (f"아카이브: {name}\n  {src} -> {dest}\n  심링크 제거: {link}\n"
               f"  복구: mv {dest} {src} && ln -s {src} {link}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--days", type=int, help="최근 N일로 창을 제한 (기본: 전체 기간)")
    ap.add_argument("--json", action="store_true", help="JSON 출력")
    ap.add_argument("--unused-only", action="store_true", help="호출 0회만 표시")
    ap.add_argument("--archive", metavar="NAME", help="스킬 하나를 아카이브 (심링크 제거 + 대장 기록)")
    ap.add_argument("--reason", help="--archive 의 근거. 필수")
    ap.add_argument("--force", action="store_true", help="호출 이력/참조 경고를 무시")
    ap.add_argument("--verdict", metavar="NAME", help="관측 사실을 넣으면 판정을 계산해 준다")
    ap.add_argument("--premise", choices=["met", "unmet"],
                    help="--verdict: 스킬이 요구하는 도구/설정파일이 환경에 있는가")
    ap.add_argument("--did-work", action="store_true",
                    help="--verdict: 그 작업을 실제로 했는데 이 스킬이 안 불렸는가")
    ap.add_argument("--superseded-by", metavar="SKILL",
                    help="--verdict: 같은 일을 하는 다른 스킬 이름")
    args = ap.parse_args()

    if args.verdict:
        if not args.premise:
            print("--premise met|unmet 필수. SKILL.md 의 전제 조건을 확인하고 넣어라.")
            sys.exit(1)
        code, msg = verdict(args.verdict, args.premise, args.did_work, args.superseded_by)
        print(msg)
        sys.exit(code)

    if args.archive:
        code, msg = archive(args.archive, args.reason, args.force)
        print(msg)
        sys.exit(code)

    report = build_report(args.days)
    if args.json:
        json.dump(report, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        print_table(report, args.unused_only)


if __name__ == "__main__":
    main()
