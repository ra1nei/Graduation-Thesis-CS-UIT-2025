#import "/template.typ": *
#set text(lang: "vi")

#[
  #set heading(numbering: none, supplement: [Phụ lục])
  = Phụ lục <phuluc>
]

#set heading(numbering: (..nums) => {
  nums = nums.pos()
  numbering("A.1.", ..nums.slice(1))
}, supplement: [Phụ lục])

#counter(heading).update(1)

== Chi tiết Kiến trúc mạng UNet <pl-unet>

Mạng UNet đóng vai trò là bộ xương sống (backbone) trong mô hình khuếch tán, chịu trách nhiệm dự đoán nhiễu tại từng bước thời gian. Cấu trúc chi tiết của mạng được trình bày tại @tab:unet_arch, bao gồm các khối mã hoá (Encoder), giải mã (Decoder) và các mô-đun tích hợp đặc trưng như MCA và SI.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Loại Block*], [*Số lượng*], [*Kích thước đầu vào* \ ($C times H times W$)], [*Kích thước đầu ra* \ ($C times H times W$)]
    ),
    table.hline(),
    
    // Encoder Part
    [Conv block], [1], [$3 times H times W$], [$64 times H times W$],
    [Down block], [2], [$64 times H times W$], [$64 times H/2 times W/2$],
    [MCA block], [2], [$64 times H/2 times W/2$], [$128 times H/4 times W/4$],
    [MCA block], [2], [$128 times H/4 times W/4$], [$256 times H/8 times W/8$],
    [Down block], [2], [$256 times H/8 times W/8$], [$512 times H/8 times W/8$],
    
    // Bottleneck
    [MCA block], [1], [$512 times H/8 times W/8$], [$512 times H/8 times W/8$],
    
    // Decoder Part
    [Up block], [3], [$512 times H/8 times W/8$], [$256 times H/4 times W/4$],
    [SI block], [3], [$256 times H/4 times W/4$], [$256 times H/2 times W/2$],
    [SI block], [3], [$256 times H/2 times W/2$], [$128 times H times W$],
    [Up block], [3], [$128 times H times W$], [$64 times H times W$],
    [Conv block], [1], [$64 times H times W$], [$3 times H times W$],
  ),
  caption: [Chi tiết kiến trúc mạng UNet trong FontDiffuser. Trong đó: MCA là khối Tổng hợp nội dung đa quy mô, SI là khối Chèn phong cách (Style Insertion) sử dụng cơ chế Cross-Attention.]
) <tab:unet_arch>

#pagebreak()

== Chi tiết Kiến trúc mô-đun CL-SCR <pl-clscr>

Mô-đun CL-SCR được thiết kế dựa trên mạng VGG-19 pre-trained để trích xuất đặc trưng phong cách đa tầng, kết hợp với các lớp chiếu (Projector) để đưa về không gian vector phục vụ học tương phản. Cấu trúc chi tiết của mạng được trình bày tại @tab:cl_scr_arch.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: (col, row) => left + horizon,
    stroke: 0.5pt,
    table.header(
      [*Thành phần*], [*Lớp / Thao tác*], [*Kích thước đầu ra* \ (Batch $times$ C $times$ H $times$ W)]
    ),
    table.hline(),

    // Input & Augmentation
    table.cell(rowspan: 2)[*Input Processing*],
    [Input Image ($x$)], [$B times 3 times 64 times 64$],
    [Data Augmentation \ (RandomResizedCrop + Normalize)], [$B times 3 times 64 times 64$],

    // Style Extractor (VGG)
    table.cell(rowspan: 5)[*Style Extractor* \ (Backbone: VGG-19)],
    [Block 1 ($"ReLU"^1_1$)], [$B times 64 times 64 times 64$],
    [Block 2 ($"ReLU"^2_1$)], [$B times 128 times 32 times 32$],
    [Block 3 ($"ReLU"^3_1$)], [$B times 256 times 16 times 16$],
    [Block 4 ($"ReLU"^4_1$)], [$B times 512 times 8 times 8$],
    [Block 5 ($"ReLU"^5_1$)], [$B times 512 times 4 times 4$],

    // Style Projector
    table.cell(rowspan: 4)[*Style Projector* \ (Shared weights)],
    [Fusion (Avg+Max Pool $arrow$ Conv1x1)], [$B times C_"reduced"$],
    [MLP Layer 1 (Linear + ReLU)], [$B times 1024$],
    [MLP Layer 2 (Linear + ReLU)], [$B times 2048$],
    [Output Layer (Linear + Normalize)], [$B times 2048$ \ (Style Vector $v$)],

    // Loss Calculation
    table.cell(rowspan: 2)[*Contrastive Loss* \ (InfoNCE)],
    [Dynamic Sampling (Intra/Cross)], [$K=4$ mẫu âm / step],
    [Loss Computation], [Scalar ($cal(L)_"CL-SCR"$)],
  ),
  caption: [Chi tiết kiến trúc và luồng dữ liệu của mô-đun CL-SCR. Các ký hiệu $"ReLU"^x_1$ biểu thị lớp kích hoạt đầu tiên trong mỗi khối VGG.]
) <tab:cl_scr_arch>

#pagebreak()

== Các siêu tham số Tiền huấn luyện CL-SCR <pl-hyperparam-clscrclscr>
@tab:hyperparams-clscrclscr dưới đây tóm tắt các thiết lập thực nghiệm chính xác được sử dụng cho giai đoạn tiền huấn luyện mô-đun CL-SCR.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: (col, row) => left + horizon,
    stroke: 0.5pt,
    table.header(
      [*Giai đoạn*], [*Tham số*], [*Giá trị*]
    ),
    table.hline(),

    // Giai đoạn Tiền huấn luyện SCR
    table.cell(rowspan: 9, align: horizon)[*Tiền huấn luyện SCR* \ (Pre-training)],
    [Kích thước Batch \ (Batch Size)], [$16$],
    [Tổng số bước lặp \ (Max Steps)], [$200,000$],
    [Tốc độ học \ (Learning Rate)], [$1 times 10^(-4)$],
    [Nhiệt độ InfoNCE \ ($tau$)], [$0.07$],
    [Bộ tối ưu hoá \ (Optimizer)], [Adam],
    [Kích thước ảnh \ (Resolution)], [$64 times 64$],
    [Augmentation], [RandomResizedCrop \ (scale 0.8-1.0)],
    [Chế độ Loss], [`both` \ ($alpha=0.3, beta=0.7$)],
    [Các lớp trích xuất \ (NCE Layers)], [`0,1,2,3,4,5`],
  ),
  caption: [Bảng tổng hợp các siêu tham số cho giai đoạn tiền huấn luyện CL-SCR.]
) <tab:hyperparams-clscrclscr>

#pagebreak()

== Các siêu tham số huấn luyện <pl-hyperparam>
@tab:hyperparams dưới đây tóm tắt các thiết lập thực nghiệm chính xác được sử dụng trong mã nguồn huấn luyện (`train.py` và các script `.sh`).

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: (col, row) => left + horizon,
    stroke: 0.5pt,
    table.header(
      [*Giai đoạn*], [*Tham số*], [*Giá trị*]
    ),
    table.hline(),
    
    // Giai đoạn 1
    table.cell(rowspan: 8, align: horizon)[*Giai đoạn 1*: \ *Tái tạo cấu trúc*],
    [Độ phân giải ảnh \ (Resolution)], [$64 times 64$],
    [Kích thước Batch \ (Batch Size)], [$4$],
    [Tổng số bước lặp \ (Max Steps)], [$400,000$],
    [Tốc độ học \ (Learning Rate)], [$1 times 10^(-4)$ \ (Linear Decay)],
    [Số bước khởi động \ (Warmup)], [$10,000$],
    [Trọng số Loss \ ($lambda_"percep"$, $lambda_"offset"$)], [$0.01$, $0.5$],
    [Bộ tối ưu hoá \ (Optimizer)], [AdamW \ ($beta_1=0.9, beta_2=0.999$)],
    [Phần cứng], [1 $times$ NVIDIA Tesla P100],

    // Giai đoạn 2
    table.cell(rowspan: 8, align: horizon)[*Giai đoạn 2*: \ *Tinh chỉnh phong cách* \ (w/ CL-SCR)],
    [Kích thước Batch \ (Batch Size)], [$4$],
    [Tổng số bước lặp \ (Max Steps)], [$30,000$],
    [Tốc độ học \ (Learning Rate)], [$1 times 10^(-5)$ (Constant)],
    [Số bước khởi động \ (Warmup)], [$1,000$],
    [Số lượng mẫu âm \ ($K$)], [$4$],
    [Chế độ SCR \ (`scr_mode`)], [`both` (Intra + Cross)],
    [Trọng số Loss CL-SCR \ ($lambda_"sc"$)], [$0.01$],
    [Augmentation \ (SCR Input)], [RandomResizedCrop (scale 0.8-1.0)],
  ),
  caption: [Bảng tổng hợp các siêu tham số huấn luyện cho cả hai giai đoạn.]
) <tab:hyperparams>

#pagebreak()

== Các tham số quá trình suy luận <pl-inference>
@tab:inference_params dưới đây liệt kê chi tiết các thiết lập được sử dụng trong mã nguồn thực nghiệm (`new_inference.py` và `sample.py`) để đánh giá mô hình.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: (col, row) => left + horizon,
    stroke: 0.5pt,
    table.header(
      [*Phân loại*], [*Tham số*], [*Giá trị thiết lập*]
    ),
    table.hline(),

    // Nhóm 1: Cấu hình lấy mẫu
    table.cell(rowspan: 7, align: horizon)[*Cấu hình Lấy mẫu* \ (Sampling Config)],
    [Thuật toán \ (Algorithm Type)], [`dpmsolver++`],
    [Loại dự đoán \ (Model Prediction)], [`noise` (dự đoán nhiễu $epsilon$)],
    [Số bước suy luận \ (Inference Steps)], [$20$ steps],
    [Bậc bộ giải \ (Solver Order)], [$2$],
    [Chế độ hướng dẫn \ (Guidance Type)], [`classifier-free`],
    [Trọng số hướng dẫn \ (Guidance Scale)], [$7.5$],
    [Độ phân giải ảnh \ (Resolution)], [$64 times 64$],

    // Nhóm 2: Kịch bản thực nghiệm
    // table.cell(rowspan: 5, align: horizon)[*Kịch bản Thực nghiệm* \ (Experimental Setup)],
    // [Hướng chuyển đổi \ (Direction)], [`e2c` (Latin $arrow.r$ Hán) \ `c2e` (Hán $arrow.r$ Latin)],
    // [Chế độ kiểm thử \ (Phase)], [`test_unknown_style` \ (Unseen Fonts)],
    // [Độ phức tạp nét \ (Complexity - c2e)], [`easy`, `medium`, `hard`, `all`],
    // [Chọn mẫu phong cách \ (Style Selection)], [Random (`A-Z`) hoặc Fixed (`A+`)],
    // [Thiết bị tính toán \ (Device)], [NVIDIA Tesla P100 (cuda:0)],
  ),
  caption: [Bảng các tham số cấu hình cho quá trình suy luận (Inference).]
) <tab:inference_params>

#pagebreak()

== Chi phí Tính toán và Thời gian <phuluc_thoigian>

Do đặc thù của kiến trúc khuếch tán (Diffusion Models), phương pháp đề xuất có sự khác biệt rõ rệt về tài nguyên tiêu thụ so với các phương pháp GAN hay CNN truyền thống. Phần này bóc tách chi tiết thời gian huấn luyện và suy diễn.

=== Thời gian Huấn luyện

Việc huấn luyện mô hình đề xuất (Ours) là một quy trình đa giai đoạn, đòi hỏi tài nguyên tính toán đáng kể để đảm bảo sự hội tụ của cả cấu trúc và phong cách.

a) *Chi tiết các giai đoạn huấn luyện của phương pháp đề xuất (Ours Breakdown)*:

@tab:ours_training_breakdown dưới đây liệt kê thời gian tiêu tốn cho từng thành phần riêng biệt khi huấn luyện trên cấu hình phần cứng tham chiếu (01 GPU NVIDIA Tesla P100).

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Thành phần*], [*Mô tả*], [*Số bước lặp*], [*Batch Size*], [*Thời gian ước tính*]
    ),
    table.hline(),
    
    [Pre-train SCR], [Huấn luyện bộ trích xuất phong cách CL-SCR], [$200,000$], [16], [$approx$ 80 giờ],
    
    [Phase 1], [Giai đoạn Tái tạo \ (Reconstruction)], [$400,000$], [4], [$approx$ 24 giờ],
    
    [Phase 2], [Giai đoạn Tinh chỉnh \ (Refinement)], [$30,000$], [4], [$approx$ 12 giờ],
    
    table.hline(stroke: 1pt),
    table.cell(colspan: 4, align: right)[*Tổng thời gian huấn luyện toàn bộ Pipeline*],
    [*$approx$ 5 ngày*],
  ),
  caption: [Thời gian huấn luyện cho từng giai đoạn của phương pháp đề xuất (Ours).]
) <tab:ours_training_breakdown>

#pagebreak()
#h(1.5em) b) *So sánh tổng thời gian huấn luyện với các Baseline*:

So với các phương pháp hiện có, FontDiffuser yêu cầu thời gian huấn luyện dài hơn do bản chất hội tụ chậm của quá trình khử nhiễu và yêu cầu số bước lặp lớn.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Mô hình*], [*Cơ chế lõi*], [*Tổng thời gian Huấn luyện* \ (Ước tính trên GPU đơn)]
    ),
    table.hline(),
    
    [DG-Font @Xie2021DGFont], [Unsupervised GAN \ (Deformable)], [Trung bình \ ($approx$ 1 - 2 ngày)],
    
    [CF-Font @Wang2023CFFont], [GAN \ (Content Fusion)], [Trung bình \ ($approx$ 1 - 2 ngày)],

    [DFS @Zhu2020FewShotTextStyle], [cGAN \ (Feature Matching)], [Trung bình \ ($approx$ 20 - 24 giờ)],
    
    [FTransGAN @Li2021FTransGAN], [GAN \ (Multi-level Attention)], [Trung bình \ ($approx$ 20 - 24 giờ)],
    
    [*Ours (FontDiffuser)*], [*Diffusion \ (Denoising)*], [*Lâu* \ ($approx$ 5 ngày)],
  ),
  caption: [So sánh tổng thời gian huấn luyện giữa phương pháp đề xuất và các Baseline.]
) <tab:training_comparison>

#pagebreak()
=== Tốc độ Suy diễn

Trong giai đoạn triển khai (Inference), tốc độ sinh ảnh là yếu tố quan trọng đối với trải nghiệm người dùng.

Bảng dưới đây so sánh thời gian trung bình để sinh ra *một ký tự ảnh* (kích thước $64 times 64$). Phương pháp đề xuất sử dụng bộ giải *DPM-Solver++* với 20 bước lấy mẫu.

#figure(
  numbering: phuluc_numbering,
  table(
    columns: (auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Mô hình*], [*Cơ chế sinh*], [*Số bước \ chuyển tiếp* \ (Forward Passes)], [*Thời gian \ / 1 ảnh*]
    ),
    table.hline(),
    
    [DG-Font @Xie2021DGFont], [Feed-forward (One-step)], [1], [Rất nhanh \ ($< 0.05$s)],
    
    [CF-Font @Wang2023CFFont], [Feed-forward (One-step)], [1], [Rất nhanh \ ($< 0.05$s)],

    [DFS @Zhu2020FewShotTextStyle], [Feed-forward (One-step)], [1], [Rất nhanh \ ($< 0.05$s)],
    
    [FTransGAN @Li2021FTransGAN], [Feed-forward (One-step)], [1], [Nhanh \ ($approx 0.1$s)],

    [*Ours (FontDiffuser)*], [*Iterative Denoising*], [*20*], [*Chậm* \ ($approx$ 2.0 - 3.0s)],
  ),
  
  caption: [So sánh tốc độ suy diễn.]
) <tab:inference_comparison>