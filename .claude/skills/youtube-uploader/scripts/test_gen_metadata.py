#!/usr/bin/env python3
"""Tests for gen_metadata.py - upload-package.md to metadata.json converter."""

import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
from gen_metadata import parse_upload_package, merge_with_defaults, main


SAMPLE_UPLOAD_PACKAGE = """## Upload Package

### 1. Title Candidates
| # | Title | Type | CTR Rationale |
|---|-------|------|---------------|
| 1 | "쿠버네티스 입문 완벽 가이드" | how-to | 검색 의도 직접 매칭 |
| 2 | "K8s 이것만 알면 된다" | list | 호기심 유발 |

**Recommended**: #1 - 검색 유입 최적화

### 2. Description
```
쿠버네티스를 처음 시작하는 개발자를 위한 완벽 가이드입니다.
Pod, Service, Deployment 핵심 개념을 실습과 함께 배워봅시다.

---
[Timestamps]
00:00 인트로
01:30 Pod란 무엇인가
05:00 Service 이해하기
08:00 Deployment 실습
```

### 3. Tags
**Core**: 쿠버네티스, kubernetes, k8s, DevOps, 컨테이너
**Long-tail**: 쿠버네티스 입문, k8s 튜토리얼, 컨테이너 오케스트레이션
**Related**: 도커, docker, 클라우드네이티브
**Total**: 285/500 chars

### 5. Cards & End Screen
| Timestamp | Type | Target |
|-----------|------|--------|
| 03:00 | card | 도커 기초 영상 |
| 09:30 | end screen | 다음 영상 추천 |

### 6. Subtitle Keywords
쿠버네티스, Pod, Service, Deployment, kubectl

### 7. Upload Checklist
- [x] Title finalized
- [x] Description copied
- [x] Tags entered
- [ ] Thumbnail created & uploaded
- [ ] Cards configured
- [ ] End screen set
- [ ] Subtitle keywords registered
- [ ] Visibility setting: scheduled 2026-03-20T09:00:00+09:00
- [ ] Category selected: Science & Technology
- [ ] Age restriction set: none
"""


class TestParseUploadPackage(unittest.TestCase):
    def test_extracts_recommended_title(self):
        result = parse_upload_package(SAMPLE_UPLOAD_PACKAGE)
        self.assertEqual(result["title"], "쿠버네티스 입문 완벽 가이드")

    def test_extracts_description(self):
        result = parse_upload_package(SAMPLE_UPLOAD_PACKAGE)
        self.assertIn("쿠버네티스를 처음 시작하는", result["description"])
        self.assertIn("00:00 인트로", result["description"])

    def test_extracts_tags(self):
        result = parse_upload_package(SAMPLE_UPLOAD_PACKAGE)
        self.assertIn("쿠버네티스", result["tags"])
        self.assertIn("kubernetes", result["tags"])
        self.assertIn("k8s", result["tags"])
        self.assertIn("쿠버네티스 입문", result["tags"])
        self.assertIn("도커", result["tags"])

    def test_extracts_scheduled_publish(self):
        result = parse_upload_package(SAMPLE_UPLOAD_PACKAGE)
        self.assertEqual(result["publishAt"], "2026-03-20T09:00:00+09:00")

    def test_extracts_category(self):
        result = parse_upload_package(SAMPLE_UPLOAD_PACKAGE)
        self.assertEqual(result["categoryId"], "28")

    def test_no_title_falls_back_to_first_candidate(self):
        md = """## Upload Package

### 1. Title Candidates
| # | Title | Type | CTR Rationale |
|---|-------|------|---------------|
| 1 | "첫 번째 제목" | how-to | reason |

### 2. Description
```
설명
```

### 3. Tags
**Core**: tag1
"""
        result = parse_upload_package(md)
        self.assertEqual(result["title"], "첫 번째 제목")

    def test_missing_schedule_defaults_to_private(self):
        md = """## Upload Package

### 1. Title Candidates
| # | Title | Type | CTR Rationale |
|---|-------|------|---------------|
| 1 | "제목" | how-to | reason |

**Recommended**: #1

### 2. Description
```
설명
```

### 3. Tags
**Core**: tag1
"""
        result = parse_upload_package(md)
        self.assertEqual(result["privacyStatus"], "private")
        self.assertNotIn("publishAt", result)


class TestMergeWithDefaults(unittest.TestCase):
    def test_merge_fills_missing_fields(self):
        parsed = {"title": "제목", "description": "설명", "tags": ["t1"]}
        defaults = {
            "categoryId": "28",
            "language": "ko",
            "license": "youtube",
            "privacy": "private",
        }
        result = merge_with_defaults(parsed, defaults)
        self.assertEqual(result["language"], "ko")
        self.assertEqual(result["license"], "youtube")

    def test_parsed_values_override_defaults(self):
        parsed = {
            "title": "제목",
            "description": "설명",
            "tags": ["t1"],
            "categoryId": "22",
        }
        defaults = {"categoryId": "28", "language": "ko"}
        result = merge_with_defaults(parsed, defaults)
        self.assertEqual(result["categoryId"], "22")

    def test_playlist_from_defaults(self):
        parsed = {"title": "제목", "description": "설명", "tags": ["t1"]}
        defaults = {"playlist": "PLxxxxx"}
        result = merge_with_defaults(parsed, defaults)
        self.assertEqual(result["playlistIds"], ["PLxxxxx"])


class TestMainCLI(unittest.TestCase):
    def test_generates_json_file(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False
        ) as f:
            f.write(SAMPLE_UPLOAD_PACKAGE)
            md_path = f.name

        out_path = md_path.replace(".md", ".json")
        try:
            main([md_path, "--output", out_path])
            with open(out_path) as f:
                data = json.load(f)
            self.assertEqual(data["title"], "쿠버네티스 입문 완벽 가이드")
            self.assertIsInstance(data["tags"], list)
        finally:
            os.unlink(md_path)
            if os.path.exists(out_path):
                os.unlink(out_path)

    def test_merge_with_config_yaml(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False
        ) as f:
            f.write(SAMPLE_UPLOAD_PACKAGE)
            md_path = f.name

        config_dir = tempfile.mkdtemp()
        config_path = os.path.join(config_dir, "config.yaml")
        with open(config_path, "w") as f:
            f.write(
                """channels:
  main:
    name: "메인 채널"
    credentials: "~/.config/yt-uploader/credentials/main.json"
    defaults:
      categoryId: "28"
      language: "ko"
      license: "youtube"
      privacy: "private"
default_channel: main
"""
            )

        out_path = md_path.replace(".md", ".json")
        try:
            main(
                [
                    md_path,
                    "--output",
                    out_path,
                    "--config",
                    config_path,
                    "--channel",
                    "main",
                ]
            )
            with open(out_path) as f:
                data = json.load(f)
            self.assertEqual(data["language"], "ko")
        finally:
            os.unlink(md_path)
            if os.path.exists(out_path):
                os.unlink(out_path)
            os.unlink(config_path)
            os.rmdir(config_dir)


class TestErrorHandling(unittest.TestCase):
    def test_empty_upload_package_exits(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("")
            md_path = f.name
        try:
            with self.assertRaises(SystemExit):
                main([md_path, "--output", "/tmp/test-empty.json"])
        finally:
            os.unlink(md_path)
            if os.path.exists("/tmp/test-empty.json"):
                os.unlink("/tmp/test-empty.json")

    def test_missing_file_exits(self):
        with self.assertRaises(SystemExit):
            main(["/tmp/nonexistent-file.md"])

    def test_korean_tags_preserved(self):
        md = '''## Upload Package

### 1. Title Candidates
| # | Title | Type | CTR Rationale |
|---|-------|------|---------------|
| 1 | "한글 제목 테스트" | how-to | test |

**Recommended**: #1

### 2. Description
```
한글 설명
```

### 3. Tags
**Core**: 쿠버네티스, 도커, 클라우드
**Long-tail**: 쿠버네티스 입문 가이드
'''
        result = parse_upload_package(md)
        self.assertEqual(result["title"], "한글 제목 테스트")
        self.assertIn("쿠버네티스", result["tags"])
        self.assertIn("쿠버네티스 입문 가이드", result["tags"])

    def test_default_output_path(self):
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".md", delete=False, dir="/tmp"
        ) as f:
            f.write(SAMPLE_UPLOAD_PACKAGE)
            md_path = f.name
        expected_output = os.path.join("/tmp", "metadata.json")
        try:
            main([md_path])
            self.assertTrue(os.path.exists(expected_output))
        finally:
            os.unlink(md_path)
            if os.path.exists(expected_output):
                os.unlink(expected_output)


if __name__ == "__main__":
    unittest.main()
