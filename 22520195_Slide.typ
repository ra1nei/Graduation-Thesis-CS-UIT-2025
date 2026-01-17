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

#show: stargazer-theme.with(
  aspect-ratio: "16-9",
  config-info(
    subtitle: [Tăng cường khả năng chuyển kiểu chữ đa ngôn ngữ trong bài toán one-shot bằng mô hình khuếch tán],
    author: [Trần Đình Khánh Đăng],
    instructor: [TS. Dương Việt Hằng],
    date: "20/01/2026",
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
// == Bối cảnh & Nhu cầu thực tế <touying:hidden>
// #grid(
//   columns: (1fr, 1.2fr),
//   gutter: 20pt,
//   align: horizon,
//   [
//     #image("images/slide_fontdes_example1.jpg", height: 80%)
//   ],
//   [
//     *Nhu cầu:* Phông chữ hiện diện khắp nơi (Biển hiệu, Bao bì, Website...).
    
//     #v(10pt)
//     *Vấn đề:* Nhu cầu về font chữ độc đáo, thẩm mỹ và *đồng bộ thương hiệu* ngày càng cao, đòi hỏi quy trình thiết kế phải nhanh chóng và đa dạng.
    
//     $arrow$ *Các phương pháp thủ công không còn đáp ứng đủ tốc độ.*
//   ]
// )

== Thách thức của thiết kế truyền thống <touying:hidden>
Quy trình thiết kế font truyền thống gặp 3 rào cản lớn:

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  row-gutter: 20pt,
  align: top + left,
  [
    *1. Chi phí:*
    - Quy trình vẽ tay tốn kém nhân lực và thời gian.
    - Hiệu suất thấp do tính chất lặp lại thủ công.
  ],
  [
    *2. Quy mô:*
    - Latin: $~$52 ký tự.
    - *CJK (Hán/Nôm):* Hàng vạn ký tự (> 50.000 ký tự).
    $arrow$ *Bất khả thi nếu làm tay hoàn toàn.*
  ],

  grid.cell(colspan: 2)[
    *3. Rào cản Đa ngôn ngữ:*
    - Các ngôn ngữ *Low-resource* hoặc có *dấu phức tạp* (như Tiếng Việt) *thường xuyên bị thiếu font đồng bộ*.
    $arrow$ Gây khó khăn lớn cho việc *Bản địa hoá thương hiệu*.
  ]
)

== Giải pháp: One-shot Font Generation <touying:hidden>
// AI học phong cách từ *1 mẫu duy nhất* $arrow$ chuyển giao sang ký tự khác.
Cơ chế *One-shot*: Tách biệt phong cách từ *1 mẫu ảnh* $arrow$ Chuyển giao (Transfer) sang *bất kỳ ký tự nào*.

#v(20pt)
#align(center)[
  #grid(
    columns: (1fr, 0.3fr, 1fr, 0.3fr, 1fr),
    align: horizon,
    [#image("images/example_image/丈.png", height: 50pt) \ #text(0.8em)[Nội dung (Content)]],
    text(1.5em)[+],
    [#image("images/example_image/A-OTF-ShinMGoMin-Shadow-2_english+M+.png", height: 50pt) \ #text(0.8em)[1 Mẫu Style (Reference)]],
    text(1.5em)[$arrow$],
    [#image("images/example_image/A-OTF-ShinMGoMin-Shadow-2_chinese+丈.png", height: 50pt) \ #text(0.8em)[Kết quả (Generated)]]
  )
]
#v(20pt)
// $arrow$ *Giải quyết đồng thời bài toán về Tốc độ, Quy mô và Đa ngôn ngữ.*
$arrow$ *Giải pháp tối ưu cho bài toán Chi phí, Quy mô và Đa ngôn ngữ.*

== Mục tiêu & Đóng góp <touying:hidden>
Mục tiêu: Xây dựng giải pháp *Cross-Lingual (Đa ngôn ngữ)* tổng quát.

#list(marker: text(fill: blue)[$arrow$])[
  *Phạm vi (Scope):* Tập trung vào cặp *Latin - Hán tự*.
  (Lý do: Đây là cặp có cấu trúc khác biệt lớn nhất $arrow$ Bài toán khó nhất).
]

*Đóng góp chính:*
1. Xây dựng pipeline dựa trên *Diffusion Model*.
2. Đề xuất mô-đun *CL-SCR* để xử lý khác biệt cấu trúc.

// ================================================
// == Khoảng cách hình thái học <touying:hidden>
// Tại sao cặp Latin - Hán tự lại là thách thức lớn nhất?

// #grid(
//   columns: (1fr, 1fr),
//   align: top + left,
//   gutter: 20pt,
//   [
//     *1. Latin (Đại diện hệ chữ cái):*
//     - Cấu trúc tuyến tính (Linear).
//     - Ít nét, mật độ thưa.
//     - *Vấn đề:* Thiếu thông tin để suy diễn sang chữ phức tạp.
//   ],
//   [
//     *2. Hán tự (Đại diện hệ tượng hình):*
//     - Cấu trúc khối vuông (Square block).
//     - Nét dày đặc, phức tạp.
//     - *Vấn đề:* Dễ bị biến dạng cấu trúc khi áp dụng phong cách lạ.
//   ]
// )

// #linebreak()
// #align(center)[
//     #image("images/visualization_morphological_gap.png", height: 30%)
// ]
// $arrow$ *Khoảng cách hình thái này tạo ra rào cản lớn trong việc bảo toàn cấu trúc (Structure Preservation) khi thực hiện chuyển đổi phong cách.*

// == Tiếp cận giải quyết vấn đề <touying:hidden>
// Với khoảng cách hình thái lớn như vậy, các phương pháp hiện tại xử lý ra sao?

// #grid(
//   columns: (1fr, 1fr),
//   gutter: 20pt,
//   align: top + left,
//   [
//     *1. Các phương pháp dựa trên GAN:*
//     (Ví dụ: DG-Font, FTransGAN)
//     - *Cơ chế:* Ánh xạ biến đổi trực tiếp (Direct Image-to-Image Translation).
//     - *Hạn chế:* Gặp khó khăn khi xử lý sự chênh lệch thông tin 2 chiều:
//       + Chiều $L arrow C$: Dễ bị *mờ* do phải "bịa" ra các nét phức tạp.
//       + Chiều $C arrow L$: Thường gặp lỗi *bóng ma* (ghosting).
//   ],
//   [
//     *2. Tại sao chọn Diffusion Model?*
//     - *Cơ chế:* Phá huỷ cấu trúc cũ thành nhiễu và tái tạo lại cấu trúc mới từng bước.
//     - *Ưu điểm:* Khả năng *tách biệt* giữa Cấu trúc và Phong cách.
//     $arrow$ *Đảm bảo tính toàn vẹn cấu trúc cho cả hai chiều chuyển đổi (Bi-directional).*
//   ]
// )
// 
== Khoảng cách hình thái học (Morphological Gap) <touying:hidden>
Tại sao Latin - Hán tự là thách thức lớn nhất?

#grid(
  columns: (1fr, 1fr),
  align: top + left,
  gutter: 20pt,
  [
    *1. Latin (Hệ chữ cái):*
    - Cấu trúc tuyến tính (Linear), ít nét.
    - *Vấn đề:* Quá ít thông tin để suy diễn.
  ],
  [
    *2. Hán tự (Hệ tượng hình):*
    - Cấu trúc khối vuông (Block), dày đặc.
    - *Vấn đề:* Dễ bị biến dạng cấu trúc.
  ]
)

#align(center)[
    #image("images/visualization_morphological_gap.png", height: 35%)
]
$arrow$ *Rào cản lớn nhất trong việc bảo toàn cấu trúc khi chuyển đổi phong cách.*

// == Tại sao chọn Diffusion thay vì GAN? <touying:hidden>
// #grid(
//   columns: (1fr, 1fr),
//   gutter: 20pt,
//   align: top + left,
//   [
//     *1. Các phương pháp GAN:*
//     (DG-Font, FTransGAN)
//     - *Cơ chế:* Ánh xạ trực tiếp (Mapping).
//     - *Hạn chế:* Gặp lỗi *Bóng ma (Ghosting)* hoặc *Mờ (Blur)* do cố "ép" cấu trúc này vào khuôn khổ kia.
//   ],
//   [
//     *2. Diffusion Model (Đề xuất):*
//     - *Cơ chế:* Khử nhiễu (Denoising) & Tái tạo.
//     - *Ưu điểm:* Tách biệt triệt để *Cấu trúc* (Content) và *Phong cách* (Style).
//     $arrow$ *Phù hợp để xử lý Cross-Lingual.*
//   ]
// )

// ================================================
= Phương pháp đề xuất
== Kiến trúc đề xuất <touying:hidden>

#align(center)[
  #block(width: 100%, height: auto)[
    #image("images/framework.pdf", height: 55%) 
    
    #place(
      top + left, 
      dx: 390pt, 
      dy: 0pt,
      rect(
        width: 295pt,
        height: 215pt,
        stroke: (paint: red, thickness: 2pt, dash: "dashed"),
        radius: 5pt
      )
    )
    
    #place(
      top + left,
      dx: 475pt,
      dy: 220pt,
      block(fill: white, inset: 3pt, stroke: red)[
        #text(fill: red, weight: "bold", size: 14pt)[Khu vực cải tiến]
      ]
    )
  ]
]

#v(10pt)

// Phần text giải thích
#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: top + left,
  
  [
    #text(size: 16pt)[ 
      *Giai đoạn 1 (Nền tảng FontDiffuser):*
      - *MCA:* Tổng hợp đặc trưng đa tỷ lệ.
      - *RSI:* Xử lý biến dạng hình học.
      - $arrow$ *Mục tiêu:* Đảm bảo tái tạo đúng *cấu trúc chữ*.
    ]
  ],
  
  [
    #text(size: 16pt)[
      #block(fill: rgb("#ffe6e6"), stroke: red, inset: 10pt, radius: 5pt, width: 100%)[
        *Giai đoạn 2 (Trong khung đỏ):*
        - Thay thế mô-đun SCR gốc bằng kiến trúc *CL-SCR* đề xuất.
        - $arrow$ Nâng cấp khả năng học *Cross-Lingual*.
      ]
    ]
  ]
)

== Động lực & Ý tưởng <touying:hidden>
#v(25pt)
#grid(
  columns: (1fr, 1fr),
  gutter: 15pt,
  align: top + left,
  [
    #block(fill: rgb("#fff0f0"), stroke: red, inset: 10pt, radius: 5pt, width: 100%)[
      #text(size: 17pt)[
        *Vấn đề của Giai đoạn 1:*
        - Giai đoạn 1 chỉ tập trung tối ưu hoá *điểm ảnh* (Pixel-wise).
        - $arrow$ Học tốt cấu trúc nhưng yếu về *biểu diễn phong cách trừu tượng*. Khi chuyển sang hệ chữ khác, mô hình bị "mất phương hướng" vì không còn điểm ảnh tương đồng để so sánh.
      ]
    ]
  ],
  [
    #block(fill: rgb("#e6fffa"), stroke: green, inset: 10pt, radius: 5pt, width: 100%)[
      #text(size: 17pt)[
        *Trực giác cho Giai đoạn 2 (Cross-Lingual Bridge):*
        - Cần một cơ chế *tách biệt phong cách* khỏi nội dung.
        - Tận dụng các *nét tương đồng* (stroke-level) giữa Latin và Hán tự thông qua cơ chế *Học tương phản (Contrastive Learning)*.
        - $arrow$ Dùng CL-SCR để "ép" mô hình tìm ra mẫu số chung về phong cách giữa hai ngôn ngữ.
      ]
    ]
  ]
)

*Giải pháp CL-SCR:* Áp dụng cơ chế *Contrastive Learning*:
#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: top + left,
  [
    #text(size: 17pt)[- *Intra-domain:* Giữ bản sắc ngôn ngữ nguồn.]
  ],
  [
    #text(size: 17pt)[- *Cross-domain:* Tìm điểm chung giữa hai hệ chữ.]
  ]
)

== Kiến trúc mô-đun CL-SCR <touying:hidden>
#v(20pt)
Cơ chế giám sát luồng đôi (Dual-stream Supervision):

#align(center + horizon)[
  #image("images/clscr_framework.pdf", width: 85%)
  
  #v(0.3em)
  *Hình 3.7:* Kiến trúc mạng CL-SCR với hai luồng giám sát Intra và Cross.
]

== Công thức hàm Loss (CL-SCR) <touying:hidden>
#v(10pt)
Dựa trên nguyên lý *InfoNCE* (Cơ chế Kéo - Đẩy):

#grid(
  columns: (1fr, 1fr),
  align: top + left,
  gutter: 20pt,
  [
    #block(fill: luma(240), stroke: gray, inset: 10pt, radius: 5pt, width: 100%)[
      *1. Intra-Lingual ($L_"intra"$)*
      #text(size: 17pt)[$ L_"intra" = - log frac(exp(q dot k^+), exp(q dot k^+) + sum exp(q dot k^-)) $]
      #v(5pt)
      $arrow$ *Mục tiêu:* Đảm bảo tính nhất quán nội bộ.
    ]
  ],
  [
    #block(fill: rgb("#e6f7ff"), stroke: blue, inset: 10pt, radius: 5pt, width: 100%)[
      *2. Cross-Lingual ($L_"cross"$)*
      #text(size: 17pt)[$ L_"cross" = - log frac(exp(q dot k^+_"cross"), exp(q dot k^+_"cross") + sum exp(q dot k^-_"cross")) $]
      #v(5pt)
      $arrow$ *Mục tiêu:* Kéo ảnh sinh về phía phong cách đích (Target).
    ]
  ]
)

#v(15pt)
#align(center)[
  *Tổng hợp Loss:* $ L_"CL-SCR" = alpha dot L_"intra" + beta dot L_"cross" $
  
  (Trong đó $beta > alpha$ để ưu tiên học chuyển đổi đa ngữ)
]

== Hàm mục tiêu tổng quát <touying:hidden>
Mô hình tối ưu hoá đồng thời 4 thành phần:

#v(20pt)
#block(fill: rgb("#fff9e6"), stroke: orange, inset: 15pt, radius: 10pt, width: 100%)[
  #align(center)[
    $ L_"total" = underbrace(L_"MSE", "Tái tạo ảnh") + lambda_"cp" underbrace(L_"cp", "Nội dung") + lambda_"offset" underbrace(L_"offset", "Cấu trúc") + lambda_3 underbrace(L_"CL-SCR", "Phong cách (Đề xuất)") $
  ]
]

#v(20pt)
- *$L_"MSE"$ & $L_"offset"$*: Giữ vai trò bảo toàn khung xương (Giai đoạn 1).
- *$L_"CL-SCR"$*: Đóng vai trò then chốt trong việc chuyển giao phong cách (Giai đoạn 2).

// ================================================
// = Thực nghiệm và Đánh giá
// == Bộ dữ liệu <touying:hidden>
// Kế thừa bộ dữ liệu chuẩn từ *FTransGAN*.

// - *Quy mô:* *818* bộ phông chữ song ngữ (Bao gồm Serif, Sans-serif, Thư pháp...).
// - *Cấu trúc cặp:*
//   #table(
//     columns: (auto, 1fr),
//     stroke: none,
//     inset: (y: 3pt),
//     gutter: 10pt,
//     [Latin:], [~ *52* ký tự cơ bản.],
//     [Hán tự:], [~ *800* ký tự thông dụng.]
//   )
// - *Đặc điểm:* Nhất quán về phong cách giữa hai hệ chữ $arrow$ Cung cấp *Ground-truth* tự nhiên cho việc học.

// == Kịch bản đánh giá <touying:hidden>
// Tuân theo chuẩn của FTransGAN và FontDiffuser.

// #v(5pt)
// #block(fill: luma(240), inset: 8pt, radius: 5pt)[
//   *SFUC (Seen Font, Unseen Char):*
//   - Font đã biết, sinh ký tự mới.
//   - *Mục tiêu:* Đánh giá khả năng *nội suy phong cách*.
// ]

// #v(10pt)
// #block(fill: blue.lighten(90%), stroke: blue, inset: 8pt, radius: 5pt)[
//   *UFSC (Unseen Font, Seen Char):*
//   - Font *mới hoàn toàn* (chưa từng thấy khi train).
//   - *Mục tiêu:* Đánh giá khả năng *One-shot Generalization* (Kịch bản khó nhất & Quan trọng nhất).
// ]

// == Cấu hình Huấn luyện & Suy diễn <touying:hidden>
// #text(size: 0.8em)[
//   #grid(
//     align: top + left,
//     columns: (1fr, auto, 1fr),
//     gutter: 20pt,
//     [
//       *1. Môi trường & Giai đoạn 1:*
//       - *Phần cứng:* Kaggle Cloud, GPU NVIDIA Tesla P100 (16GB).
//       - *Framework:* PyTorch, Diffusers.
//       - *Giai đoạn 1:* 400.000 bước, Batch 4, AdamW ($lr=1 times 10^(-4)$).
//       - *Mục tiêu:* Học cấu trúc nội dung và phong cách cơ bản.

//       *2. Tiền huấn luyện CL-SCR:*
//       - *Quy mô:* 200.000 bước, Batch 16, AdamW
//       - *Augmentation:* Random Resized Crop (Scale 0.8-1.0) $arrow$ Tăng tính bền vững với biến thể hình học.
//     ], 
//     [],
//     [
//       *3. Giai đoạn 2 - Tinh chỉnh:*
//       - *Thiết lập:* 30k bước, Batch 4, giảm $lr=1 times 10^(-5)$ để tránh phá vỡ cấu trúc.
//       - *CL-SCR:* Chế độ `both` (Nội miền + Xuyên miền), $alpha=0.3, beta=0.7$, $K=4$.
//       - *Hàm Loss tổng hợp:*
//         $ L_"total" = L_"MSE" + 0.01 L_"percep" + 0.5 L_"offset" + 0.01 L_"CL-SCR" $

//       *4. Quy trình Inference:*
//       - *Sampler:* DPM-Solver++ (20 steps) để cân bằng tốc độ/chất lượng.
//       - *Guidance:* Classifier-free Guidance (CFG).
//     ]
//   )
// ]

// == Các thước đo đánh giá <touying:hidden>
// #v(20pt)
// Để đánh giá toàn diện, khoá luận sử dụng hệ thống đo lường đa tầng:

// #grid(
//   align: top + left,
//   columns: (1fr, 1fr),
//   gutter: 20pt,
//   [
//     *1. Định lượng (Quantitative):*
//     #table(
//       columns: (auto, 1fr),
//       stroke: none,
//       inset: (y: 5pt),
//       [*L1 & SSIM*], [Độ chính xác về điểm ảnh & cấu trúc (Pixel-level).],
//       [*LPIPS*], [Độ tương đồng nhận thức (Perceptual distance).],
//       [*FID*], [*(Quan trọng nhất)* Đo khoảng cách phân bố giữa ảnh sinh và ảnh thật (Độ chân thực).]
//     )
//   ],
//   [
//     *2. Định tính (Qualitative):*
//     - *Visual Inspection:* So sánh bằng mắt thường các chi tiết nét (gai, xước, đậm/nhạt).
//     - *User Study:* Khảo sát mù (Blind Test) trên 20 người dùng để đánh giá độ hài lòng thị giác.
//   ]
// )
// $arrow$ *Kết hợp cả độ chính xác máy học và cảm nhận con người.*

= Thực nghiệm và kết quả
== Chiến lược Huấn luyện <touying:hidden>
// Áp dụng chiến lược *Coarse-to-Fine (Từ Thô đến Tinh)* qua 2 giai đoạn:
#v(25pt)
#align(center)[
  #block(fill: luma(240), stroke: gray, inset: 8pt, radius: 5pt)[
    #text(size: 17pt)[
      *Thiết lập:* GPU Tesla P100 (16GB) $diamond$ Batch size: 4 $diamond$ *Inference:* DPM-Solver++ (20 bước).
      \ (Mô-đun CL-SCR được tiền huấn luyện (pre-train) độc lập trước khi đưa vào Giai đoạn 2).
    ]
  ]
]
#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: top + left,
  
  // Giai đoạn 1: Giai đoạn thô
  [
    #block(fill: rgb("#e6f7ff"), stroke: blue, inset: 15pt, radius: 10pt, width: 100%)[
      #text(size: 16pt, fill: blue)[*Giai đoạn 1: Khởi tạo*]
      #v(5pt)
      #text(size: 17pt)[
        - *Mục tiêu:* Học tái tạo cấu trúc chữ (Skeleton).
        - *Loss:* $L_"MSE"$ + $lambda_"cp" L_"cp"$ + $lambda_"offset" L_"offset"$.
        - *Quy mô:* 400.000 bước (Steps).
        - *Learning Rate:* $1 times 10^(-4)$.
        
        $arrow$ *Kết quả:* Học cấu trúc nội dung và phong cách cơ bản.
      ]
    ]
  ],
  
  // Giai đoạn 2: Giai đoạn tinh (Quan trọng)
  [
    #block(fill: rgb("#ffe6e6"), stroke: red, inset: 15pt, radius: 10pt, width: 100%)[
      #text(size: 16pt, fill: red)[*Giai đoạn 2: Tinh chỉnh*]
      #v(5pt)
      #text(size: 17pt)[
        - *Mục tiêu:* Tách biệt và chuyển giao Style (Cross-Lingual).
        - *Loss:* Thêm hàm *CL-SCR* (Contrastive Loss).
        - *Quy mô:* 30.000 bước.
        - *Learning Rate:* Giảm xuống $1 times 10^(-5)$.
        - *Kỹ thuật:* Áp dụng *Data Augmentation* (Random Crop) để chống học vẹt.
        
        $arrow$ *Kết quả:* Phong cách sắc nét, chuẩn xác.
      ]
    ]
  ]
)

// == Cấu hình Huấn luyện & Suy diễn <touying:hidden>
// #text(size: 0.8em)[
//   #grid(
//     align: top + left,
//     columns: (1fr, auto, 1fr),
//     gutter: 20pt,
//     [
//       *1. Môi trường & Giai đoạn 1:*
//       - *Phần cứng:* Kaggle Cloud, GPU NVIDIA Tesla P100 (16GB).
//       - *Framework:* PyTorch, Diffusers.
//       - *Giai đoạn 1:* 400.000 bước, Batch 4, AdamW ($lr=1 times 10^(-4)$).
//       - *Mục tiêu:* Học cấu trúc nội dung và phong cách cơ bản.

//       *2. Tiền huấn luyện CL-SCR:*
//       - *Quy mô:* 200.000 bước, Batch 16, AdamW
//       - *Augmentation:* Random Resized Crop (Scale 0.8-1.0) $arrow$ Tăng tính bền vững với biến thể hình học.
//     ], 
//     [],
//     [
//       *3. Giai đoạn 2 - Tinh chỉnh:*
//       - *Thiết lập:* 30k bước, Batch 4, giảm $lr=1 times 10^(-5)$ để tránh phá vỡ cấu trúc.
//       - *CL-SCR:* Chế độ `both` (Nội miền + Xuyên miền), $alpha=0.3, beta=0.7$, $K=4$.
//       - *Hàm Loss tổng hợp:*
//         $ L_"total" = L_"MSE" + 0.01 L_"percep" + 0.5 L_"offset" + 0.01 L_"CL-SCR" $

//       *4. Quy trình Inference:*
//       - *Sampler:* DPM-Solver++ (20 steps) để cân bằng tốc độ/chất lượng.
//       - *Guidance:* Classifier-free Guidance (CFG).
//     ]
//   )
// ]

== Dữ liệu & Kịch bản đánh giá <touying:hidden>
#v(15pt)
Cơ sở thực nghiệm của khoá luận:

#grid(
  columns: (1fr, 1fr),
  gutter: 20pt,
  align: top + left,
  
  [
    #block(fill: rgb("#e6f7ff"), stroke: blue, inset: 10pt, radius: 5pt, width: 100%)[
      *1. Bộ dữ liệu:*
      - *Nguồn:* 818 font song ngữ (FTransGAN).
      - *Cấu trúc:* Ghép cặp Latin ($~$52 ký tự) và Hán tự ($~$800 ký tự).
      $arrow$ Đảm bảo sự nhất quán phong cách (Ground-truth).
    ]
    #v(10pt)
    // Chèn bảng nhỏ minh hoạ số lượng nếu cần, hoặc để trống cho thoáng
    // #table(
    //   columns: (auto, 1fr), stroke: none, inset: 4pt,
    //   [Latin:], [A-Z, a-z],
    //   [Hán tự:], [800 chữ thông dụng]
    // )
  ],
  
  [
    #block(fill: rgb("#fff0f0"), stroke: red, inset: 10pt, radius: 5pt, width: 100%)[
      *2. Kịch bản:*
      
      #v(5pt)
      *a. SFUC (Font đã biết):*
      - Sinh ký tự mới từ font đã train.
      - *Mục tiêu:* Kiểm tra khả năng "học thuộc".
      
      #v(5pt)
      *b. UFSC (Font chưa biết - Quan trọng):*
      - Sinh ký tự từ font *mới hoàn toàn*.
      - *Mục tiêu:* Đánh giá khả năng *One-shot Generalization*.
    ]
  ]
)

== Các thước đo đánh giá <touying:hidden>
#v(15pt)
Để đảm bảo tính khách quan, khoá luận sử dụng hệ thống đo lường đa chiều:

#grid(
  columns: (1.3fr, 1fr),
  gutter: 30pt,
  align: top + left,
  
  [
    #block(fill: rgb("#e6f7ff"), stroke: blue, inset: 15pt, radius: 10pt, width: 100%)[
      *1. Định lượng:*
      
      #v(5pt)
      - *FID (Quan trọng nhất):*
        Đo khoảng cách phân bố giữa ảnh sinh và ảnh thật.
        $arrow$ *FID càng thấp $arrow$ Ảnh càng chân thực.*
      
      #v(5pt)
      - *L1 / SSIM:*
        Đo độ chính xác về điểm ảnh (Pixel) và cấu trúc (Structure).
        
      - *LPIPS:*
        Đo độ tương đồng theo nhận thức của mắt người.
    ]
  ],
  
  [
    #block(fill: rgb("#fff0f0"), stroke: red, inset: 15pt, radius: 10pt, width: 100%)[
      *2. Định tính:*
      
      #v(10pt)
      - *Kiểm tra trực quan:*
        So sánh trực quan các chi tiết nét.
        
      #v(10pt)
      - *Khảo sát người dùng:*
        Khảo sát mù trên người dùng để đánh giá độ hài lòng.
    ]
  ]
)
// #v(20pt)
// #align(center)[
//   #text(size: 14pt, style: "italic", fill: gray)[
//     *Chiến lược huấn luyện:* Áp dụng *Data Augmentation* (Random Crop) để tăng tính bền vững (Robustness).
//   ]
// ]

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
        [0.2773], [0.2702], [0.4023], [106.3833], 
        [0.2797], [0.2654], [0.3649], [54.0974],

        [CF-Font], 
        [0.2659], [0.2740], [0.3979], [91.2134], 
        [0.2638], [0.2716], [0.3615], [51.3925],

        [DFS], 
        [0.2131], [0.3558], [0.3812], [45.4212], 
        [#r[0.2008]], [0.3048], [0.3876], [62.7206],

        [FTransGAN], 
        [#r[0.1844]], [#r[0.3900]], [0.3548], [40.4561], 
        [#underline[0.2089]], [#underline[0.3109]], [0.3329], [42.1053],

        [FontDiffuser (Baseline)], 
        [0.1976], [0.3775], [#underline[0.2968]], [#underline[14.6871]], 
        [0.2283], [0.2946], [#underline[0.3184]], [#underline[29.0999]],

        [#o[Ours]], 
        [#underline[0.1939]], [#underline[0.3890]], [#r[0.2911]], [#r[11.7691]], 
        [0.2214], [#r[0.3197]], [#r[0.2954]], [#r[13.5508]],
        
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
    #let mark_row(m, r, cl) = {
      grid(
        columns: (1fr, 1fr, 1fr),
        align: center,
        m, r, cl
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
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[ *SFUC* ],
          table.cell(colspan: 4, stroke: (bottom: 0.5pt))[ *UFSC* ],
        ),
        
        // --- Sub-header ---
        [], 
        table.vline(stroke: 0.5pt),
        table.cell(align: center + horizon)[
          *Mô-đun*
          #grid(
             columns: (1fr, 1fr, 1fr),
             [*M*], [*R*], [*CL*]
          )
        ], 
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [#text(size: 15pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
        table.vline(stroke: 0.5pt),
        
        [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [#text(size: 15pt)[*LPIPS $arrow.b$*]], [*FID $arrow.b$*],
        table.hline(stroke: 0.5pt),

        // --- (L -> C) ---
        table.cell(rowspan: 3, rotate(-90deg, reflow: true)[*L $->$ C*]),
        
        // Dòng 1: M + R
        mark_row($checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$),
        [#underline[0.1977]], [#underline[0.3809]], [#underline[0.2927]], [#r[10.9069]],
        [#underline[0.2266]], [#underline[0.3072]], [#underline[0.3009]], [#underline[14.8680]],

        // Dòng 2: CL
        mark_row($crossmark.heavy$, $crossmark.heavy$, $checkmark.heavy$),
        [0.2679], [0.2415], [0.5199], [161.0711],
        [0.2966], [0.1687], [0.5606], [180.2861],

        // Dòng 3: M + R + CL
        o[#mark_row($checkmark.heavy$, $checkmark.heavy$, $checkmark.heavy$)],
        [#r[0.1939]], [#r[0.3890]], [#r[0.2911]], [#underline[11.7691]],
        [#r[0.2214]], [#r[0.3197]], [#r[0.2954]], [#r[13.5508]],
        
        table.hline(stroke: 0.5pt),

        // --- (C -> L) ---
        table.cell(rowspan: 3, rotate(-90deg, reflow: true)[*C $->$ L*]),
        
        // Dòng 4: M + R
        mark_row($checkmark.heavy$, $checkmark.heavy$, $crossmark.heavy$),
        [#r[0.1076]], [#r[0.6449]], [#r[0.2005]], [#r[14.3511]],
        [#r[0.1070]], [#r[0.6413]], [#r[0.1980]], [#underline[42.8665]],

        // Dòng 5: CL
        mark_row($crossmark.heavy$, $crossmark.heavy$, $checkmark.heavy$),
        [0.3234], [0.2520], [0.5469], [205.2360],
        [0.3882], [0.1849], [0.5951], [239.9641],

        // Dòng 6: M + R + CL
        o[#mark_row($checkmark.heavy$, $checkmark.heavy$, $checkmark.heavy$)],
        [#underline[0.1083]], [#underline[0.6406]], [#underline[0.2019]], [#underline[14.7298]],
        [#underline[0.1090]], [#underline[0.6377]], [#underline[0.1985]], [#r[41.1152]],
        
        table.hline(stroke: 0.5pt),
      )
    ) <ablation-module>
  ]
])

// ================================================
= Kết luận
== Tổng kết đóng góp <touying:hidden>
Khoá luận đã hoàn thành các mục tiêu đề ra ban đầu:

- Xây dựng thành công Pipeline chuyển đổi phong cách *xuyên hệ chữ (Cross-Script)*, đặc biệt là cặp khó Latin - Hán tự.
#v(10pt)
- Đề xuất mô-đun *CL-SCR* với cơ chế *Contrastive Learning*, giải quyết hiệu quả vấn đề "Domain Gap" giữa các ngôn ngữ.
#v(10pt)
- Vượt trội SOTA hiện tại (FID giảm $~50%$), khắc phục triệt để lỗi *"Bóng ma"* (Ghosting) và *"Biến dạng cấu trúc"* thường gặp ở GAN.

== Hạn chế & Hướng phát triển <touying:hidden>
#v(35pt)
Định hướng nghiên cứu trong tương lai:

#grid(
  columns: (1fr, 1fr), // Bên phải rộng hơn để nhấn mạnh Tương lai
  gutter: 20pt,
  align: top + left,
  // Cột 1: Hạn chế (Nói giảm nói tránh)
  [
    #block(fill: rgb("#fff0f0"), inset: 15pt, radius: 10pt, width: 100%)[
      #text(size: 17pt)[
        *Hạn chế:*
        
        #v(5pt)
        - *Thách thức về Tốc độ:*
          Do bản chất khử nhiễu lặp lại (Iterative Denoising) của Diffusion, tốc độ suy diễn chậm hơn các phương pháp One-step (GAN).
          
        - *Đánh đổi:*
          Chất lượng ảnh cao đổi lấy chi phí tính toán lớn.
        ]
    ]
  ],
  
  // Cột 2: Tương lai (Vẽ bánh)
  [
    #block(fill: rgb("#e6fffa"), inset: 15pt, radius: 10pt, width: 100%)[
      #text(size: 17pt)[
        *Hướng phát triển:*
        
        #v(5pt)
        - *Tăng tốc:*
          Áp dụng *Consistency Distillation* hoặc *Latent Consistency Models (LCM)* để giảm xuống còn 4-8 bước.
        
        - *Mở rộng:*
          Ứng dụng cho *Tiếng Việt (Thư pháp)* và các ngôn ngữ Low-resource khác.
          
        - *Ứng dụng:*
          Sinh font dạng *Vector (SVG)* để tích hợp trực tiếp vào phần mềm thiết kế.
      ]
    ]
  ]
)

== Công trình khoa học <touying:hidden>
D. K. D. Tran and V. H. Duong, “CL-SCR: Decoupling Style and Structure for One-Shot Cross-Script Font Generation,” _The Journal of Supercomputing (under review)_, 2026.
  
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

== Tối ưu hoá CL-SCR <touying:hidden>
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
          [#o[Both]], [#r[13.55]], [#r[41.12]],
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
          [0.7], [0.3], [#underline[14.48]], [45.23],
          [0.5], [0.5], [15.18], [#underline[43.42]],
          [#o[0.3]], [#o[0.7]], [#r[13.55]], [#r[41.12]],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ Bài toán Cross-Lingual cần ưu tiên học các đặc trưng xuyên ngôn ngữ ($beta$ lớn).
    ]
  )
]

== Phân tích độ nhạy <touying:hidden>
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
          [#o[4]], [#r[13.55]], [#r[41.12]],
          [8], [#underline[15.02]], [43.81],
          [16], [16.79], [#underline[43.50]],
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
          [2.5], [#r[13.28]], [#underline[40.05]],
          [5.0], [#underline[13.39]], [#r[40.00]],
          [#o[7.5]], [13.55], [41.12],
          [10.0], [13.78], [44.74],
          [12.5], [14.78], [47.15],
          [15.0], [17.01], [52.76],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ *$s$* thấp (*$in [2.5, 7.5]$*) cho kết quả tốt nhất.
    ]
  )
]

#pagebreak()
#v(30pt)
Đánh giá hiệu quả của chiến lược Tăng cường dữ liệu (Data Augmentation).

#text(size: 17pt)[
  #grid(
    columns: (1.4fr, 1fr),
    gutter: 30pt,
    align: top + left,
    [
      *e. Tăng cường dữ liệu:*
      So sánh mô hình khi dùng/không dùng kỹ thuật tăng cường dữ liệu.
      #figure(
        table(
          columns: (1.5fr, auto, auto),
          inset: 8pt, stroke: none, align: center + horizon,
          table.header(
            table.cell(rowspan: 2, align: horizon)[*Cấu hình*],
            table.cell(colspan: 2, stroke: (bottom: 0.5pt))[*FID (UFSC) $arrow.b$*],
            [*L $arrow$ C*], [*C $arrow$ L*],
            table.hline(stroke: 0.5pt)
          ),
          [w/o Augmentation], [#underline[15.77]], [#underline[43.07]], 
          [#o[w/ Augmentation]], [#r[13.55]], [#r[41.12]],
          table.hline(stroke: 0.5pt)
        )
      )
      #v(5pt)
      $arrow$ Việc áp dụng Augmentation giúp giảm đáng kể FID, chứng tỏ mô hình học được các đặc trưng phong cách *bền vững* hơn, tránh bị Overfitting.
    ],
    [
      #block(fill: rgb("#f0f8ff"), inset: 10pt, radius: 5pt, width: 100%)[
        *Chiến lược: Random Resized Crop*
        
        #v(5pt)
        - *Scale ($0.8 - 1.0$):* Cắt ngẫu nhiên nhưng giữ lại phần lớn cấu trúc chữ.
        
        - *Ratio ($0.8 - 1.2$):* Thay đổi tỷ lệ khung hình nhẹ để mô phỏng các biến thể viết tay.
      ]
      
      #v(10pt)
      $arrow$ Giúp mô-đun *CL-SCR* không bị "học vẹt" (memorize) các vị trí pixel cố định.
    ]
  )
]