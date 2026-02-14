///|
pub struct SlideContent {
  title : String
  lines : Array[String]
} derive(Show, Eq)

///|
pub struct FrontMatter {
  slide_theme : String
  body : String
} derive(Show, Eq)

///|
pub struct DeckRenderInput {
  title : String
  markdown : String
  initial_index : Int
} derive(Show, Eq)

///|
pub fn DeckRenderInput::new(
  title : String,
  markdown : String,
  initial_index : Int,
) -> DeckRenderInput {
  { title, markdown, initial_index }
}

///|
priv struct SlideTheme {
  id : String
  name : String
  width : Int
  height : Int
  background : String
  panel : String
  title_color : String
  body_color : String
  accent : String
  title_size : Int
  body_size : Int
  line_height : Int
  padding_x : Int
  padding_y : Int
}

///|
pub fn available_themes() -> Array[String] {
  ["classic", "sunrise", "ocean"]
}

///|
fn theme_by_id(theme_id : String) -> SlideTheme? {
  match theme_id {
    "classic" =>
      Some({
        id: "classic",
        name: "Classic",
        width: 1600,
        height: 900,
        background: "#0f172a",
        panel: "#111827",
        title_color: "#e2e8f0",
        body_color: "#cbd5e1",
        accent: "#38bdf8",
        title_size: 64,
        body_size: 34,
        line_height: 56,
        padding_x: 120,
        padding_y: 110,
      })
    "sunrise" =>
      Some({
        id: "sunrise",
        name: "Sunrise",
        width: 1600,
        height: 900,
        background: "#fff8f0",
        panel: "#fff3e2",
        title_color: "#9a3412",
        body_color: "#7c2d12",
        accent: "#ea580c",
        title_size: 62,
        body_size: 34,
        line_height: 54,
        padding_x: 120,
        padding_y: 110,
      })
    "ocean" =>
      Some({
        id: "ocean",
        name: "Ocean",
        width: 1600,
        height: 900,
        background: "#041c32",
        panel: "#04293a",
        title_color: "#ecfeff",
        body_color: "#bae6fd",
        accent: "#00a8cc",
        title_size: 64,
        body_size: 34,
        line_height: 56,
        padding_x: 120,
        padding_y: 110,
      })
    _ => None
  }
}

///|
fn trim_to_string(line : String) -> String {
  line.trim().to_string()
}

///|
fn split_lines(content : String) -> Array[String] {
  let lines : Array[String] = []
  for line in content.split("\n") {
    lines.push(line.to_string())
  }
  lines
}

///|
fn join_lines(lines : Array[String], start : Int) -> String {
  if start >= lines.length() {
    return ""
  }
  let sb = StringBuilder::new()
  let mut first = true
  for i = start; i < lines.length(); i = i + 1 {
    if !first {
      sb.write_char('\n')
    }
    sb.write_string(lines[i])
    first = false
  }
  sb.to_string()
}

///|
fn parse_front_matter_key_value(line : String) -> (String, String)? {
  let pos = line.find(":"[:])
  match pos {
    Some(idx) => {
      let key = trim_to_string((try! line[:idx]).to_string()).to_lower()
      let value = trim_to_string((try! line[idx + 1:]).to_string())
      if key == "" {
        None
      } else {
        Some((key, value))
      }
    }
    None => None
  }
}

///|
pub fn parse_front_matter(markdown : String) -> Result[FrontMatter, String] {
  let lines = split_lines(markdown)
  if lines.length() == 0 || trim_to_string(lines[0]) != "---" {
    return Ok({ slide_theme: "classic", body: markdown })
  }

  let mut closing_idx : Int? = None
  for i = 1; i < lines.length(); i = i + 1 {
    if trim_to_string(lines[i]) == "---" {
      closing_idx = Some(i)
      break
    }
  }

  let end_idx = match closing_idx {
    Some(v) => v
    None =>
      return Err("Front matter starts with --- but no closing --- was found.")
  }

  let mut slide_theme = "classic"
  for i = 1; i < end_idx; i = i + 1 {
    let line = trim_to_string(lines[i])
    if line == "" || line.has_prefix("#"[:]) {
      continue
    }
    match parse_front_matter_key_value(line) {
      Some((key, value)) =>
        if key == "slide_theme" {
          if value == "" {
            return Err("slide_theme in front matter cannot be empty.")
          }
          slide_theme = value
        }
      None => return Err("Invalid front matter line: " + line)
    }
  }

  if theme_by_id(slide_theme) is None {
    return Err("Unknown slide theme: " + slide_theme)
  }

  Ok({ slide_theme, body: join_lines(lines, end_idx + 1) })
}

///|
fn is_h2_heading(line : String) -> String? {
  let trimmed = trim_to_string(line)
  if trimmed.has_prefix("## "[:]) {
    let title = trim_to_string((try! trimmed[3:]).to_string())
    if title == "" {
      None
    } else {
      Some(title)
    }
  } else {
    None
  }
}

///|
fn has_non_blank(lines : Array[String]) -> Bool {
  for line in lines {
    if trim_to_string(line) != "" {
      return true
    }
  }
  false
}

///|
fn trim_blank_edges(lines : Array[String]) -> Array[String] {
  if lines.length() == 0 {
    return []
  }
  let mut start = 0
  let mut end = lines.length()
  while start < end && trim_to_string(lines[start]) == "" {
    start = start + 1
  }
  while end > start && trim_to_string(lines[end - 1]) == "" {
    end = end - 1
  }
  let result : Array[String] = []
  for i = start; i < end; i = i + 1 {
    result.push(lines[i])
  }
  result
}

///|
pub fn parse_slides(markdown : String) -> Array[SlideContent] {
  let lines = split_lines(markdown)
  let slides : Array[SlideContent] = []
  let mut current_title = "Slide"
  let mut current_lines : Array[String] = []
  let mut seen_h2 = false

  for line in lines {
    match is_h2_heading(line) {
      Some(next_title) => {
        if seen_h2 || has_non_blank(current_lines) {
          slides.push({
            title: current_title,
            lines: trim_blank_edges(current_lines),
          })
        }
        current_title = next_title
        current_lines = []
        seen_h2 = true
      }
      None => current_lines.push(line)
    }
  }

  if seen_h2 || has_non_blank(current_lines) {
    slides.push({ title: current_title, lines: trim_blank_edges(current_lines) })
  }

  if slides.length() == 0 {
    [{ title: "Slide", lines: [] }]
  } else {
    slides
  }
}

///|
fn contains_h2_heading(content : String) -> Bool {
  for line in split_lines(content) {
    if is_h2_heading(line) is Some(_) {
      return true
    }
  }
  false
}

///|
fn escape_xml(value : String) -> String {
  let sb = StringBuilder::new()
  for ch in value {
    match ch {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '\'' => sb.write_string("&#39;")
      '"' => sb.write_string("&quot;")
      _ => sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
fn wrap_text(text : String, max_chars : Int) -> Array[String] {
  let trimmed = trim_to_string(text)
  if trimmed == "" {
    return [""]
  }
  let words : Array[String] = []
  for word in trimmed.split(" ") {
    let part = word.to_string()
    if part != "" {
      words.push(part)
    }
  }
  if words.length() == 0 {
    return [""]
  }

  let lines : Array[String] = []
  let mut current = ""
  for word in words {
    let candidate = if current == "" { word } else { current + " " + word }
    if candidate.length() <= max_chars {
      current = candidate
    } else {
      if current != "" {
        lines.push(current)
      }
      current = word
    }
  }
  if current != "" {
    lines.push(current)
  }
  lines
}

///|
priv struct RenderLine {
  is_blank : Bool
  is_bullet : Bool
  text : String
}

///|
priv struct SlideLayout {
  title_size : Int
  body_size : Int
  line_height : Int
  lines : Array[RenderLine]
}

///|
fn clamp_int(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn body_size_candidates(min_size : Int, max_size : Int) -> Array[Int] {
  let values : Array[Int] = []
  let mut size = max_size
  while size >= min_size {
    values.push(size)
    size = size - 2
  }
  values
}

///|
fn compute_wrap_chars(theme : SlideTheme, body_size : Int) -> Int {
  let wrap_chars = 56 * theme.body_size / body_size
  if wrap_chars < 16 {
    16
  } else {
    wrap_chars
  }
}

///|
fn compute_title_size(theme : SlideTheme, body_size : Int) -> Int {
  let scaled = theme.title_size * body_size / theme.body_size
  clamp_int(scaled, 40, theme.title_size)
}

///|
fn compute_line_height(theme : SlideTheme, body_size : Int) -> Int {
  let scaled = theme.line_height * body_size / theme.body_size
  let minimum = body_size + 10
  if scaled < minimum {
    minimum
  } else {
    scaled
  }
}

///|
fn render_lines_from_slide(
  slide : SlideContent,
  wrap_chars : Int,
) -> Array[RenderLine] {
  let lines : Array[RenderLine] = []
  for raw_line in slide.lines {
    let trimmed = trim_to_string(raw_line)
    if trimmed == "" {
      lines.push({ is_blank: true, is_bullet: false, text: "" })
      continue
    }

    let (is_bullet, body_text) = if trimmed.has_prefix("- "[:]) ||
      trimmed.has_prefix("* "[:]) {
      (true, trim_to_string((try! trimmed[2:]).to_string()))
    } else {
      (false, trimmed)
    }

    for wrapped in wrap_text(body_text, wrap_chars) {
      lines.push({ is_blank: false, is_bullet, text: wrapped })
    }
  }
  lines
}

///|
fn can_render_all_lines(
  lines : Array[RenderLine],
  body_start_y : Int,
  line_height : Int,
  bottom_limit : Int,
) -> Bool {
  let mut body_y = body_start_y
  for line in lines {
    if line.is_blank {
      body_y = body_y + line_height / 2
      continue
    }
    if body_y >= bottom_limit {
      return false
    }
    body_y = body_y + line_height
  }
  true
}

///|
fn append_ellipsis(text : String, max_chars : Int) -> String {
  if max_chars <= 1 {
    return "…"
  }
  let trimmed = trim_to_string(text)
  if trimmed == "" {
    return "…"
  }
  if trimmed.length() >= max_chars {
    let keep = max_chars - 1
    if keep <= 0 {
      "…"
    } else {
      (try! trimmed[:keep]).to_string() + "…"
    }
  } else {
    trimmed + "…"
  }
}

///|
fn truncate_lines_for_height(
  lines : Array[RenderLine],
  body_start_y : Int,
  line_height : Int,
  bottom_limit : Int,
  wrap_chars : Int,
) -> Array[RenderLine] {
  let rendered : Array[RenderLine] = []
  let mut body_y = body_start_y
  let mut truncated = false

  for line in lines {
    if line.is_blank {
      let next_y = body_y + line_height / 2
      if next_y >= bottom_limit {
        truncated = true
        break
      }
      rendered.push(line)
      body_y = next_y
      continue
    }

    if body_y >= bottom_limit {
      truncated = true
      break
    }

    rendered.push(line)
    body_y = body_y + line_height
  }

  if !truncated {
    return rendered
  }

  let mut last_text_idx : Int? = None
  for i = 0; i < rendered.length(); i = i + 1 {
    if !rendered[i].is_blank {
      last_text_idx = Some(i)
    }
  }

  match last_text_idx {
    Some(idx) => {
      let line = rendered[idx]
      rendered[idx] = {
        is_blank: false,
        is_bullet: line.is_bullet,
        text: append_ellipsis(line.text, wrap_chars),
      }
    }
    None => rendered.push({ is_blank: false, is_bullet: false, text: "…" })
  }

  rendered
}

///|
fn build_slide_layout(slide : SlideContent, theme : SlideTheme) -> SlideLayout {
  let min_body_size = 24
  let max_body_size = 46
  let bottom_limit = theme.height - 64

  for body_size in body_size_candidates(min_body_size, max_body_size) {
    let title_size = compute_title_size(theme, body_size)
    let line_height = compute_line_height(theme, body_size)
    let wrap_chars = compute_wrap_chars(theme, body_size)
    let body_start_y = theme.padding_y + title_size + 48
    let lines = render_lines_from_slide(slide, wrap_chars)
    if can_render_all_lines(lines, body_start_y, line_height, bottom_limit) {
      return { title_size, body_size, line_height, lines }
    }
  }

  let body_size = min_body_size
  let title_size = compute_title_size(theme, body_size)
  let line_height = compute_line_height(theme, body_size)
  let wrap_chars = compute_wrap_chars(theme, body_size)
  let body_start_y = theme.padding_y + title_size + 48
  let lines = render_lines_from_slide(slide, wrap_chars)
  {
    title_size,
    body_size,
    line_height,
    lines: truncate_lines_for_height(
      lines, body_start_y, line_height, bottom_limit, wrap_chars,
    ),
  }
}

///|
fn render_slide_svg(
  slide : SlideContent,
  index : Int,
  total : Int,
  theme : SlideTheme,
) -> String {
  let sb = StringBuilder::new()
  let title = if slide.title == "" { "Slide" } else { slide.title }
  let layout = build_slide_layout(slide, theme)
  let body_x = theme.padding_x
  let mut body_y = theme.padding_y + layout.title_size + 48
  let bullet_radius = layout.body_size / 6 + 1

  sb.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    theme.width.to_string() +
    " " +
    theme.height.to_string() +
    "\" role=\"img\" aria-label=\"" +
    escape_xml(title) +
    "\">",
  )
  sb.write_string(
    "<rect x=\"0\" y=\"0\" width=\"" +
    theme.width.to_string() +
    "\" height=\"" +
    theme.height.to_string() +
    "\" fill=\"" +
    theme.background +
    "\"/>",
  )
  sb.write_string(
    "<rect x=\"" +
    (theme.padding_x - 28).to_string() +
    "\" y=\"" +
    (theme.padding_y - 42).to_string() +
    "\" width=\"" +
    (theme.width - theme.padding_x * 2 + 56).to_string() +
    "\" height=\"" +
    (theme.height - theme.padding_y * 2 + 56).to_string() +
    "\" rx=\"28\" fill=\"" +
    theme.panel +
    "\"/>",
  )
  sb.write_string(
    "<rect x=\"" +
    (theme.padding_x - 28).to_string() +
    "\" y=\"" +
    (theme.padding_y - 42).to_string() +
    "\" width=\"" +
    (theme.width - theme.padding_x * 2 + 56).to_string() +
    "\" height=\"10\" fill=\"" +
    theme.accent +
    "\"/>",
  )
  sb.write_string(
    "<text x=\"" +
    theme.padding_x.to_string() +
    "\" y=\"" +
    theme.padding_y.to_string() +
    "\" font-size=\"" +
    layout.title_size.to_string() +
    "\" font-weight=\"700\" fill=\"" +
    theme.title_color +
    "\">" +
    escape_xml(title) +
    "</text>",
  )

  for line in layout.lines {
    if line.is_blank {
      body_y = body_y + layout.line_height / 2
      continue
    }

    let x = if line.is_bullet { body_x + 24 } else { body_x }
    if line.is_bullet {
      sb.write_string(
        "<circle data-bullet=\"1\" cx=\"" +
        (body_x + 8).to_string() +
        "\" cy=\"" +
        (body_y - layout.body_size / 3).to_string() +
        "\" r=\"" +
        bullet_radius.to_string() +
        "\" fill=\"" +
        theme.accent +
        "\"/>",
      )
    }
    sb.write_string(
      "<text x=\"" +
      x.to_string() +
      "\" y=\"" +
      body_y.to_string() +
      "\" font-size=\"" +
      layout.body_size.to_string() +
      "\" fill=\"" +
      theme.body_color +
      "\">" +
      escape_xml(line.text) +
      "</text>",
    )
    body_y = body_y + layout.line_height
  }

  sb.write_string(
    "<text x=\"" +
    (theme.width - theme.padding_x).to_string() +
    "\" y=\"" +
    (theme.height - 42).to_string() +
    "\" text-anchor=\"end\" font-size=\"24\" fill=\"" +
    theme.accent +
    "\">" +
    (index + 1).to_string() +
    " / " +
    total.to_string() +
    "</text>",
  )

  sb.write_string("</svg>")
  sb.to_string()
}

///|
pub fn render_svg_slides(
  markdown : String,
  theme_id? : String = "classic",
) -> Result[Array[String], String] {
  let theme = match theme_by_id(theme_id) {
    Some(v) => v
    None => return Err("Unknown slide theme: " + theme_id)
  }
  let slides = parse_slides(markdown)
  let svgs : Array[String] = []
  for i = 0; i < slides.length(); i = i + 1 {
    svgs.push(render_slide_svg(slides[i], i, slides.length(), theme))
  }
  Ok(svgs)
}

///|
pub fn render_slide_deck_page(
  input : DeckRenderInput,
) -> Result[String, String] {
  let source = match parse_front_matter(input.markdown) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }

  if !contains_h2_heading(source.body) {
    return Err(
      "Slide content must contain at least one H2 heading (`## title`).",
    )
  }

  let theme = match theme_by_id(source.slide_theme) {
    Some(t) => t
    None => return Err("Unknown slide theme: " + source.slide_theme)
  }

  let svgs = match render_svg_slides(source.body, theme_id=theme.id) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }

  let start_index = if input.initial_index < 0 {
    0
  } else if input.initial_index >= svgs.length() {
    svgs.length() - 1
  } else {
    input.initial_index
  }

  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html><html lang=\"en\"><head>")
  sb.write_string("<meta charset=\"utf-8\"/>")
  sb.write_string(
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>",
  )
  sb.write_string("<title>")
  sb.write_string(escape_xml(input.title))
  sb.write_string("</title>")
  sb.write_string(
    "<style>body{margin:0;background:#050816;color:#dbeafe;font-family:ui-sans-serif,system-ui,sans-serif;min-height:100vh;display:flex;flex-direction:column;}header{padding:14px 20px;border-bottom:1px solid #1f2937;background:#020617;}h1{margin:0;font-size:1rem;font-weight:600;}main{flex:1;display:grid;grid-template-columns:auto minmax(0,1fr) auto;gap:12px;padding:16px;max-width:1440px;width:100%;margin:0 auto;align-items:center;}button.nav{width:52px;height:52px;border-radius:999px;border:1px solid #1e3a5f;background:#0f172a;color:#bae6fd;cursor:pointer;}button.nav:disabled{opacity:0.35;cursor:not-allowed;}article{display:none;}article.active{display:block;}article svg{width:100%;display:block;border-radius:16px;box-shadow:0 22px 52px rgba(0,0,0,.45);}footer{padding:10px 16px 18px;color:#93c5fd;display:flex;align-items:center;justify-content:center;gap:14px;flex-wrap:wrap;}#font-controls{display:inline-flex;align-items:center;gap:6px;}button.font-btn{border:1px solid #1e3a5f;background:#0f172a;color:#bae6fd;border-radius:8px;height:34px;min-width:36px;padding:0 8px;cursor:pointer;font-size:.78rem;}button.font-btn:disabled{opacity:0.4;cursor:not-allowed;}#font-scale{min-width:48px;text-align:center;color:#cfe7ff;font-size:.82rem;}@media(max-width:840px){main{grid-template-columns:1fr;}button.nav{justify-self:center;width:46px;height:46px;}footer{gap:8px;}}</style>",
  )
  sb.write_string("</head><body>")
  sb.write_string("<header><h1>")
  sb.write_string(escape_xml(input.title))
  sb.write_string(" · Theme: ")
  sb.write_string(escape_xml(theme.name))
  sb.write_string("</h1></header>")
  sb.write_string(
    "<main><button class=\"nav\" type=\"button\" id=\"prev\">◀</button><section id=\"viewport\">",
  )
  for i = 0; i < svgs.length(); i = i + 1 {
    let active = if i == start_index { " active" } else { "" }
    sb.write_string(
      "<article class=\"slide" +
      active +
      "\" data-index=\"" +
      i.to_string() +
      "\">" +
      svgs[i] +
      "</article>",
    )
  }
  sb.write_string(
    "</section><button class=\"nav\" type=\"button\" id=\"next\">▶</button></main>",
  )
  sb.write_string(
    "<footer><span id=\"counter\"></span><span>← → / #3</span><div id=\"font-controls\"><button class=\"font-btn\" type=\"button\" id=\"text-dec\">A-</button><span id=\"font-scale\">100%</span><button class=\"font-btn\" type=\"button\" id=\"text-inc\">A+</button><button class=\"font-btn\" type=\"button\" id=\"text-reset\">Reset</button></div></footer>",
  )
  sb.write_string(
    "<script>(function(){const slides=Array.from(document.querySelectorAll('.slide'));const prev=document.getElementById('prev');const next=document.getElementById('next');const counter=document.getElementById('counter');const dec=document.getElementById('text-dec');const inc=document.getElementById('text-inc');const reset=document.getElementById('text-reset');const scaleLabel=document.getElementById('font-scale');const total=slides.length;const minScale=80;const maxScale=140;const stepScale=10;let textScale=100;let idx=" +
    start_index.to_string() +
    ";const clamp=(v)=>Math.max(0,Math.min(total-1,v));const clampScale=(v)=>Math.max(minScale,Math.min(maxScale,v));const readHash=()=>{const n=parseInt(location.hash.slice(1),10);if(Number.isFinite(n)){idx=clamp(n-1);}};const applyTextScale=()=>{slides.forEach((slide)=>{const svg=slide.querySelector('svg');if(!svg){return;}svg.querySelectorAll('text').forEach((node)=>{const baseValue=node.dataset.baseFontSize||node.getAttribute('font-size');const base=Number.parseFloat(baseValue||'');if(!Number.isFinite(base)||base<=0){return;}if(!node.dataset.baseFontSize){node.dataset.baseFontSize=String(base);}const scaled=Math.max(1,Math.round(base*textScale/100));node.setAttribute('font-size',String(scaled));});});};const renderScale=()=>{if(scaleLabel){scaleLabel.textContent=textScale+'%';}if(dec){dec.disabled=textScale<=minScale;}if(inc){inc.disabled=textScale>=maxScale;}};const setScale=(next)=>{const value=clampScale(next);if(value===textScale){renderScale();return;}textScale=value;applyTextScale();renderScale();};const render=()=>{slides.forEach((s,i)=>s.classList.toggle('active',i===idx));counter.textContent=(idx+1)+' / '+total;prev.disabled=idx===0;next.disabled=idx===total-1;if(location.hash!=='#'+(idx+1)){history.replaceState(null,'','#'+(idx+1));}};prev.addEventListener('click',()=>{idx=clamp(idx-1);render();});next.addEventListener('click',()=>{idx=clamp(idx+1);render();});dec.addEventListener('click',()=>{setScale(textScale-stepScale);});inc.addEventListener('click',()=>{setScale(textScale+stepScale);});reset.addEventListener('click',()=>{setScale(100);});window.addEventListener('keydown',(e)=>{if(e.key==='ArrowLeft'){e.preventDefault();idx=clamp(idx-1);render();}if(e.key==='ArrowRight'){e.preventDefault();idx=clamp(idx+1);render();}});window.addEventListener('hashchange',()=>{readHash();render();});readHash();applyTextScale();renderScale();render();})();</script>",
  )
  sb.write_string("</body></html>")
  Ok(sb.to_string())
}
