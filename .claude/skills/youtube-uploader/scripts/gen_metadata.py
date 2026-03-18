#!/usr/bin/env python3
"""Convert 07-upload-package.md to youtubeuploader metadata.json.

Usage:
    python3 gen_metadata.py <upload-package.md> [--output metadata.json]
                                                [--config config.yaml]
                                                [--channel main]
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Optional

try:
    import yaml
except ImportError:
    yaml = None

# YouTube category name → ID mapping
CATEGORY_MAP = {
    "film & animation": "1",
    "autos & vehicles": "2",
    "music": "10",
    "pets & animals": "15",
    "sports": "17",
    "travel & events": "19",
    "gaming": "20",
    "people & blogs": "22",
    "comedy": "23",
    "entertainment": "24",
    "news & politics": "25",
    "howto & style": "26",
    "education": "27",
    "science & technology": "28",
    "nonprofits & activism": "29",
}


def parse_upload_package(content: str) -> dict:
    """Parse 07-upload-package.md content into a metadata dict."""
    result = {}

    # 1. Title: look for **Recommended**: #N pattern first
    rec_match = re.search(r"\*\*Recommended\*\*:\s*#(\d+)", content)
    title_rows = re.findall(
        r'\|\s*(\d+)\s*\|\s*"([^"]+)"\s*\|', content
    )

    if rec_match and title_rows:
        rec_num = rec_match.group(1)
        for num, title in title_rows:
            if num == rec_num:
                result["title"] = title
                break
    if "title" not in result and title_rows:
        result["title"] = title_rows[0][1]

    # 2. Description: extract content between ```...``` under ### 2. Description
    desc_section = re.search(
        r"### 2\.\s*Description\s*\n```\n(.*?)\n```",
        content,
        re.DOTALL,
    )
    if desc_section:
        result["description"] = desc_section.group(1).strip()

    # 3. Tags: collect from Core, Long-tail, Related lines
    tags = []
    for label in ["Core", "Long-tail", "Related"]:
        tag_match = re.search(
            rf"\*\*{label}\*\*:\s*(.+)", content
        )
        if tag_match:
            raw = tag_match.group(1).strip()
            for tag in re.split(r",\s*", raw):
                tag = tag.strip()
                if tag:
                    tags.append(tag)
    if tags:
        result["tags"] = tags

    # 4. Visibility / Schedule from Upload Checklist
    vis_match = re.search(
        r"Visibility setting[:\s]*(.*)", content, re.IGNORECASE
    )
    if vis_match:
        vis_value = vis_match.group(1).strip()
        sched_match = re.search(
            r"scheduled\s+(\S+)", vis_value, re.IGNORECASE
        )
        if sched_match:
            result["privacyStatus"] = "private"
            result["publishAt"] = sched_match.group(1)
        elif "public" in vis_value.lower():
            result["privacyStatus"] = "public"
        elif "unlisted" in vis_value.lower():
            result["privacyStatus"] = "unlisted"
        else:
            result["privacyStatus"] = "private"
    else:
        result["privacyStatus"] = "private"

    # 5. Category from Upload Checklist
    cat_match = re.search(
        r"Category selected[:\s]*(.*)", content, re.IGNORECASE
    )
    if cat_match:
        cat_value = cat_match.group(1).strip()
        cat_lower = cat_value.lower().strip()
        for name, cid in CATEGORY_MAP.items():
            if cat_lower == name or cat_lower.startswith(name):
                result["categoryId"] = cid
                break

    return result


def merge_with_defaults(parsed: dict, defaults: dict) -> dict:
    """Merge parsed metadata with channel defaults. Parsed values take priority."""
    result = dict(parsed)

    field_map = {
        "categoryId": "categoryId",
        "language": "language",
        "license": "license",
    }

    for default_key, result_key in field_map.items():
        if result_key not in result and default_key in defaults:
            result[result_key] = defaults[default_key]

    if "privacyStatus" not in result and "privacy" in defaults:
        result["privacyStatus"] = defaults["privacy"]

    if "playlistIds" not in result and "playlist" in defaults:
        playlist = defaults["playlist"]
        if playlist:
            result["playlistIds"] = (
                [playlist] if isinstance(playlist, str) else playlist
            )

    return result


def load_channel_config(
    config_path: str, channel_name: Optional[str] = None, is_explicit: bool = False
) -> dict:
    """Load channel defaults from config.yaml."""
    if yaml is None:
        if is_explicit:
            print(
                "Error: PyYAML not installed but --config was explicitly provided.",
                file=sys.stderr,
            )
            sys.exit(1)
        else:
            print(
                "Warning: PyYAML not installed. Skipping config merge.",
                file=sys.stderr,
            )
            return {}

    path = Path(config_path).expanduser()
    if not path.exists():
        return {}

    with open(path) as f:
        config = yaml.safe_load(f)

    if not config or "channels" not in config:
        return {}

    ch_name = channel_name or config.get("default_channel", "main")
    channel = config["channels"].get(ch_name, {})
    defaults = channel.get("defaults", {})

    cache_path = channel.get("cache", channel.get("token", ""))
    if cache_path:
        defaults["cache"] = cache_path

    return defaults


def main(argv: Optional[List[str]] = None) -> None:
    parser = argparse.ArgumentParser(
        description="Convert upload-package.md to metadata.json"
    )
    parser.add_argument("input", help="Path to 07-upload-package.md")
    parser.add_argument(
        "--output",
        "-o",
        default=None,
        help="Output JSON path (default: same dir as input)",
    )
    default_config = "~/.config/yt-uploader/config.yaml"
    parser.add_argument(
        "--config",
        "-c",
        default=default_config,
        help="Channel config YAML path",
    )
    parser.add_argument(
        "--channel",
        default=None,
        help="Channel name from config",
    )
    args = parser.parse_args(argv)

    input_path = Path(args.input).expanduser()
    if not input_path.exists():
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    content = input_path.read_text(encoding="utf-8")
    parsed = parse_upload_package(content)

    if not parsed.get("title"):
        print(
            "Error: Could not extract title from upload package",
            file=sys.stderr,
        )
        sys.exit(1)

    if not parsed.get("description"):
        print("Warning: description not found in upload package", file=sys.stderr)

    if not parsed.get("tags"):
        print("Warning: tags not found in upload package", file=sys.stderr)

    is_explicit_config = args.config != default_config
    defaults = load_channel_config(args.config, args.channel, is_explicit_config)
    metadata = merge_with_defaults(parsed, defaults)

    output_path = args.output or str(
        input_path.parent / "metadata.json"
    )
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)

    print(f"Generated: {output_path}")


if __name__ == "__main__":
    main()
