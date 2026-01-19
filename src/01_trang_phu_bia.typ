#let trang_phu_bia(title, authors) = {
  rect(
    stroke: 5pt,
    inset: 7pt,
  rect(
    width: 100%,
    height: 100%,
    inset: 15pt,
    stroke: 1.7pt,
    [
      #align(center)[
      #text(12pt, strong("ĐẠI HỌC QUỐC GIA TP. HỒ CHÍ MINH"))
  
      #text(12pt, strong("TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN"))

      #text(12pt, strong("KHOA KHOA HỌC MÁY TÍNH"))
      ]

      #v(1.5cm)
      #align(center)[
        #text(14pt, strong("TRẦN ĐÌNH KHÁNH ĐĂNG - 22520195"))
      ]

      #v(1.5cm)
      #align(center)[
        #text(14pt, strong("KHOÁ LUẬN TỐT NGHIỆP"))
      ]
      
      #v(2cm)
      #align(center)[
        #set par(justify: false)
        #text(18pt,  upper(strong(title)))
      ]

      #v(0.5cm)
      #align(center)[
        #pad(
          left: 1cm,
          right: 1cm,
        )[
          #set text(lang: "en")
          #text(fill: red, 18pt, strong("Enhancing One-shot Cross-Script Font Style Transfer using Diffusion Model"))
        ]
      ]

      #v(1.5cm)
      #align(center)[
        #text(14pt, strong("CỬ NHÂN NGÀNH KHOA HỌC MÁY TÍNH"))
      ]

      // #align(center)[
      //   #text(14pt, strong("Khoa: Khoa học máy tính"))
      // ]

      #v(1.5cm)
      #align(center)[
        #text(14pt, strong("GIẢNG VIÊN HƯỚNG DẪN:"))
      ]
      #align(center)[
        #text(14pt, strong("TS. Dương Việt Hằng"))
      ]

      #v(1fr)
      #align(center)[
        #text(12pt, strong("TP.HỒ CHÍ MINH, 2025"))
      ]
    ]  
  ))
}
