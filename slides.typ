#import "@preview/touying:0.5.3": *
#import "stargazer.typ": *
#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge

#import "@preview/numbly:0.1.0": numbly

#show: stargazer-theme.with(
  aspect-ratio: "16-9",
  config-info(
    subtitle: [Tích hợp các phép biến hình cấu trúc cây cải tiến suy luận tiến hóa trong MPBoot],
    author: [Huỳnh Tiến Dũng],
    instructor: [TS. Hoàng Thị Điệp],
    date: "17/12/2024",
    institution: [Trường Đại học Công Nghệ - ĐHQGHN],
  ),
)
#set text(font: "New Computer Modern", lang: "vi")
#set heading(numbering: numbly("{1}.", default: "1.1."))
#set par(justify: true)
#show figure.caption: set text(17pt)

#slide(navigation: none, progress-bar: false, self => [
  #v(0.5cm)
  #grid(
    columns: (auto, auto, 11pt, 1fr, 1fr, 8fr),
    align: auto,
    [#h(105pt)],
    // [#v(-20pt)#image("images/dhqg.png")],
    [],
    // [#v(-20pt)#image("images/UET.png", width: 75%)],
    // [#v(-20pt)#image("images/cntt.png", width: 75%)],
    align(center, [
      #set text(size: 15pt)
      ĐẠI HỌC QUỐC GIA HÀ NỘI \
      TRƯỜNG ĐẠI HỌC CÔNG NGHỆ \
      #text(10pt, strong("———————o0o——————–"))
    ])
  )
  #v(0.4cm)
  #align(center, text(27pt, upper(strong("Tích hợp các phép biến hình cấu trúc cây cải tiến suy luận tiến hóa theo tiêu chuẩn Parsimony trong MPBoot"))))
  #v(0.5cm)
  #align(center, [
    #set text(size: 18pt)
    #grid(
      columns: (auto, auto),   
      align: (left, left),
      column-gutter: 26pt,
      row-gutter: 18pt,
      [Sinh viên thực hiện:], [*Huỳnh Tiến Dũng*], 
      [Giảng viên hướng dẫn:], [*TS. Hoàng Thị Điệp*],
      [Lớp khóa học:], [QH-2021-I/CQ-I-IT15],
      [Khoa:], [Công nghệ thông tin]
    )
  ])

  #v(1fr)
])

#outline-slide(title: "Mục lục")

// == Outline <touying:hidden>

// #components.adaptive-columns(outline(title: none, indent: 1em))

= Giới thiệu
== Tiến hóa sinh học <touying:hidden>
#v(1cm)
#grid(
  columns: (240pt, 510pt),
  gutter: 10pt,
  align: center + horizon,
  [
    #v(0.4cm)
    #text(27pt, "Phylogenetic\n")
    #text(17pt, "(Tiến hóa sinh học)")
  ],
  grid.cell(rowspan: 2)[
    // #image("images/treeoflife.png", height: 92%)
  ],
  [
    // #image("images/darwin.png", height: 70%)
  ]
)
== Một cây tiến hóa đơn giản <touying:hidden>
#v(0.7cm)
#align(center, 
[
  // #image("images/phytree.png", width: 93%)
])
== Ứng dụng rộng rãi trong dịch tễ học <touying:hidden>
#v(0.7cm)
#align(center, 
[
  // #image("images/covid.png", width: 105%)
])
== Xây dựng cây tiến hóa <touying:hidden>
#v(0.7cm)
#grid(
  columns: (auto, auto),
  gutter: 40pt,
  align: horizon,
  [
    #pad(left: 20pt, [
      *Đầu vào*:\
      Sắp hàng đa\ chuỗi (MSA) \ \
      *Đầu ra*:\
      Cây tiến hóa\ tương ứng
    ])
  ],
  [
    // #image("images/phytree1.png", height: 94%)
  ],
)

== Xây dựng cây tiến hóa bootstrap <touying:hidden>
#v(0.3cm)
#grid(
  columns: (290pt, auto),
  gutter: 35pt,
  align: horizon,
  [
    #pad(left: 20pt, [
      1. Thực hiện xây dựng tìm kiếm cây tối ưu nhất.

      2. Đánh giá độ tin cậy của các phân nhánh/cạnh trong cây bằng tần suất tương ứng trên tập các cây bootstrap.
    ])
  ],
  [
    // #image("images/boot1.png", width: 99%)
  ],
)
#pagebreak()
#v(0.8cm)
// #image("images/boot.png", width: 105%)
== Mô hình Bootstrap chuẩn (SBS; Felsenstein 1985) <touying:hidden>
#v(0.7cm)
#align(center, [
  // #image("images/boot2.png", width: 85%)
])

== Mô hình Bootstrap xấp xỉ (MPBoot; Hoang 2018) <touying:hidden>
#v(0.7cm)
#align(center, [
  // #image("images/boot3.png", width: 75%)
])

== Tiêu chí Maximum Parsimony <touying:hidden>
#v(1.3cm)
- Điểm số MP là số lượng tối thiểu các đột biến của cây cần thiết để giải thích MSA.

- Xây dựng cây MP là bài toán NP-complete (Foulds & Graham 1982)
- Phương pháp chung: Khám phá mẫu không gian các cây nhị phân n lá. Với mỗi cây tìm thấy, tính điểm MP. Chọn cây có điểm MP thấp nhất.
  - sử dụng Fitch cho chi phí đột biến đều.
  - sử dụng Sankoff cho chi phí đột biến không đều.

#align(center, [
  // #image("images/mp.png")
])

== Các phép biến đổi cây thường dùng <touying:hidden>

#v(0.9cm)
#align(center, [
  // #image("images/3-ops.png", width: 80%)
])

== Câu hỏi nghiên cứu <touying:hidden>
*Làm thế nào để cải thiện hiệu quả lấy mẫu cây tiến hóa trong MPBoot?*

- Tích hợp phép Tree Bisection and Reconnection (TBR) vào các thủ tục leo đồi trong MPBoot.

- Kết hợp leo đồi sử dụng cả NNI, SPR, TBR bằng phương pháp học tăng cường giải thuật đàn kiến (ACO) nhằm lựa chọn phép biến đổi phù hợp nhất với dữ liệu đầu vào.

= Tích hợp phép TBR vào MPBoot 

== Khung thuật toán MPBoot gốc <touying:hidden>
#v(0.8cm)
#grid(
  columns: (1fr, auto),
  gutter: 40pt,
[
  #set text(size: 17pt)
- *Pha 1. Khởi tạo*
  - Tạo tập ứng cử viên $cal(C)$ gồm $C$ cây sử dụng thuật toán randomized stepwise addition, sau đó tối ưu bằng leo đồi *SPR*.
- *Pha 2. Khám phá*
  - Chọn một cây ngẫu nhiên $T$ từ tập $cal(C)$.
  - Thực hiện chiến lược phá cây trên $T$, xen kẽ giữa NNI ngẫu nhiên và ratchet với leo đồi *SPR*.
  - Thực hiện leo đồi *SPR* theo sau với cây nhận được.
  - Tập cây bootstrap $cal(B)$ được cập nhật cùng với bước tìm kiếm cây.

- *Pha 3. Tinh chỉnh*
  - Mỗi cây bootstrap sẽ được tối ưu sử dụng leo đồi *SPR* thực hiện trên MSA tương ứng.
],
  grid.cell(align: center)[
    #pause
    Phép *SPR* được sử dụng\ trong toàn bộ framework
    #pause
    *$ arrow.b.double $*
    Sử dụng *TBR* toàn diện\ hơn SPR có thể dẫn đến cây MP\ và tập bootstrap tốt hơn.
  ]
)

== Ví dụ về một phép TBR <touying:hidden>
#v(1.2cm)
- Cây $T^"lst"$
- Cạnh cắt $R$
- Cạnh nối $I_1$ và $I_2$ (thuộc 2 cây con khác nhau sau khi cắt cạnh $R$)
- Cây kết quả $T^*$

#v(0.1cm)
#align(center, [
  // #image("images/tbr.png", width: 107%)
])
== Tính toán nhanh một phép biến đổi TBR <touying:hidden>
#grid(
  columns: 3,
  align: horizon,
  gutter: 50pt,
  [Tiếp cận trực tiếp], [=====>], [Duyệt post-order lại toàn bộ cây và tính theo thuật toán Fitch hoặc Sankoff #pause],
  [#emoji.lightbulb Tuy nhiên, nhiều cây con *không thay đổi cấu trúc* (điểm MP) sau một phép TBR], [=====>], [Chỉ tính lại điểm của những đỉnh có thay đổi điểm số ]
)
#pagebreak()

#v(0.8cm)
#align(center, [
  // #image("images/tbr-fast1.png", width: 80%)
])
#v(-0.3cm)
#[
  #set text(size: 16pt)
  #grid(
    columns: (1fr, 1fr),
    align: center,
    [#h(60pt)*(A) Cây $T^"lst"$*], [*(B) Cây $T^*$*]
  )
  #set text(size: 19pt)
  - Các đỉnh in xanh cần phải tính lại điểm (Các đỉnh trên đường đi từ $I_1$ đến gốc và trên đường đi từ $I_2$ đến gốc của $T^"lst"$)
  - Đổi gốc của cây $T^*$ thành $R$.
  - Cây $T^*$ sẽ được sử dụng làm cây $T^"lst"$ cho phép biến đổi TBR tiếp theo.

  $arrow.r.double$ Số lượng đỉnh cần phải tính lại điểm giảm xuống $O("maxtrav")$ ở hầu hết các trường hợp.
]

== Thuật toán leo đồi sử dụng TBR <touying:hidden>
- Tìm kiếm cây lân cận sử dụng TBR. Với:

  - Cạnh cắt $R$

  - Khoảng bán kính $["mintrav", "maxtrav"]$ (điều kiện về khoảng cách giữa 2 cạnh nối)
#pause

#h(25pt)#diagram({
  let (a, b, c) = ((0,0.3), (1, 0),(1,0.6))
  node(a)
  node(b, name: <b>, [#h(7pt) Chiến lược tìm kiếm "tốt nhất"])
  node(c, name: <c>, [#h(7pt) Chiến lược tìm kiếm "tốt hơn"])
  edge(a, <b.west>, "-|>")
  edge(a, <c.west>, "-|>")
})
#pause

- Cập nhật cây $T$ bằng $T^"bestNei"$ tìm được.

$arrow.r.double$ Thủ tục tìm kiếm lặp lại nếu điểm số MP của cây $T$ vẫn được cải thiện.

== Chiến lược tìm kiếm "tốt nhất" <touying:hidden>
#grid(
  columns: 2,
  column-gutter: 45pt, 
  [
    - Cắt cây tại cạnh $R$

    - Xét mọi cặp cạnh $(I_1, I_2)$ thỏa khoảng cách giữa 2 cạnh nối nằm trong điều kiện bán kính ban đầu:
      - Nối cạnh $I_1$ với $I_2$ thông qua $R$
      - Đánh giá cây kết quả, cập nhật $T^"bestNei"$
      - Cắt cạnh $R$
    - Nối lại cạnh $R$, hoàn tác lại cây $T$

    $arrow.r.double$ Nhận được một cây $T^"bestNei"$ tốt nhất trong khoảng lân cận tìm kiếm của cây 
  ],
  [
    #v(20pt)
    // #image("images/tbr-best.png", height: 94%)
  ]
)

== Chiến lược tìm kiếm "tốt hơn" <touying:hidden>

#grid(
  columns: 2,
  column-gutter: 30pt, 
  align: horizon, 
  [
    #diagram(node-outset: 10pt, {
      let (a, b) = ((0,0), (0, 1))
      node(a, name: <a>, [*BEST*: $T$ được cập nhật tối đa 1 lần\ với mỗi cạnh cắt $R$])
      node(b, name: <b>, [*BETTER*: $T$ được cập nhật tối đa 1 lần\ với mỗi cặp cạnh cắt $R$ và cạnh nối $I_1$])
      edge(<a.south>, <b.north>, "-|>")
    })
  ],
  [
    // #image("images/tbr-better.png", width: 110%)
  ]
)
#v(10pt)
$arrow.r.double$ Với mỗi cặp cạnh $(R, I_1)$, xét mọi cạnh nối $I_2$ thỏa mãn, xác định cây lân cận tốt nhất $T^"bestNei"$. Cập nhật $T$ thành $T^"bestNei"$ nếu tốt hơn và tiếp tục chiến lược với cây $T$.

= Đề xuất MPBoot2
== Đề xuất MPBoot2 <touying:hidden>
- Tích hợp leo đồi sử dụng TBR vào MPBoot. Tinh chỉnh bán kính khảo sát và điều kiện dừng.

- Một số tính năng mới như:
  - Checkpoint
  - Cải thiện xử lý với bộ dữ liệu lớn
  - Hỗ trợ dữ liệu morphology, nhị phân

$arrow.r.double$ Đề xuất phiên bản MPBoot2

= Đề xuất MPBoot-RL
== Ý tưởng <touying:hidden>
#v(18pt)
#align(center, [
  // #image("images/mpboot-rl.png", width: 105%)
])
== Giải thuật đàn kiến <touying:hidden>
#v(20pt)
#align(center, [
  // #image("images/aco.png", width: 59%)
])
== Cấu trúc đồ thị <touying:hidden>
#v(25pt)
#align(center, [
  // #image("images/network.png", width: 42%)
])
== Thông tin Heuristics <touying:hidden>
#align(center, [
  #diagram(node-outset: 10pt, {
    node((0, 0), name: <a>, [NNI, SPR, TBR])
    node((4, 0), name: <b>, [$eta_"NNI",space eta_"SPR",space eta_"TBR"$])
    edge(<a.east>, <b.west>, "-|>", [Tham số đầu vào])
  })
])

== Quy tắc cập nhật mùi pheromone - SMMAS-once <touying:hidden>
#[
#v(20pt)
#let fletcher-diagram = touying-reducer.with(reduce: fletcher.diagram, cover: fletcher.hide)
#let (a, b, c, d, e, f) = ((0,3), (1, 0),(1,3), (4,0), (4,3), (4, 2))
#fletcher-diagram(
  node-outset: 10pt,
  node(a, [*Quy tắc SMMAS\ (sau một thế hệ kiến)*]),
  pause,
  node(b),
  node(d, $tau_e arrow.l (1- rho) dot.c tau_e + rho dot.c tau_"max"$),
  node(f, name: <f>, $tau_e arrow.l (1- rho) dot.c tau_e + rho dot.c tau_"max"$),
  edge(a, b, "->", $in "lời giải tốt"$, label-side: left, stroke: 3pt + rgb("#93c47d")),
  edge(b, d, "->", $"MP"_"new" <= "MP"_"cur_best"$, stroke: 3pt + rgb("#93c47d"),label-sep: 15pt),
  edge(b, <f.west>, "->", label: "fallback\nto NNI", label-side: right, stroke: 3pt + rgb("#93c47d")),
  pause,
  node(e, $tau_e arrow.l (1- rho) dot.c tau_e + rho dot.c tau_"min"$),
  edge(a, e, "->", $in.not "lời giải tốt"$, label-side: right, stroke: 3pt + rgb("#990000")),
)
]
== Quy tắc cập nhật mùi pheromone - SMMAS-multiple <touying:hidden>
#diagram(node-outset: 10pt, {
  node((0, 0), name: <a>, [*SMMAS-once*])
  node((2, 0), name: <aa>, [Mỗi cạnh chỉ được cập nhật mùi đúng 1 lần])
  node((0, 1), name: <b>, [*SMMAS-multiple*])
  node((2, 1), name: <bb>, [Gọi $k$ là số lượng lời giải tốt mà cạnh $e$ tham gia])
  edge(<a.east>, <aa.west>, "-|>")
  edge(<b.east>, <bb.west>, "-|>")
})
#v(20pt)
#align(center, [
  #diagram(node-outset: 10pt, {
    let (a, b, c) = ((0,0.3), (1, 0),(1,0.6))
    node(a)
    node(b, name: <b>, [$k > 0:$])
    node((1.9, 0), width: 400pt, align(left)[$tau_e arrow.l (1- rho) dot.c tau_e + rho dot.c tau_"max" space space space$ (lặp lại $k$ lần)])
    node(c, name: <c>, [$k = 0:$ ])
    node((1.9, 0.6), width: 400pt, align(left)[$tau_e arrow.l (1- rho) dot.c tau_e + rho dot.c tau_"min"$])
    edge(a, <b.west>, "-|>")
    edge(a, <c.west>, "-|>")
  })
])
== Quy trình bước đi ngẫu nhiên <touying:hidden>
$ "prob"_(A arrow.r B) = (tau_(A arrow.r B) dot.c eta_B) / (sum_(C in "adj"(A)) tau_(A arrow.r C) dot.c eta_C) $

trong đó:
#[

#set list(indent: 0.8em)
- $"prob"_(A arrow.r B)$ là xác suất con kiến ở đỉnh $A$ di chuyển đến đỉnh $B$.

- $tau_(A arrow.r B)$ là mức độ pheromone của cạnh từ $A$ đến $B$.
- $eta_B$ là thông tin heuristic của đỉnh $B$.
- $"adj"(A)$ là tập các đỉnh mà $A$ nối tới.
]

= Thực nghiệm và kết quả
== Cài đặt thực nghiệm <touying:hidden>
#[
  #v(20pt)
  #set list(indent: 0.4cm)
  #grid(
    columns: (1fr, 1fr),
    align: top + left,
    [
      - *TBR5* 
        - bán kính 5, chiến lược "tốt nhất"

      - *TBR5-SC100* ($n'=100$)
      - *TBR5-BETTER* 
        - bán kính 5, chiến lược "tốt hơn"
      - *TBR6*
        - bán kính 6, chiến lược "tốt nhất"

      - *SPR6* (MPBoot cũ)
      - *TNT*:
        - intensive
        - SOTA
    ],
    [
      - *ACO-MUL*:
        - $rho=0.25$
        - $eta_"NNI" = 0.3, space eta_"SPR" = 0.4, space eta_"TBR" = 0.4$

        - $L = L_0 + ceil(n/100)$ với $L_0 = 15$

      - *ACO-ONCE*
        - $rho=0.1$
        - $eta_"NNI" = 0.3, space eta_"SPR" = 0.4, space eta_"TBR" = 0.4$

        - $L = L_0 + ceil(n/100)$ với $L_0 = 5$
    ]
  )
]
== Các bộ dữ liệu <touying:hidden>
#v(10pt)
#figure(
  table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    inset: 8pt,
    align: center + horizon,
    [*Dataset*], [*Sub-dataset *], [*Data type*], [*\#MSAs*], [*\#sequences*], [*\#sites*],
    table.cell(rowspan: 5)[Yule-Harding], [YH1], table.cell(rowspan: 3)[DNA], [200], [100], [500],
    [YH2], [200], [200], [1000],
    [YH3], [200], [500], [1000],
    [YH4], table.cell(rowspan: 2)[Protein], [200], [100], [300],
    [YH5], [200], [200], [500],
    table.cell(rowspan: 2)[TreeBASE], [DNA], [DNA], [70], [201-767], [976-61199],
    [Protein], [Protein], [45], [50-194], [126-22426],
  ),
  caption: [Tóm tắt các bộ dữ liệu]
)
== TreeBASE DNA và Protein (Điểm MP) <touying:hidden>

#v(20pt)
#align(center, [
  // #image("images/treebase_4_aco.png", height: 94%)
])

== TreeBASE DNA và Protein (Thời gian thực thi) <touying:hidden>
#v(20pt)
#figure(
  table(
    columns: (2fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    inset: 7pt,
    align: (left, horizon, horizon, horizon, horizon, horizon, horizon),
    table.cell(rowspan: 2, align: horizon + center)[*Method*], table.cell(colspan: 3)[*Uniform cost*], table.cell(colspan: 3)[*Non-uniform cost*],
    [Time (hours)], [Mean], [Median], [Time (hours)], [Mean], [Median],
    [*ACO-MUL*], [*31.5*], [*0.79*], [*0.79*], [*144.7*], [*0.85*], [*0.84*],
    [*ACO-ONCE*], [*30.6*], [*0.78*], [*0.79*], [*141.0*], [*0.85*], [*0.84*],
    [SPR6], [37.2], [1.00], [1.00], [146.8], [1.00], [1.00],
    [TBR5-SC100], [30.2], [1.04], [0.96], [192.8], [1.26], [1.17],
    [TBR5], [54.5], [1.42], [1.43], [240.1], [1.52], [1.52],
    [TBR5-BETTER], [67.3], [1.62], [1.60], [269.3], [1.72], [1.71],
    [TBR6], [78.2], [1.98], [1.96], [338.8], [2.21], [2.18],
    [TNT], [75.5], [1.23], [0.47], [682.3], [6.47], [3.55],
  ), 
  caption: [Thời gian chạy tổng cộng (giờ) và tỷ lệ thời gian (so với SPR6 gốc) của các phương pháp trên 115 bộ dữ liệu từ TreeBASE]
) <tab-time-aco>
== Độ chính xác Bootstrap <touying:hidden>
#grid(
  columns: 2,
  align: center,
  row-gutter: 10pt,
  column-gutter: 68pt,
  [*TBR\**], [*ACO\**],
  // image("images/bootstrap.png", width: 125%),
  // image("images/bootstrap-aco.png", width: 125%)
)
== Khảo sát liên quan độ khó bộ dữ liệu <touying:hidden>
#grid(
  columns: 2,
  align: center,
  row-gutter: 10pt,
  column-gutter: 80pt,
  [*ACO-MUL*], [#h(0.8cm)*ACO-ONCE*],
  // image("images/acomul_diff.png", width: 125%),
  // image("images/acoonce_diff.png", width: 125%)
)
= Kết luận
== Kết luận <touying:hidden>
#v(0.8cm)
- *Kết quả đạt được*:

  - Tích hợp phép TBR vào MPBoot, đề xuất phiên bản MPBoot2 cùng với nhiều tính năng mới.

  - Kết hợp các phép biến đổi NNI, SPR, TBR sử dụng giải thuật đàn kiến, đề xuất phiên bản MPBoot-RL; đồng thời mở rộng khảo sát về độ khó bộ dữ liệu.

- *Định hướng phát triển*:

  - Phân tích độ khó bộ dữ liệu dựa trên thông số sử dụng các phép biến đổi cây kết hợp với các đặc tính khác của bộ dữ liệu.

  - Ý tưởng áp dụng giải thuật đàn kiến có thể áp dụng tương tự vào quá trình phá cây (các thuật toán phá cây như ratchet, random NNIs, IQP...)

== Công bố liên quan <touying:hidden>
- *T. D. Huynh*, Q. T. Vu, V. D. Nguyen and D. T. Hoang, "Employing tree bisection and reconnection rearrangement for parsimony inference in MPBoot," 2022 14th International Conference on Knowledge and Systems Engineering (KSE), Nha Trang, Vietnam, 2022, pp. 1-6, doi: 10.1109/KSE56063.2022.9953773.

== Lời cảm ơn <touying:hidden>

#v(0.5cm)
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
    [Sinh viên thực hiện:], [*Huỳnh Tiến Dũng*], 
    [Giảng viên hướng dẫn:], [*TS. Hoàng Thị Điệp*],
    [Lớp khóa học:], [QH-2021-I/CQ-I-IT15],
    [Khoa:], [Công nghệ thông tin]
  )
])


