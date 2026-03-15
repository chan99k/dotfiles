---
argument-hint: "[url]"
description: "기술 문서 URL을 입력받아 전문 번역(full translation)하고, 서두에 요약을 포함하여 obsidian 문서로 저장"
allowed-tools: playwright
color: blue
---

# article translate - $ARGUMENTS

지정된 문서를 **playwright tool**로 읽고, **전문 번역** + 서두 요약을 포함한 obsidian 문서를 생성합니다.

> `obsidian:summarize-article`과의 차이: summarize는 4000자 요약이 본체이고, translate는 **원문 전체의 빠짐없는 한국어 번역이 본체**이며 서두에 간략한 요약을 부가합니다.

## 작업 프로세스

1. $ARGUMENTS 로 전달된 url의 문서를 playwright tool로 읽어서
   a. url에 접근할 때는 반드시 playwright tool을 사용
   b. 로그인 등이 필요한 경우 fetch tool을 사용하면 url에 접근이 안될 수 있음
2. 아래 규칙(`## 전문 번역 규칙`)에 따라 내용을 정리해서 yaml frontmatter를 포함한 obsidian file로 저장
3. hierarchical tagging 규칙은 `~/.claude/commands/obsidian/add-tag.md` 에 정의된 규칙을 준수
4. 문서에 존재하는 이미지를 ATTACHMENTS 폴더에 저장하고, 이번에 작성하는 옵시디언 문서에 포함시켜줘. **이미지는 하나도 누락 없이 포함**되었으면 해

## yaml frontmatter 예시

```yaml
id: "Coding Challenge #110 - RTFM For Me Agent"
aliases: "코딩 챌린지 #110 - RTFM For Me 에이전트: Redis 기반 RAG 문서 어시스턴트 구축"
tags:
  - ai/rag/vector-search
  - ai/agent/memory-management
  - redis/vector-search/semantic-cache
  - architecture/patterns/retrieval-augmented-generation
  - challenge/coding/full-stack
  - guide/hands-on/step-by-step
author: john-crickett
created_at: 2026-03-09 15:18
related: []
source: https://codingchallenges.fyi/challenges/challenge-rtfm-agent
```

- id: 문서에서 발견한 제목 (원문 그대로)
- aliases: 문서에서 발견한 제목의 한국어 번역
- author: 문서에서 발견한 작성자 (작성자가 명확하지 않으면 공백). 이름은 모두 소문자, 공백은 '-'로 변경
- created_at: obsidian 파일 생성 시점
- source: 문서 url

## 출력 문서 구조

문서는 반드시 아래 순서로 구성:

```markdown
# {원문 제목}

## 1. 하이라이트 / 요약
{전체 내용을 2-3 문단으로 요약. 핵심 개념, 기술, 결론을 간결하게 정리}

---

## 2. 전문 번역

{원문의 모든 섹션을 빠짐없이 번역. 원문의 구조(제목, 소제목, 목록, 코드 블록 등)를 그대로 유지}
```

**핵심 원칙**: 전문 번역 섹션이 문서의 본체이다. 원문의 내용이 누락되어서는 안 된다.

## 전문 번역 규칙

```
You are a professional translator and software development expert with a degree in computer science. You are fluent in English and capable of translating technical documents into Korean. You excel at writing and can effectively communicate key points and insights to developers.

Your task is to **fully translate** the following technical document into Korean. This is NOT a summary — translate the ENTIRE document without omission.

Here is the technical document to be translated:
<technical_document>
{{TECHNICAL_DOCUMENT}}
</technical_document>

Translation requirements:
1. Translate the ENTIRE input text into Korean. Do NOT omit, skip, or summarize any section.
2. For technical terms and programming concepts, include the original English term in parentheses when first mentioned.
   - Include as many original terms as possible.
3. Prioritize literal translation over free translation, but use natural Korean expressions.
4. Use technical terminology and include code examples or diagrams when necessary.
5. Explicitly mark any uncertain parts.
6. Preserve the original document structure: headings, subheadings, lists, code blocks, tables, diagrams.
7. Include ALL code examples from the original document without omission.

Output structure:

## 1. 하이라이트 / 요약
Summarize the entire content in 2-3 paragraphs. This is a brief overview before the full translation.

## 2. 전문 번역
Translate the entire document section by section, preserving the original heading structure.
- Each original heading becomes a Korean heading (with original English in parentheses if helpful).
- Every paragraph, list item, code block, and table must be translated.
- Do NOT add commentary or analysis — translate faithfully.

Important considerations:
- The target audience is a Korean software developer with over 25 years of experience, who obtained a Computer Science degree and a master's degree in Korea, specializing in object-oriented analysis & design and software architecture.
- They have extensive experience in developing and operating various services and products.
- They are particularly interested in sustainable software system development, OOP, developer capability enhancement, Java, TDD, Design Patterns, Refactoring, DDD, Clean Code, Architecture (MSA, Modulith, Layered, Hexagonal, vertical slicing), Code Review, Agile (Lean) Development, Spring Boot, building development organizations, improving development culture, developer growth, and coaching.
- They enjoy studying and organizing related topics for use in work and lectures.
- They cannot quickly read English text or watch English videos.

Constraints:
- Explicitly mark any uncertainties in the translation process.
- Use accurate and professional terminology as much as possible.
- Include ALL code examples and pseudocode from the original document.
- Preserve all diagrams, tables, and structured content.
- Do NOT add your own opinions, analysis, or "conclusion" sections — translate only what exists in the original.
- Self-verify the final translation for completeness before outputting.
- If the document is very long, ensure no sections are skipped. Completeness over brevity.

Remember: The goal is a COMPLETE, FAITHFUL Korean translation — not a summary.
```

## 광고/홍보 콘텐츠 처리

원문에 포함된 광고, 구독 유도, 뉴스레터 홍보, 소셜 미디어 공유 요청 등 본문과 무관한 홍보성 콘텐츠는 번역에서 제외한다. 기술적 내용만 번역에 포함한다.

## 파일명 규칙

Obsidian 파일명은 원문 제목을 그대로 사용한다.

```
00-Inbox/{원문 제목}.md
```

예: `00-Inbox/Coding Challenge 110 - RTFM For Me Agent.md`
