# API Documentation

## parse_front_matter

```mbt check
///|
test {
  let markdown =
    #|---
    #|slide_theme: sunrise
    #|---
    #|
    #|## Intro
    #|- hello
    #|
  let parsed = parse_front_matter(markdown)
  match parsed {
    Ok(v) => inspect(v.slide_theme, content="sunrise")
    Err(msg) => fail(msg)
  }
}
```

## parse_slides

```mbt check
///|
test {
  let slides = parse_slides("## A\n- one\n\n## B\n- two\n")
  inspect(slides.length(), content="2")
}
```

## render_svg_slides

```mbt check
///|
test {
  let result = render_svg_slides("## A\n- one\n")
  match result {
    Ok(slides) => inspect(slides.length(), content="1")
    Err(msg) => fail(msg)
  }
}
```

## render_slide_deck_page

```mbt check
///|
test {
  let input = DeckRenderInput::new("Demo", "## Intro\n- hello", 0)
  let result = render_slide_deck_page(input)
  match result {
    Ok(html) => inspect(html.contains("<html"[:]), content="true")
    Err(msg) => fail(msg)
  }
}
```
