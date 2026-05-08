#import "../src/lib.typ": key-out

#set page(width: 210mm, height: 210mm, margin: 12mm)
#set text(size: 11pt)

#let source = read("fixtures/typst-chan.png", encoding: none)
#let checker = read("fixtures/checkerboard.png", encoding: none)
#let preview-width = 86mm
#let preview-height = 120mm
#let key-color = rgb("#04f904")
#let key-tolerance = 15%
#let key-softness = 3%
#let image-from-bytes(data, ..args) = {
  if sys.version >= version(0, 13, 0) {
    image(data, ..args)
  } else {
    image.decode(data, format: "png", ..args)
  }
}

#let checker-preview(body) = box(width: preview-width, height: preview-height)[
  #place(top + left, image-from-bytes(checker, width: preview-width, height: preview-height, fit: "stretch"))
  #place(top + left, body)
]

#align(center)[
  #text(size: 18pt, weight: "bold")[Typst-chan visual check]

  #v(2mm)

  #text(size: 9pt)[Key settings: color #key-color.to-hex(), tolerance #key-tolerance, softness #key-softness.]

  #v(5mm)

  #grid(
    columns: (1fr, 1fr),
    gutter: 8mm,
    [
      #text(weight: "bold")[Source]
      #v(3mm)
      #image-from-bytes(source, height: preview-height)
    ],
    [
      #text(weight: "bold")[Keyed on checkerboard]
      #v(3mm)
      #checker-preview(key-out(
        source,
        color: key-color,
        tolerance: key-tolerance,
        softness: key-softness,
        height: preview-height,
        alt: "Typst-chan with green background keyed out",
      ))
    ],
  )
]
