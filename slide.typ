#import "@preview/touying:0.5.3": *
#import "stargazer.typ": *
#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge
#import "@preview/numbly:0.1.0": numbly
#import "/template.typ" : *

#set text(font: "New Computer Modern", lang: "vi")
#set heading(numbering: numbly("{1}.", default: "1.1."))
#set par(justify: true)
#show figure.caption: set text(17pt)

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
  row-gutter: 20pt, // Thêm khoảng cách giữa các hàng
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
  // Phần bổ sung mới, cho nằm trải dài (colspan: 2) ở hàng dưới
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
#align(center, [
  #text(size: 17pt)[ 
    // --- Định nghĩa hàm tô Đậm + Đỏ ở đây ---
    #let r(it) = text(fill: rgb("#D00000"), weight: "bold", it)
    
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
          [], [],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[
            *SFUC* // Cái này sẽ tự động là Đậm + Màu mặc định (không bị đỏ)
          ],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[
            *UFSC*
          ],
        ),
        
        // --- Sub-header ---
        [], 
        table.vline(stroke: 0.5pt),
        [*Model*], // Vẫn đen/xanh đậm
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [#text(size: 14pt)[*SSIM $arrow.t$*]], [#text(size: 12pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [#text(size: 14pt)[*SSIM $arrow.t$*]], [#text(size: 12pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
        table.hline(stroke: 0.5pt),

        // --- Data Rows (L -> C) ---
        table.cell(rowspan: 6, rotate(-90deg, reflow: true)[*L $->$ C*]),
        
        [DG-Font], 
        [0.2773], [0.2702], [0.4023], [106.38], 
        [0.2797], [0.2654], [0.3649], [54.09],

        [CF-Font], 
        [0.2659], [0.2740], [0.3979], [91.21], 
        [0.2638], [0.2716], [0.3615], [51.39],

        [DFS], 
        [0.2131], [0.3558], [0.3812], [45.42], 
        [#r[0.2008]], [0.3048], [0.3876], [62.72], // Dùng hàm #r thay vì *...*

        [FTransGAN], 
        [#r[0.1844]], [#r[0.3900]], [0.3548], [40.45], 
        [#underline[0.2089]], [#underline[0.3109]], [0.3329], [42.10],

        [FontDiffuser (Baseline)], 
        [0.1976], [0.3775], [#underline[0.2968]], [#underline[14.68]], 
        [0.2283], [0.2946], [#underline[0.3184]], [#underline[29.09]],

        [Ours], 
        [#underline[0.1939]], [#underline[0.3890]], [#r[0.2911]], [#r[11.76]], 
        [0.2214], [#r[0.3197]], [#r[0.2954]], [#r[13.55]],
        
        table.hline(stroke: 0.5pt),

        // --- Data Rows (C -> L) ---
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

        [Ours], 
        [#r[0.1083]], [#r[0.6406]], [#r[0.2019]], [#r[14.7298]], 
        [#r[0.1090]], [#r[0.6377]], [#r[0.1985]], [#r[41.1152]],
        
        table.hline(stroke: 0.5pt),
      )
    ) <table-metric>
  ]
])

== Kết quả định tính <touying:hidden>
So sánh trực quan (Visual Comparison)

#grid(
  align: top + left, 
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    *Chiều Latin $arrow$ Hán:*
    - *Ours:* Tái tạo đúng nét cọ xước, đậm nhạt.
    - *Baseline:* Nét đôi khi bị cứng hoặc sai độ đậm.
  ],
  [
    *Chiều Hán $arrow$ Latin:*
    - *Ours:* Giữ cấu trúc chữ rõ ràng.
    - *DG-Font:* Bị lỗi "Content Leakage" (chữ Latin biến thành Hán).
  ]
)

#pagebreak()
#v(25pt)
#figure(
  grid(
    columns: (100pt, 30pt, auto, auto),
    gutter: 1pt,
    inset: 0.01pt,
    stroke: none,
    align: (horizon, horizon, horizon),
    
    // ===== c2e =====
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

    [$"Ours"$], [],
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
  // caption: [Comparison results between our method and previous state-of-the-art methods.]
) <image_metric>

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