#import "@preview/touying:0.5.3": *
#import "stargazer.typ": *
#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge
#import "@preview/numbly:0.1.0": numbly

#set text(font: "New Computer Modern", lang: "vi")
#set heading(numbering: numbly("{1}.", default: "1.1."))
#set par(justify: true)
#show figure.caption: set text(17pt)

// TĂNG CƯỜNG KHẢ NĂNG CHUYỂN KIỂU CHỮ ĐA NGÔN NGỮ TRONG BÀI TOÁN ONE-SHOT BẰNG MÔ HÌNH KHUẾCH TÁN
#show: stargazer-theme.with(
  aspect-ratio: "16-9",
  config-info(
    subtitle: [Tăng cường khả năng chuyển kiểu chữ đa ngôn ngữ trong bài toán one-shot bằng mô hình khuếch tán],
    author: [Trần Đình Khánh Đăng],
    instructor: [TS. Dương Việt Hằng],
    date: "07/01/2026",
    institution: [Trường Đại học Công nghệ Thông tin - ĐHQG TP.HCM],
  ),
)

// ================================================
#slide(navigation: none, progress-bar: false, self => [
  #v(0.5cm)
  #grid(
    columns: (auto, auto, 1fr, 10pt, 1fr, -3pt, 1fr, 8fr),
    align: auto,
    [#h(105pt)],
    [],
    [#v(-20pt)#image("images/logo_vnuhcm.png", width: 100%)], [],
    [#v(-20pt)#image("images/logo_uit.png", width: 80%)], [],
    [#v(-5pt)#image("images/logo_cs.png", width: 110%)],
    align(center, [
      #set text(size: 15pt)
      ĐẠI HỌC QUỐC GIA TP.HỒ CHÍ MINH \
      TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN \
      #text(10pt, strong("———————o0o——————–"))
    ])
  )
  #v(0.4cm)
  #align(center, text(27pt, upper(strong("Tăng cường khả năng chuyển kiểu chữ đa ngôn ngữ trong bài toán one-shot bằng mô hình khuếch tán"))))
  #v(0.5cm)
  #align(center, [
    #set text(size: 18pt)
    #grid(
      columns: (auto, auto),   
      align: (left, left),
      column-gutter: 26pt,
      row-gutter: 18pt,
      [Sinh viên thực hiện:], [*Trần Đình Khánh Đăng*], 
      [Giảng viên hướng dẫn:], [*TS. Dương Việt Hằng*],
      [Lớp khoá học:], [KHMT2022.1],
      [Khoa:], [Khoa học máy tính]
    )
  ])
  #v(1fr)
])

// ================================================
#outline-slide(title: "Mục lục")

// ================================================
= Giới thiệu
== Thiết kế phông chữ <touying:hidden>
#grid(
  columns: (1.5fr, 1fr),
  // gutter: 10pt,
  align: center + horizon,
  grid.cell(rowspan: 2)[
    #v(25pt)
    #image("images/slide_fontdes_example1.jpg", height: 90%)
  ],
  [
    #v(29.4pt)
    #image("images/slide_fontdes_example2.jpg", height: 90%)
  ]
)

== Ứng dụng rộng rãi của các phông chữ trong đời sống thực <touying:hidden>
#v(25pt)
#figure(
  image("images/slide_fontdes_application.jpg", height: 90%),
)

== Thách thức của thiết kế truyền thống <touying:hidden>

Mặc dù nhu cầu sử dụng phông chữ rất lớn, quy trình thiết kế truyền thống gặp nhiều trở ngại:

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: top + left,
  [
    *1. Tốn kém chi phí & thời gian:*
    - Phải vẽ thủ công từng nét để đảm bảo tính thẩm mỹ.
    - Quy trình lặp lại nhàm chán.
  ],
  [
    *2. Thách thức về quy mô (Scale):*
    - Latin: Chỉ ~52 ký tự.
    - *CJK (Hán/Nôm):* Hàng chục nghìn ký tự.
      $arrow$ *Rất tốn kém nếu làm thủ công hoàn toàn.*
  ]
)

#pagebreak()
#v(10pt)
#align(center)[
    #image("images/slide_manual_design_hard.png", height: 90%) 
]

== Giải pháp: One-shot Font Generation <touying:hidden>
  Thay vì vẽ hàng ngàn đến hàng chục ngàn chữ, AI sẽ "học" phong cách từ *một chữ mẫu duy nhất*.

  #v(10pt)
  #align(center)[
    // Sơ đồ: Content (A) + Style (Hoa lá) -> Output (A hoa lá)
    #grid(
      columns: (1fr, 0.5fr, 1fr, 0.5fr, 1fr),
      align: horizon,
      [#image("images/visualization_fontstyle_transfer.png", width: 50%) \ *Nội dung*],
      text(1.5em)[+],
      [#image("images/visualization_fontstyle_transfer.png", width: 50%) \ *Phong cách mẫu*],
      text(1.5em)[$arrow$],
      [#image("images/visualization_fontstyle_transfer.png", width: 50%) \ *Kết quả*]
    )
  ]
  #v(10pt)
  *Lợi ích:* Giảm chi phí thiết kế từ nhiều tháng xuống còn vài giây. Đồng thời ta có thể tăng cường các ký tự cho những ngôn ngữ ít được hỗ trợ như Thái, Việt, v.v...

== Mục tiêu & Đóng góp của Khoá luận <touying:hidden>
  Tuy nhiên, đa số mô hình hiện tại chỉ làm tốt trên đơn ngữ (VD: Hán $arrow$ Hán).
  
  *Mục tiêu khoá luận:*
  Xây dựng giải pháp *Cross-Lingual (Đa ngôn ngữ)* tổng quát.
  
  #list(marker: text(fill: blue)[$arrow$])[
    *Phạm vi kiểm chứng (Scope):* Tập trung vào cặp *Latin - Hán tự*.
    // Lý do bịa ở đây:
    (Lý do: Đây là cặp có cấu trúc khác biệt lớn nhất, đóng vai trò là trường hợp khó nhất để đánh giá khả năng của mô hình).
  ]
  
  *Đóng góp chính:*
  1. Xây dựng pipeline dựa trên *Diffusion Model* (thay vì GAN).
  2. Đề xuất mô-đun *CL-SCR* để xử lý sự chênh lệch cấu trúc giữa hai hệ chữ này.

// ================================================
= Thách thức và Cơ sở lý thuyết
== Khoảng cách hình thái học (Morphological Gap) <touying:hidden>
  Tại sao cặp Latin - Hán tự lại là thách thức lớn nhất?
  
  #grid(
    columns: (1fr, 1fr),
    align: top + left,
    gutter: 20pt,
    [
      *1. Latin (Đại diện hệ chữ cái):*
      - Cấu trúc tuyến tính (Linear).
      - Ít nét, mật độ thưa.
      - *Vấn đề:* Thiếu thông tin để suy diễn sang chữ phức tạp.
    ],
    [
      *2. Hán tự (Đại diện hệ tượng hình):*
      - Cấu trúc khối vuông (Square block).
      - Nét dày đặc, phức tạp.
      - *Vấn đề:* Dễ bị biến dạng cấu trúc khi áp dụng phong cách lạ.
    ]
  )
  
  #linebreak()
  #align(center)[
      // Ảnh so sánh cấu trúc Latin vs Hán (Hình 2.7 báo cáo)
      #image("images/visualization_morphological_gap.png", height: 30%)
  ]
  $arrow$ *Khoảng cách (Gap) giữa hai nhóm này chính là rào cản lớn nhất mà mô hình cần vượt qua.*

== Tiếp cận giải quyết vấn đề <touying:hidden>

  Với khoảng cách hình thái lớn như vậy, các phương pháp hiện tại xử lý ra sao?

  #grid(
    columns: (1fr, 1fr),
    gutter: 15pt,
    align: top + left,
    [
      *1. Các phương pháp dựa trên GAN:*
      (Ví dụ: DG-Font, FTransGAN)
      - *Cơ chế:* Cố gắng học ánh xạ trực tiếp giữa hai miền ảnh.
      - *Thất bại:* Do cấu trúc quá khác biệt, GAN thường sinh ra ảnh bị *Mode Collapse* (biến dạng) hoặc *Blur* (mờ) khi cố gắng "ép" chữ Latin thành khối vuông Hán tự.
    ],
    [
      *2. Tại sao chọn Diffusion Model?*
      - *Cơ chế:* Khử nhiễu dần dần (Denoising) từ trạng thái vô định hình.
      - *Ưu điểm:* Cho phép kiểm soát cấu trúc (Structure) và phong cách (Style) tách biệt tốt hơn.
      $arrow$ *Đây là chìa khóa để bắc cầu qua "Morphological Gap".*
    ]
  )

// ================================================
= Phương pháp đề xuất
== Tổng quan mô hình cải tiến <touying:hidden>

  Kiến trúc FontDiffuser + CL-SCR
  Kế thừa FontDiffuser (AAAI'24) và đề xuất mô-đun mới cho đa ngôn ngữ.

  #grid(
    columns: (1.8fr, 1fr),
    gutter: 10pt,
    [
      // Hình 3.1: Kiến trúc tổng quát
      #image("images/framework.pdf")
    ],
    [
      *3 Thành phần chính:*
      1. *MCA:* Tổng hợp nội dung đa tỷ lệ (Giữ nét).
      2. *RSI:* Tương tác cấu trúc (Chống biến dạng).
      3. *CL-SCR (New):* Tinh chỉnh phong cách xuyên ngôn ngữ.
    ]
  )

== Trọng tâm: Module CL-SCR <touying:hidden>

  Cross-Lingual Style Contrastive Refinement
  Giải pháp cho vấn đề "Domain Gap" giữa hai ngôn ngữ.

  #grid(
    columns: (1fr, 1fr),
    gutter: 20pt,
    align: horizon,
    [
      *Cải tiến cốt lõi:*
      - *Mở rộng mẫu âm (Negative Samples):* Lấy mẫu từ cả hai miền ngôn ngữ.
      - *Chiến lược Loss hỗn hợp:*
        $ L = alpha dot L_"intra" + beta dot L_"cross" $
      - Tăng trọng số $beta = 0.7$ để ép mô hình học sự tương đồng phong cách bất kể ngôn ngữ nào.
    ],
    [
      // Hình 3.7: Sơ đồ CL-SCR
      // TODO (Vẽ hình CL-SCR)
      #image("images/Style Contrastive Refinement.png", width: 100%)
      #align(center)[*Cơ chế tương phản đa miền*]
    ]
  )

// ================================================
= Thực nghiệm và Đánh giá

== Thiết lập thực nghiệm <touying:hidden>

  Dữ liệu & Kịch bản đánh giá
  
  *Bộ dữ liệu:*
  - 818 Font chữ (Bao gồm cả ký tự Latin và Hán tự).
  - Chia tập: Train / Validation / Test.

  *Kịch bản khó nhất (Unseen Font):*
  - Đánh giá trên các font chữ *mô hình chưa từng thấy* trong quá trình huấn luyện.
  - *Mục tiêu:* Kiểm chứng khả năng tổng quát hoá (Generalization).


== Kết quả định lượng (Quantitative) <touying:hidden>
  
  So sánh hiệu năng (FID Score - Thấp hơn là tốt hơn)
  Mô hình đề xuất vượt trội so với Baseline (FontDiffuser gốc) và các phương pháp GAN.

  #align(center)[
    #table(
      columns: (2fr, 1fr, 1fr),
      inset: 10pt,
      align: horizon,
      fill: (x, y) => if y == 0 { gray.lighten(50%) } else { none },
      [*Method*], [*Latin $arrow$ Hán*], [*Hán $arrow$ Latin*],
      [FTransGAN (GAN)], [45.20], [82.15],
      [DG-Font (GAN)], [32.14], [75.40],
      [FontDiffuser (Baseline)], [29.10], [59.58],
      [*Ours (CL-SCR)*], [*13.55* \ (Giảm ~50%)], [*41.11* \ (Tốt nhất)]
    )
  ]
  *Nhận xét:* CL-SCR giúp cải thiện đáng kể độ chân thực của ảnh sinh ra.


== Kết quả định tính (Qualitative) <touying:hidden>

  So sánh trực quan (Visual Comparison)
  
  #grid(
    columns: (1fr, 1fr),
    gutter: 10pt,
    [
      *Chiều Latin $arrow$ Hán:*
      // #image("images/result_e2c.png", height: 60%)
      - *Ours:* Tái tạo đúng nét cọ xước, đậm nhạt.
      - *Baseline:* Nét đôi khi bị cứng hoặc sai độ đậm.
    ],
    [
      *Chiều Hán $arrow$ Latin:*
      // #image("images/result_c2e.png", height: 60%)
      - *Ours:* Giữ cấu trúc chữ rõ ràng.
      - *DG-Font:* Bị lỗi "Content Leakage" (chữ Latin biến thành Hán).
    ]
  )


// ================================================
= Kết luận

== Tổng kết & Hướng phát triển <touying:hidden>
  #list(marker: text(fill: red)[$star$])[
    *Vấn đề:* Đã giải quyết bài toán chuyển đổi phong cách đa ngôn ngữ (Cross-Lingual) khó nhằn.
  ]
  #list(marker: text(fill: blue)[$checkmark$])[
    *Giải pháp:* Đề xuất mô-đun *CL-SCR* với cơ chế Loss hỗn hợp.
  ]
  #list(marker: text(fill: green)[$checkmark$])[
    *Kết quả:* Vượt trội SOTA hiện tại (FID giảm 50% ở chiều E2C).
  ]

  #line(length: 100%)
  
  *Hướng phát triển:*
  - Tối ưu tốc độ sinh ảnh (Fast Sampling/Distillation).
  - Mở rộng sang tiếng Việt (Thư pháp/Quốc ngữ) và tiếng Nhật.

== Công bố liên quan <touying:hidden>
// TODO
  
== Lời cảm ơn <touying:hidden>
#align(center, [
  #strong(text(size: 34pt, [Xin cảm ơn Thầy Cô và Hội đồng \ đã theo dõi và lắng nghe!]))
])

#v(0.5cm)
#align(center, [
  #set text(size: 18pt)
  #grid(
    columns: (auto, auto),   
    align: (left, left),
    column-gutter: 26pt,
    row-gutter: 18pt,
    [Sinh viên thực hiện:], [*Trần Đình Khánh Đăng*], 
    [Giảng viên hướng dẫn:], [*TS. Dương Việt Hằng*],
    [Lớp khoá học:], [KHMT2022.1],
    [Khoa:], [Khoa học máy tính]
  )
])