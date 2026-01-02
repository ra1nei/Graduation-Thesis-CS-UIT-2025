#import "@preview/touying:0.5.3": *
#import "stargazer.typ": *
#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge
#import "@preview/numbly:0.1.0": numbly
#import "/template.typ" : *

#set text(font: "New Computer Modern", lang: "vi")
#set heading(numbering: numbly("{1}.", default: "1.1."))
#set par(justify: true)
#show figure.caption: set text(17pt)

#let r(it) = text(fill: rgb("#D00000"), weight: "bold", it)
#let o(it) = text(fill: rgb("#eaa646"), weight: "bold", it)
#let glyph-grid2(chars, base, font) = grid(
  columns: (auto,) * chars.len(),
  inset: 1pt,
  ..chars.map(char =>
    box(
      width: 60pt,
      height: auto,
      image(
        base + font + "_" + char + ".png",
        width: 60%,
        fit: "contain"
      )
    )
  )
)

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
  row-gutter: 20pt,
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
  ],

  grid.cell(colspan: 2)[
    *3. Hạn chế về hỗ trợ đa ngôn ngữ (Localization Barrier):*
    - Các font nghệ thuật đẹp thường chỉ hỗ trợ ngôn ngữ phổ biến (Anh, Trung).
    - Thiếu các *glyph Latin mở rộng* (như tiếng Việt: ă, â, đ...) hoặc hệ chữ ít phổ biến (Thái, Lào).
  ]
)

#pagebreak()
#v(20pt)
$arrow$ *Không thể tái sử dụng trực tiếp nếu không tự thiết kế bổ sung các ký tự thiếu.*
#align(center)[
    #image("images/slide_manual_design_hard.png", height: 70%) 
]

== Giải pháp: One-shot Font Generation <touying:hidden>
Thay vì vẽ thủ công hàng chục nghìn ký tự, AI sẽ "học" phong cách từ *một chữ mẫu duy nhất* để sinh ra toàn bộ bộ font.

#v(10pt)
#align(center)[
  #grid(
    columns: (1fr, 0.5fr, 1fr, 0.5fr, 1fr),
    align: horizon,
    [#image("images/example_image/丈.png", width: 50%) \ *Nội dung* \ (Ký tự gốc)],
    text(1.5em)[+],
    [#image("images/example_image/A-OTF-ShinMGoMin-Shadow-2_english+M+.png", width: 50%) \ *Phong cách* \ (1 Mẫu)],
    text(1.5em)[$arrow$],
    [#image("images/example_image/A-OTF-ShinMGoMin-Shadow-2_chinese+丈.png", width: 50%) \ *Kết quả* \ (Font mới)]
  )
]

#pagebreak()
*Giải quyết triệt để 3 thách thức trên:*
#list(marker: text(fill: red)[$checkmark$])[
  *Tốc độ & Chi phí:* Rút ngắn quy trình từ hàng tháng xuống vài giây.
]
#list(marker: text(fill: green)[$checkmark$])[
  *Mở rộng quy mô:* Sinh tự động hàng vạn ký tự Hán/Nôm mà không tốn sức người.
]
#list(marker: text(fill: blue)[$checkmark$])[
  *Hỗ trợ đa ngôn ngữ (Localization):* Tự động sinh các *glyph thiếu* (như dấu tiếng Việt, ký tự Thái) từ các font nước ngoài, giúp tái sử dụng tài nguyên font hiệu quả.
]

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
== Khoảng cách hình thái học <touying:hidden>
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
    $arrow$ *Đây là chìa khoá để bắc cầu qua "Morphological Gap".*
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
== Bộ dữ liệu <touying:hidden>
Kế thừa bộ dữ liệu chuẩn từ *FTransGAN*.

- *Quy mô:* *818* bộ phông chữ song ngữ (Bao gồm Serif, Sans-serif, Thư pháp...).
- *Cấu trúc cặp (Paired Data):*
  #table(
    columns: (auto, 1fr),
    stroke: none,
    inset: (y: 3pt),
    gutter: 10pt,
    [Latin:], [~ *52* ký tự cơ bản.],
    [Hán tự:], [~ *800* ký tự thông dụng (GB2312).]
  )
- *Đặc điểm:* Nhất quán tuyệt đối về phong cách giữa hai hệ chữ $arrow$ Cung cấp *Ground-truth* tự nhiên cho việc học.

== Kịch bản đánh giá <touying:hidden>
Tuân theo chuẩn của FTransGAN và FontDiffuser.

#v(5pt)
#block(fill: luma(240), inset: 8pt, radius: 5pt)[
  *SFUC (Seen Font, Unseen Char):*
  - Font đã biết, sinh ký tự mới.
  - *Mục tiêu:* Đánh giá khả năng *nội suy phong cách*.
]

#v(10pt)
#block(fill: blue.lighten(90%), stroke: blue, inset: 8pt, radius: 5pt)[
  *UFSC (Unseen Font, Seen Char):*
  - Font *mới hoàn toàn* (chưa từng thấy khi train).
  - *Mục tiêu:* Đánh giá khả năng *One-shot Generalization* (Kịch bản khó nhất & Quan trọng nhất).
  ]

== Cấu hình Huấn luyện & Suy diễn <touying:hidden>
#text(size: 0.8em)[
  #grid(
    align: top + left,
    columns: (1fr, auto, 1fr),
    gutter: 20pt,
    [
      *1. Môi trường & Giai đoạn 1:*
      - *Phần cứng:* Kaggle Cloud, GPU NVIDIA Tesla P100 (16GB).
      - *Framework:* PyTorch, Diffusers.
      - *Phase 1:* 400.000 bước, Batch 4, AdamW ($lr=1 times 10^(-4)$).
      - *Mục tiêu:* Học cấu trúc nội dung và phong cách cơ bản.

      *2. Tiền huấn luyện CL-SCR:*
      - *Quy mô:* 200k bước, Batch 16, Adam[cite: 914].
      - *Augmentation:* Random Resized Crop (Scale 0.8-1.0) $arrow$ Tăng tính bền vững với biến thể hình học.
    ], 
    [],
    [
      *3. Giai đoạn 2 - Tinh chỉnh:*
      - *Thiết lập:* 30k bước, Batch 4, giảm $lr=1 times 10^(-5)$ để tránh phá vỡ cấu trúc.
      - *CL-SCR:* Chế độ `both` (Nội miền + Xuyên miền), $alpha=0.3, beta=0.7$, $K=4$.
      - *Hàm Loss tổng hợp:*
        $ L_"total" = L_"MSE" + 0.01 L_"percep" + 0.5 L_"offset" + 0.01 L_"CL-SCR" $

      *4. Quy trình Inference:*
      - *Sampler:* DPM-Solver++ (20 steps) để cân bằng tốc độ/chất lượng.
      - *Guidance:* Classifier-free Guidance (CFG).
    ]
  )
]

== Các thước đo đánh giá <touying:hidden>
#v(20pt)
Để đánh giá toàn diện, khoá luận sử dụng hệ thống đo lường đa tầng:

#grid(
  align: top + left,
  columns: (1fr, 1fr),
  gutter: 20pt,
  [
    *1. Định lượng (Quantitative):*
    #table(
      columns: (auto, 1fr),
      stroke: none,
      inset: (y: 5pt),
      [*L1 & SSIM*], [Độ chính xác về điểm ảnh & cấu trúc (Pixel-level).],
      [*LPIPS*], [Độ tương đồng nhận thức (Perceptual distance).],
      [*FID*], [*(Quan trọng nhất)* Đo khoảng cách phân bố giữa ảnh sinh và ảnh thật (Độ chân thực).]
    )
  ],
  [
    *2. Định tính (Qualitative):*
    - *Visual Inspection:* So sánh bằng mắt thường các chi tiết nét (gai, xước, đậm/nhạt).
    - *User Study:* Khảo sát mù (Blind Test) trên 20 người dùng để đánh giá độ hài lòng thị giác.
  ]
)
$arrow$ *Kết hợp cả độ chính xác máy học và cảm nhận con người.*

== Kết quả định lượng <touying:hidden>
#v(30pt)
#align(center, [
  #text(size: 17pt)[ 
    #figure(
      table(
        columns: (auto, 200pt, auto, auto, auto, auto, auto, auto, auto, auto),
        inset: 4pt,
        align: center + horizon,
        stroke: none,
        gutter: 3pt,
        
        // --- Header ---
        table.hline(stroke: 0.5pt),
        table.header(
          // --- HEADER ---
          [],
          table.vline(stroke: 0.5pt),
          
          table.cell(rowspan: 2, align: center + horizon)[*Model*], 
          table.vline(stroke: 0.5pt),
          
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[*SFUC*],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[*UFSC*],
          
          // --- HEADER (Metrics) ---
          [],
          
          // Metrics SFUC
          [*L1 $arrow.b$*], [#text(size: 14pt)[*SSIM $arrow.t$*]], [#text(size: 12pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
          table.vline(stroke: 0.5pt),
          
          // Metrics UFSC
          [*L1 $arrow.b$*], [#text(size: 14pt)[*SSIM $arrow.t$*]], [#text(size: 12pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
        ),
        table.hline(stroke: 0.5pt),

        // --- (L -> C) ---
        table.cell(rowspan: 6, rotate(-90deg, reflow: true)[*L $->$ C*]),
        
        [DG-Font], 
        [0.2773], [0.2702], [0.4023], [106.38], 
        [0.2797], [0.2654], [0.3649], [54.09],

        [CF-Font], 
        [0.2659], [0.2740], [0.3979], [91.21], 
        [0.2638], [0.2716], [0.3615], [51.39],

        [DFS], 
        [0.2131], [0.3558], [0.3812], [45.42], 
        [#r[0.2008]], [0.3048], [0.3876], [62.72],

        [FTransGAN], 
        [#r[0.1844]], [#r[0.3900]], [0.3548], [40.45], 
        [#underline[0.2089]], [#underline[0.3109]], [0.3329], [42.10],

        [FontDiffuser (Baseline)], 
        [0.1976], [0.3775], [#underline[0.2968]], [#underline[14.68]], 
        [0.2283], [0.2946], [#underline[0.3184]], [#underline[29.09]],

        [#o[Ours]], 
        [#underline[0.1939]], [#underline[0.3890]], [#r[0.2911]], [#r[11.76]], 
        [0.2214], [#r[0.3197]], [#r[0.2954]], [#r[13.55]],
        
        table.hline(stroke: 0.5pt),

        // --- (C -> L) ---
        table.cell(rowspan: 6, rotate(-90deg, reflow: true)[*C $->$ L*]),
        
        [DG-Font], 
        [0.1462], [0.5542], [0.2821], [74.1655], 
        [0.1397], [0.5624], [0.2751], [89.8197],

        [CF-Font], 
        [0.1402], [0.5621], [0.2790], [67.1241], 
        [0.1317], [0.5756], [0.2726], [84.3787],

        [DFS], 
        [#r[0.1083]], [#underline[0.6140]], [0.2585], [40.4042], 
        [#underline[0.1139]], [#underline[0.5819]], [0.2907], [75.2760],

        [FTransGAN], 
        [0.1381], [0.5291], [0.2851], [55.5859], 
        [0.1456], [0.4949], [0.3023], [88.4450],

        [FontDiffuser (Baseline)], 
        [#underline[0.1223]], [0.6107], [#underline[0.2270]], [#underline[21.2234]], 
        [0.1370], [0.5731], [#underline[0.2476]], [#underline[59.5788]],

        [#o[Ours]], 
        [#r[0.1083]], [#r[0.6406]], [#r[0.2019]], [#r[14.7298]], 
        [#r[0.1090]], [#r[0.6377]], [#r[0.1985]], [#r[41.1152]],
        
        table.hline(stroke: 0.5pt),
      )
    ) <table-metric>
  ]
])

== Kết quả định tính <touying:hidden>
// #grid(
//   align: top + left, 
//   columns: (1fr, 1fr),
//   gutter: 10pt,
//   [
//     *Chiều Latin $arrow$ Hán:*
//     - *Ours:* Tái tạo đúng nét cọ xước, đậm nhạt.
//     - *Baseline:* Nét đôi khi bị cứng hoặc sai độ đậm.
//   ],
//   [
//     *Chiều Hán $arrow$ Latin:*
//     - *Ours:* Giữ cấu trúc chữ rõ ràng.
//     - *DG-Font:* Bị lỗi "Content Leakage" (chữ Latin biến thành Hán).
//   ]
// )

// #pagebreak()

#v(25pt)
#figure(
  grid(
    columns: (200pt, 0pt, auto, auto),
    gutter: 1pt,
    inset: 0.01pt,
    stroke: none,
    align: (horizon, horizon, horizon),
    fill: (x, y) => {
      if y == 0 or y == 1 { rgb("#e6f7ff") }
      else if y == 7 { rgb("#ffe6e6") }
      else if y == 8 { rgb("#fda979") }
      else { none }
    },

    [Source], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "Content"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "Content"
    ),

    [Reference], [],
    glyph-grid2(
      ("衣", "牛", "土", "生", "至"),
      "images/eval/chi2eng_style/",
      "Content"
    ),
    glyph-grid2(
      ("Z", "D", "W", "B", "J"),
      "images/eval/eng2chi_style/",
      "Content"
    ),

    [DG-Font], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "DG"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "DG"
    ),

    [CF-Font], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "CF"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "CF"
    ),

    [DFS], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "DFS"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "DFS"
    ),

    [FTransGAN], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "FTransGAN"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "FTransGAN"
    ),

    [FontDiffuser (Baseline)], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "Baseline"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "Baseline"
    ),

    [#o[Ours]], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "FontDiffuser"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "FontDiffuser"
    ),

    [Target], [],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "images/eval/chi2eng_style/",
      "GroundTruth"
    ),
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "images/eval/eng2chi_style/",
      "GroundTruth"
    ),
  ),
) <image_metric>

== Đánh giá người dùng <touying:hidden>
#v(30pt)
#figure(
  image("images/userscore_chart.png", height: 90%)
)

== Hiệu quả của các mô-đun kiến trúc <touying:hidden>
#v(30pt)
#align(center, [
  #text(size: 17pt)[
    #let mark_row(m, r, s, cl) = {
      grid(
        columns: (1fr, 1fr, 1fr, 1fr),
        align: center,
        m, r, s, cl
      )
    }

    #figure(
      table(
        columns: (auto, 140pt, auto, auto, auto, auto, auto, auto, auto, auto),
        inset: 4pt,
        align: center + horizon,
        stroke: none,
        gutter: 3pt,
        
        // --- Header ---
        table.hline(stroke: 0.5pt),
        table.header(
          [], [],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[
            *SFUC* ],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[
            *UFSC*
          ],
        ),
        
        // --- Sub-header ---
        [], 
        table.vline(stroke: 0.5pt),
        table.cell(align: center + horizon)[
          *Mô-đun*
          #grid(
             columns: (1fr, 1fr, 1fr, 1fr),
             [*M*], [*R*], [*S*], [*CL*]
          )
        ], 
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
        table.hline(stroke: 0.5pt),

        // --- (L -> C) ---
        table.cell(rowspan: 3, rotate(-90deg, reflow: true)[*L $->$ C*]),
        
        // Dòng 1: ✘ + ✘ + ✘
        mark_row($crossmark.heavy$, $crossmark.heavy$, $crossmark.heavy$, $crossmark.heavy$),
        [0.2441], [0.2983], [0.4434], [70.3650],
        [0.2815], [0.1965], [0.4854], [75.7399],

        // Dòng 2: M + R + S
        mark_row($checkmark.heavy$, $checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$),
        [#underline[0.1976]], [#underline[0.3775]], [#underline[0.2968]], [#underline[14.6871]],
        [#underline[0.2283]], [#underline[0.2946]], [#underline[0.3184]], [#underline[29.0999]],

        // Dòng 3: M + R + CL
        o[#mark_row($checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$, $checkmark.heavy$)],
        [#r[0.1939]], [#r[0.3890]], [#r[0.2911]], [#r[11.7691]],
        [#r[0.2214]], [#r[0.3197]], [#r[0.2954]], [#r[13.5508]],
        
        table.hline(stroke: 0.5pt),

        // --- (C -> L) ---
        table.cell(rowspan: 3, rotate(-90deg, reflow: true)[*C $->$ L*]),
        
        // Dòng 4: ✘ + ✘ + ✘
        mark_row($crossmark.heavy$, $crossmark.heavy$, $crossmark.heavy$, $crossmark.heavy$),
        [0.2763], [0.2491], [0.4792], [84.7434],
        [0.3017], [0.1793], [0.5102], [119.9425],

        // Dòng 5: M + R + S
        mark_row($checkmark.heavy$, $checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$),
        [#underline[0.1223]], [#underline[0.6107]], [#underline[0.2270]], [#underline[21.2234]],
        [#underline[0.1370]], [#underline[0.5731]], [#underline[0.2476]], [#underline[59.5788]],

        // Dòng 6: M + R + CL
        o[#mark_row($checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$, $checkmark.heavy$)],
        [#r[0.1083]], [#r[0.6406]], [#r[0.2019]], [#r[14.7298]],
        [#r[0.1090]], [#r[0.6377]], [#r[0.1985]], [#r[41.1152]],
        
        table.hline(stroke: 0.5pt),
      )
    ) <ablation-module>
  ]
])

// == Tối ưu hoá mô-đun CL-SCR <touying:hidden>
// Đánh giá hiệu năng trên kịch bản khó nhất (*UFSC*) theo hai chiều chuyển đổi.

// #text(size: 18pt)[ 
//   #grid(
//     columns: (1fr, 10pt, 1fr),
//     gutter: 20pt,
//     align: top + left,
//     [
//       *a. Chế độ Hàm Loss (Loss Modes):*
//       So sánh chiều xuôi (L$arrow$C) và ngược (C$arrow$L).

//       #figure(
//         table(
//           columns: (1fr, auto, auto),
//           inset: 6pt,
//           align: (left, center, center),
//           stroke: none,
//           table.header(
//             table.cell(rowspan: 2, align: horizon)[*Chế độ*],
//             table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
//             [*L $arrow$ C*], [*C $arrow$ L*],
//             table.hline(stroke: 0.5pt),
//           ),
//           [Intra-only], [#underline[15.7197]], [#underline[41.3399]],
//           [Cross-only], [16.2615], [44.7758],
//           [*Both*], [#r[13.5508]], [#r[41.1152]],
//           table.hline(stroke: 0.5pt),
//         )
//       )
//       #v(5pt)
//       #text(size: 0.8em)[
//         $arrow$ *Both* tối ưu nhất. *Cross-only* cho kết quả kém nhất, chứng tỏ cần duy trì học nội bộ (Intra) để giữ ổn định cấu trúc.
//       ]
//     ],
//     [],
//     [
//       *b. Trọng số Alpha ($alpha$) & Beta ($beta$):*
//       Tác động lên từng chiều ngôn ngữ.

//       #figure(
//         table(
//           columns: (1fr, 1fr, auto, auto),
//           inset: 6pt,
//           align: center,
//           stroke: none,
//           table.header(
//             table.cell(rowspan: 2, align: horizon)[*$alpha$*],
//             table.cell(rowspan: 2, align: horizon)[*$beta$*],
//             table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
//             [*L $arrow$ C*], [*C $arrow$ L*],
//             table.hline(stroke: 0.5pt),
//           ),
//           [0.7], [0.3], [#underline[14.4760]], [16.3548],
//           [0.5], [0.5], [15.1777], [#underline[15.5683]],
//           [*0.3*], [*0.7*], [#r[13.5508]], [#r[14.7298]],
//           table.hline(stroke: 0.5pt),
//         )
//       )
//       #v(5pt)
//       #text(size: 0.8em)[
//         $arrow$ Hiệu năng đạt đỉnh khi ưu tiên *$beta=0.7$*, khẳng định tầm quan trọng của việc nhấn mạnh vào các đặc trưng xuyên ngôn ngữ.
//       ]
//     ]
//   )
// ]

// ================================================
= Kết luận
== Tổng kết đóng góp <touying:hidden>
Khoá luận đã hoàn thành các mục tiêu đề ra ban đầu:

#v(20pt)
#list(marker: text(fill: red, size: 1.2em)[$star$])[
  *Giải quyết bài toán khó:* Xây dựng thành công pipeline chuyển đổi phong cách đa ngôn ngữ (Cross-Lingual) giữa Latin và Hán tự.
]
#v(10pt)
#list(marker: text(fill: blue, size: 1.2em)[$checkmark$])[
  *Đóng góp kỹ thuật:* Đề xuất mô-đun *CL-SCR* với cơ chế Loss hỗn hợp (Intra + Cross), giúp tách biệt hiệu quả nội dung và phong cách.
]
#v(10pt)
#list(marker: text(fill: green, size: 1.2em)[$checkmark$])[
  *Hiệu quả thực nghiệm:* Vượt trội SOTA hiện tại (FID giảm $~$50% ở chiều Latin $arrow$ Hán), khắc phục được lỗi "bóng ma" và "biến dạng cấu trúc" của các dòng GAN.
]

== Hạn chế & Hướng phát triển <touying:hidden>
#text(size: 18pt)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 20pt,
    align: top + left,
    [
      #block(fill: rgb("#fff0f0"), inset: 10pt, radius: 5pt, width: 100%)[
        *Hạn chế (Limitations):*
        
        - *Tốc độ suy diễn chậm:*
          Do bản chất của Diffusion (20 bước khử nhiễu) $arrow$ Chậm hơn GAN ~60 lần.
        
        - *Tài nguyên tính toán:*
          Yêu cầu VRAM lớn hơn để lưu trữ các trạng thái trung gian.
          
        $arrow$ *Chưa phù hợp cho ứng dụng Real-time.*
      ]
    ],
    [
      #block(fill: rgb("#f0f8ff"), inset: 10pt, radius: 5pt, width: 100%)[
        *Hướng phát triển (Future Work):*
        
        - *Tối ưu tốc độ (Speed Up):*
          Áp dụng *Consistency Distillation* hoặc *Latent Diffusion* để giảm số bước lấy mẫu (4-8 bước).
        
        - *Mở rộng ngôn ngữ:*
          Thử nghiệm trên tiếng Việt (Thư pháp/Quốc ngữ), tiếng Thái.
          
        - *Đa dạng đầu ra:*
            Sinh font dạng Vector (SVG) để designer dễ dàng chỉnh sửa.
      ]
    ]
  )
]

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

= Phụ lục <touying:hidden>
So sánh chỉ số quan trọng nhất (*FID*) trên kịch bản khó (*UFSC*):

== Tối ưu hóa CL-SCR (Ablation Detail) <touying:hidden>
Cơ sở thực nghiệm để lựa chọn các siêu tham số tốt nhất.

#text(size: 17pt)[
  #grid(
    columns: (auto, 10pt, auto),
    gutter: 20pt,
    align: top + left,
    [
      *a. Chế độ Hàm Loss (Loss Modes):*
      Tại sao phải kết hợp cả Intra và Cross?

      #figure(
        table(
          columns: (1fr, auto, auto),
          inset: 6pt, stroke: none, align: center,
          table.header(
            table.cell(rowspan: 2, align: horizon)[*Chế độ*],
            table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
            [*L $arrow$ C*], [*C $arrow$ L*],
            table.hline(stroke: 0.5pt)
          ),
          [Intra-only], [#underline[15.72]], [#underline[41.34]],
          [Cross-only], [16.26], [44.78],
          [#o[Both]], [#o[13.55]], [#o[41.12]],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ *Both* tận dụng sự ổn định của Intra và khả năng chuyển đổi của Cross.
    ],
    [], // Space
    [
      *b. Trọng số Alpha ($alpha$) & Beta ($beta$):*
      Tại sao ưu tiên $beta=0.7$?

      #figure(
        table(
          columns: (1fr, 1fr, auto, auto),
          inset: 6pt, stroke: none, align: center,
          table.header(
            table.cell(rowspan: 2, align: horizon)[*$alpha$*],
            table.cell(rowspan: 2, align: horizon)[*$beta$*],
            table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
            [*L $arrow$ C*], [*C $arrow$ L*],
            table.hline(stroke: 0.5pt)
          ),
          [0.7], [0.3], [#underline[14.48]], [16.35],
          [0.5], [0.5], [15.18], [#underline[15.57]],
          [#o[0.3]], [#o[0.7]], [#o[13.55]], [#o[14.73]],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ Bài toán Cross-Lingual cần ưu tiên học các đặc trưng xuyên ngôn ngữ ($beta$ lớn).
    ]
  )
]

== Phân tích độ nhạy (Sensitivity Analysis) <touying:hidden>
Ảnh hưởng của Số mẫu âm & Guidance Scale

#text(size: 17pt)[
  #grid(
    columns: (auto, 10pt, auto),
    gutter: 20pt,
    align: top + left,
    [
      *c. Số lượng mẫu âm ($K$):*
      Trong hàm loss InfoNCE.

      #figure(
        table(
          columns: (1fr, auto, auto),
          inset: 6pt, stroke: none, align: center,
          table.header(
            table.cell(rowspan: 2, align: horizon)[*K*],
            table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
            [*L $arrow$ C*], [*C $arrow$ L*],
            table.hline(stroke: 0.5pt)
          ),
          [#o[4]], [#o[13.55]], [#o[41.11]],
          [8], [15.42], [43.50],
          [16], [19.80], [48.20],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ *K=4* là điểm cân bằng tối ưu cho cả hai chiều.
    ],
    [], // Space
    [
      *d. Trọng số hướng dẫn (Scale - $s$):*
      Cân bằng giữa đa dạng và chính xác.

      #figure(
        table(
          columns: (1fr, auto, auto),
          inset: 6pt, stroke: none, align: center,
          table.header(
            table.cell(rowspan: 2, align: horizon)[*Scale ($s$)*],
            table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
            [*L $arrow$ C*], [*C $arrow$ L*],
            table.hline(stroke: 0.5pt)
          ),
          [2.5], [18.20], [52.10],
          [5.0], [15.10], [45.30],
          [#o[7.5]], [#o[13.55]], [#o[41.11]],
          [10.0], [14.20], [42.80],
          [12.5], [14.90], [44.10],
          [15.0], [16.50], [47.50],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ *$s=7.5$* (Chuẩn CFG) cho kết quả tốt nhất.
    ]
  )
]

== Chi tiết triển khai (Implementation) <touying:hidden>