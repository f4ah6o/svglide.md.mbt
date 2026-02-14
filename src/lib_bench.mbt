///|
fn sample_markdown() -> String {
  (
    #|---
    #|slide_theme: classic
    #|---
    #|
    #|## Intro
    #|- One
    #|- Two
    #|
    #|## Design
    #|- content and layout are separated
    #|
    #|## End
    #|- Thanks
    #|
  )
}

///|
test "render svg benchmark" (b : @bench.T) {
  let markdown = sample_markdown()
  b.bench(fn() { ignore(render_svg_slides(markdown)) })
}

///|
test "render deck html benchmark" (b : @bench.T) {
  let input = DeckRenderInput::{
    title: "benchmark",
    markdown: sample_markdown(),
    initial_index: 0,
  }
  b.bench(fn() { ignore(render_slide_deck_page(input)) })
}
