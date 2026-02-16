# svglide.md.mbt

Markdown を H2 (`##`) 区切りで分割し、SVG スライドと HTML deck ページを生成する MoonBit ライブラリです。

## Features

- Front Matter (`slide_theme`) によるテーマ切り替え
- `##` 見出しごとに 1 スライドへ分割
- 純 SVG のスライド出力
- speakerdeck 風の deck HTML 出力
- 利用可能テーマ: `classic`, `sunrise`, `ocean`

## Installation

`moon.pkg` に依存を追加します。

```json
{
  "import": [
    "mizchi/svglide.md.mbt/src"
  ]
}
```

## Quick Start

```mbt
///|
fn main {
  let markdown =
    #|---
    #|slide_theme: sunrise
    #|---
    #|
    #|## Intro
    #|- hello svglide
    #|
    #|## Next
    #|- markdown in
    #|- svg out
    #|

  let input = @lib.DeckRenderInput::new("svglide demo", markdown, 0)

  match @lib.render_slide_deck_page(input) {
    Ok(html) => println(html)
    Err(msg) => println("error: " + msg)
  }
}
```

## Public API

- `available_themes() -> Array[String]`
- `parse_front_matter(markdown) -> Result[FrontMatter, String]`
- `parse_slides(markdown) -> Array[SlideContent]`
- `render_svg_slides(markdown) -> Result[Array[String], String]`
- `render_slide_deck_page(input) -> Result[String, String]`

## Front Matter

`slide_theme` を指定しない場合は `classic` が使われます。

```markdown
---
slide_theme: ocean
---

## Title
- body line
```

## Commands

```bash
just check
just test
just run
just release-check
```
