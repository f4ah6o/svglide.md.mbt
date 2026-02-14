///|
test "available themes include ocean" {
  inspect(available_themes().contains("ocean"), content="true")
}

///|
test "parse front matter" {
  let markdown =
    #|---
    #|slide_theme: sunrise
    #|---
    #|
    #|## Intro
    #|- hello
    #|
  let parsed = parse_front_matter(markdown)
  inspect(
    parsed,
    content="Ok({slide_theme: \"sunrise\", body: \"\\n## Intro\\n- hello\\n\"})",
  )
}

///|
test "parse slides by h2" {
  let markdown =
    #|## One
    #|- alpha
    #|
    #|## Two
    #|- beta
    #|
  let slides = parse_slides(markdown)
  inspect(slides.length(), content="2")
  inspect(slides[0].title, content="One")
  inspect(slides[1].title, content="Two")
}

///|
test "render svg slides" {
  let markdown =
    #|## Intro
    #|- hello
    #|
    #|## End
    #|- bye
    #|
  let result = render_svg_slides(markdown)
  match result {
    Ok(svgs) => {
      inspect(svgs.length(), content="2")
      inspect(svgs[0].contains("<svg"[:]), content="true")
      inspect(svgs[0].contains("Intro"[:]), content="true")
    }
    Err(msg) => fail("unexpected render error: " + msg)
  }
}

///|
test "render slide deck page" {
  let markdown =
    #|---
    #|slide_theme: classic
    #|---
    #|
    #|## Slide A
    #|- point
    #|
    #|## Slide B
    #|- point
    #|
  let input = DeckRenderInput::new("Deck", markdown, 1)
  let page = render_slide_deck_page(input)
  match page {
    Ok(html) => {
      inspect(html.contains("<html"[:]), content="true")
      inspect(html.contains("let idx=1;"[:]), content="true")
      inspect(html.contains("Slide B"[:]), content="true")
    }
    Err(msg) => fail("unexpected deck error: " + msg)
  }
}
