#{
  show heading: none
  heading(numbering: none)[Thông tin hội đồng chấm khoá luận tốt nghiệp]
}
#align(center, text(16pt, strong("THÔNG TIN HỘI ĐỒNG CHẤM KHOÁ LUẬN TỐT NGHIỆP")))

#let thong_tin_hoi_dong(so, ngay, mem1, role1, mem2, role2, mem3, role3) = {
  v(10pt)
  align(center)[
    #text()[
      Hội đồng chấm khoá luận tốt nghiệp, thành lập theo Quyết định số #so ngày #ngay \
      của Hiệu trưởng Trường Đại học Công nghệ Thông tin.
    ]
  ]

  v(18pt)
  grid(
    columns: (1fr, auto),
    row-gutter: 20pt,

    [#mem1], [*#role1*],
    [#mem2], [*#role2*],
    [#mem3], [*#role3*],
  )
}

#thong_tin_hoi_dong(
  "xx", 
  "xx", 
  "xxxxxxxx", 
  "xxxxxxxx", 
  "xxxxxxxx", 
  "xxxxxxxx",
  "xxxxxxxx",
  "xxxxxxxx"
)

#pagebreak()