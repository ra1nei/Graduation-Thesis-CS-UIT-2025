#let thong_tin_hoi_dong(so, ngay, mem1, role1, mem2, role2, mem3, role3) = {
  align(center)[
    #text(16pt, weight: "bold")[
      THÔNG TIN HỘI ĐỒNG CHẤM KHÓA LUẬN TỐT NGHIỆP
    ]
  ]

  v(10pt)

  align(center)[
    #text()[
      Hội đồng chấm khóa luận tốt nghiệp, thành lập theo Quyết định số #so ngày #ngay \
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