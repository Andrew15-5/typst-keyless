#import "../src/lib.typ": key-out, key-out-bytes

#set page(width: 2cm, height: 2cm, margin: 0pt)

#let source = read("fixtures/white-black.png", encoding: none)
#let keyed = key-out-bytes(source, color: white)

#assert.eq(keyed.at(0), 0x89)
#assert.eq(keyed.at(1), 0x50)
#assert.eq(keyed.at(2), 0x4e)
#assert.eq(keyed.at(3), 0x47)
#metadata(range(keyed.len()).map(i => keyed.at(i))) <keyed-png>

#key-out(
  source,
  color: white,
  width: 1cm,
  alt: "white pixel keyed out",
)
