#let trang_bia(title, authors) = {
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
      #text(12pt, strong("ĐẠI HỌC QUỐC GIA HỒ CHÍ MINH"))
  
      #text(12pt, strong("TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN"))
      ]
      #v(0.6cm)
      #align(center)[
        #image("/images/UIT.png", width: 25%)
      ]
      #v(0.7cm)
      
      #align(center)[
        #text(14pt, strong("Trần Đình Khánh Đăng - 22520195"))
      ]
      
      #v(1.2cm)
      #align(center)[
        #set par(justify: false)
        #text(18pt,  upper(strong(title)))
      ]
      #v(2cm)
      #align(center)[
        #text(14pt, strong("KHÓA LUẬN TỐT NGHIỆP ĐẠI HỌC HỆ CHÍNH QUY"))
      ]
      #align(center)[
        #text(14pt, strong("Khoa: Khoa học máy tính"))
      ]

      #v(1fr)
    
      #align(center)[
        #text(12pt, strong("HỒ CHÍ MINH - 2025"))
      ]
    ]  
  ))
}
