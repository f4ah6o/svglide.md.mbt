///|
fn main {
  let md =
    #|---
    #|slide_theme: classic
    #|---
    #|
    #|## svglide
    #|- Markdown to SVG slides
    #|
    #|## Separation
    #|- content in markdown
    #|- layout in theme
    #|
  let input = @lib.DeckRenderInput::new("svglide demo", md, 0)
  let html = @lib.render_slide_deck_page(input)
  match html {
    Ok(page) => println(page)
    Err(msg) => println("error: " + msg)
  }
}
