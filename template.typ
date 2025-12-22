#import "@preview/showybox:2.0.1" : showybox
#import "src/00_trang_bia.typ": trang_bia
#import "src/01_trang_phu_bia.typ": trang_phu_bia
#import "src/02_thong_tin_hoi_dong.typ": thong_tin_hoi_dong
#import "@preview/codly:1.3.0": *

#let heading_numbering(..nums) = {
  return str(counter(heading).get().first()) + "." + nums
  .pos()
  .map(str)
  .join(".")
}

#let phuluc_numbering(..nums) = {
  return str.from-unicode(counter(heading).get().at(1) + 64) + "." + nums
  .pos()
  .map(str)
  .join(".")
}

#let outline_algo(x, caption, label) = {
  return [
    #figure(x, kind: "algo", supplement: [Thuật toán], caption: caption, numbering: heading_numbering) #label
  ]
}

#let numbered_equation(content, label) = {
  return [
    #set math.equation(
      numbering: (..nums) => "(" + str(counter(heading).get().first()) + "." + nums.pos().map(str).join(".") + ")",
    )
    #content
    #label
  ]
}

#let output_box(content) = {
  showybox(
    breakable: true,
    frame: (border-color: gray, title-color: gray.lighten(80%), radius: 0pt),
    title-style: (color: black, boxed-style: (anchor: (x: left, y: horizon), radius: 0pt)),
    title: "Output",
    content,
  )
}

#let tab_eq(body, space: 1.2em, indent: 1.5em) = [
  #set par(first-line-indent: indent, hanging-indent: indent, spacing: space)
  #body
  #set par(hanging-indent: 0pt)
]

#let untab_para(body) = [
  #set par(first-line-indent: 0pt)
  #body
  #set par(first-line-indent: 1.5em)
]

// Project part
#let project(title: "", authors: (), body) = {
  // Set the document's basic properties.
  set document(author: authors.map(a => a.name), title: title)
  set page(paper: "a4", margin: (top: 3cm, bottom: 3.5cm, left: 3.5cm, right: 2cm))
  set text(font: "Times New Roman", lang: "vi", size: 13pt)
  // set text(font: "New Computer Modern", lang: "vi", size: 13pt)
  set par(justify: true)

  // ================= TRANG BÌA =====================
  trang_bia(title, authors)

  // ================= TRANG PHỤ BÌA =====================
  trang_phu_bia(title, authors)

  set page(numbering: "i")
  counter(page).update(1)
  // ================= THÔNG TIN HỘI ĐỒNG =====================
  include "src/02_thong_tin_hoi_dong.typ"
  
  // ================= LỜI CAM ĐOAN =====================
  include "src/03_loi_cam_doan.typ"

  // ================= LỜI CẢM ƠN =====================
  include "src/04_loi_cam_on.typ"

  show heading.where(level: 1): it => [
    #counter(figure.where(kind: image)).update(0)
    #counter(figure.where(kind: table)).update(0)
    #counter(figure.where(kind: "algo")).update(0)

    #pagebreak(weak: true)
    #if (not str(counter(heading).display()).starts-with("Chương")) {
      text(35pt, it)
    } else {
      block([
        #set par(first-line-indent: 0pt)
        #text(35pt, counter(heading).display())
        #v(0.1cm)
        #text(35pt, it.body)
        #v(0.5cm)
      ])
    }
  ]

  // ================= MỤC LỤC =====================
  {
    show outline.entry.where(level: 1): it => {
      v(20pt, weak: true)
      strong(
        {
          if (it.element.numbering != none) {
            let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
            box(width: 5em, number) + ". "
          }
          link(it.element.location())[#it.element.body ]
          box(width: 1fr, it.fill)
          h(3pt)
          link(it.element.location())[#it.page()]
        },
      )
    }
    show outline.entry.where(level: 2): it => {
      v(20pt, weak: true)
      h(1.5em)
      if (it.element.numbering != none) {
        let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
        box(width: 1.7em, number)
      }
      link(it.element.location())[ #it.element.body ]
      box(width: 1fr, it.fill)
      h(3pt)
      link(it.element.location())[#it.page()]
    }
    show outline.entry.where(level: 3): it => {
      v(20pt, weak: true)
      h(3em)
      if (it.element.numbering != none) {
        let number = numbering(it.element.numbering, ..counter(heading).at(it.element.location()))
        box(width: 2.4em, number)
      }
      link(it.element.location())[ #it.element.body ]
      box(width: 1fr, it.fill)
      h(3pt)
      link(it.element.location())[#it.page()]
    }
    show outline.entry.where(level: 4): it => {
      v(20pt, weak: true)
      h(4.5em)
      if (it.element.numbering != none) {
        let number = numbering(
          it.element.numbering,
          ..counter(heading).at(it.element.location())
        )
        box(width: 3.2em, number)
      }

      link(it.element.location())[ #it.element.body ]
      box(width: 1fr, it.fill)
      h(3pt)
      link(it.element.location())[#it.page()]
    }

    {
      show heading: none
      heading(numbering: none)[Mục lục]
    }
    align(center, text(16pt, [*MỤC LỤC*]))
    v(7pt)
    outline(title: none, depth: 4)
    pagebreak()
  }

  {
    // citation dup in caption
    // https://github.com/typst/typst/issues/1880
    set footnote.entry(separator: none)
    show footnote.entry: hide
    show ref: none
    show footnote: none


    {
      show heading: none
      heading(numbering: none)[Danh mục hình ảnh]
    }
    align(center, text(16pt, [*DANH MỤC HÌNH ẢNH*]))
    v(7pt)
    outline(title: none, target: figure.where(kind: image))
    pagebreak()
    {
      show heading: none
      heading(numbering: none)[Danh mục bảng]
    }
    align(center, text(16pt, [*DANH MỤC BẢNG*]))
    v(7pt)
    outline(title: none, target: figure.where(kind: table))
    pagebreak()
      
    // ================= DANH SÁCH THUẬT NGỮ =====================
    include "src/05_danh_sach_thuat_ngu.typ"
    pagebreak()
    {
      show heading: none
      heading(numbering: none)[Danh mục giải thuật]
    }
    align(center, text(16pt, [*DANH MỤC GIẢI THUẬT*]))
    v(7pt)
    outline(title: none, target: figure.where(kind: "algo"))
    pagebreak()
  }

  // ================= TÓM TẮT =====================
  include "src/06_tom_tat.typ"

  // ===============================================
  set par(first-line-indent: (amount: 1.5em, all: false), leading: 0.8em, spacing: 1.5em)
  set block(spacing: 1.2em)
  set list(indent: 0.8em)
  show heading: set block(spacing: 1.5em)
  show link: set text(fill: rgb("#0028d9"))
  show ref: it => {
    if it.element == none {
      return it
    }
    set text(fill: rgb("#0028d9"))
    it
  }

  show cite: it => {
    show regex("\d+"): set text(rgb("#0028d9"))
    it
  }
  set figure.caption(separator: [ --- ])
  set figure(gap: 3pt, numbering: heading_numbering)

  show figure.where(kind: image): set figure(gap: 15pt, numbering: heading_numbering)

  show figure.caption: c => [
    #context text(weight: "bold", size: 13pt)[
    #c.supplement #c.counter.display(c.numbering)
    ]
    #c.separator#c.body
    #v(0.4cm)
  ]
  show figure.where(kind: table): set figure.caption(position: top)

  show figure.where(kind: "algo"): set figure.caption(position: top)
  show figure: set block(breakable: true)

  show raw.where(block: false): box.with(
    fill:  luma(240), 
    stroke: rgb(239, 240, 243),
    inset: (x: 3pt, y: 1pt),
    outset: (y: 3pt),
    radius: 3pt,
  )

  show: codly-init.with()
  show raw.where(block: true, lang: "sh"): it => {
    codly(
      number-format: none,
      display-icon: false,
      display-name: false,
    )
    it
  }
  show raw.where(block: true, lang: "py"): it => {
    codly(
      display-icon: false,
      display-name: false,
      languages: (py: (name: "Python", color: rgb("#CE412B"))),
    )
    it
  }
  show raw.where(block: true, lang: "python"): it => {
    codly(
      display-icon: true,
      display-name: true,
      languages: (python: (name: "Python", icon: "🐍 ", color: rgb("#CE412B"))),
    )
    it
  }

  // ============ MATH ==============
  set math.cases(gap: 1.2em)
  set math.equation(supplement: none)
  set math.equation(numbering: "(1)")

  body
}

#let dfrac(x, y) = math.equation(block(inset: (top: 0.5em, bottom: 0.8em))[#text(size: 18pt)[#math.frac(x, y)]])