#import "/template.typ": *

#[
  #set heading(numbering: none, supplement: [Phụ lục])
  = Phụ lục <phuluc>
]

#set heading(numbering: (..nums) => {
  nums = nums.pos()
  numbering("A.1.", ..nums.slice(1))
}, supplement: [Phụ lục])

#counter(heading).update(1)

== Các siêu tham số huấn luyện (Training Hyperparameters) <pl-hyperparam>
Bảng dưới đây tóm tắt các thiết lập thực nghiệm chính xác được sử dụng trong mã nguồn huấn luyện (`train.py` và các script `.sh`).

#figure(
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
    table.cell(rowspan: 7, align: horizon)[*Giai đoạn 1: \ Tái tạo cấu trúc*],
    [Độ phân giải ảnh \ (Resolution)], [$64 times 64$],
    [Kích thước Batch \ (Batch Size)], [*4*],
    [Tổng số bước lặp \ (Max Steps)], [$400,000$],
    [Tốc độ học \ (Learning Rate)], [$1 times 10^(-4)$ \ (Linear Decay)],
    [Trọng số Loss \ ($lambda_"percep"$, $lambda_"offset"$)], [$0.01$, $0.5$],
    [Bộ tối ưu hoá \ (Optimizer)], [AdamW \ ($beta_1=0.9, beta_2=0.999$)],
    [Phần cứng], [1 $times$ NVIDIA Tesla P100],

    // Giai đoạn 2
    table.cell(rowspan: 8, align: horizon)[*Giai đoạn 2: \ Tinh chỉnh phong cách* \ (w/ CL-SCR)],
    [Kích thước Batch (Batch Size)], [*4*],
    [Tổng số bước lặp (Max Steps)], [$30,000$],
    [Tốc độ học (Learning Rate)], [$1 times 10^(-5)$ (Constant)],
    [Số bước khởi động (Warmup)], [$1,000$],
    [Số lượng mẫu âm ($K$)], [*4*],
    [Chế độ SCR (`scr_mode`)], [`both` (Intra + Cross)],
    [Trọng số Loss CL-SCR ($lambda_"sc"$)], [$0.01$],
    [Augmentation (SCR Input)], [RandomResizedCrop (scale 0.8-1.0)],
  ),
  caption: [Bảng tổng hợp các siêu tham số huấn luyện cho cả hai giai đoạn.]
) <tab:hyperparams>

#pagebreak()

== Kiến trúc mô-đun CL-SCR <pl-clscr>

Mô-đun CL-SCR được thiết kế dựa trên mạng VGG-19 pre-trained để trích xuất đặc trưng phong cách đa tầng, kết hợp với các lớp chiếu (Projector) để đưa về không gian vector phục vụ học tương phản.

#figure(
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

== Chi tiết Kiến trúc mạng UNet <pl-unet>

Mạng UNet đóng vai trò là bộ xương sống (backbone) trong mô hình khuếch tán, chịu trách nhiệm dự đoán nhiễu tại từng bước thời gian. Cấu trúc chi tiết của mạng được trình bày tại @tab:unet_arch, bao gồm các khối mã hóa (Encoder), giải mã (Decoder) và các mô-đun tích hợp đặc trưng như MCA và SI.

#figure(
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

== Phân tích Chi phí Tính toán và Thời gian <phuluc_thoigian>

Do đặc thù của kiến trúc khuếch tán (Diffusion Models), phương pháp đề xuất có sự khác biệt rõ rệt về tài nguyên tiêu thụ so với các phương pháp GAN hay CNN truyền thống. Phần này bóc tách chi tiết thời gian huấn luyện và suy diễn.

=== Thời gian Huấn luyện (Training Time)

Việc huấn luyện mô hình đề xuất (Ours) là một quy trình đa giai đoạn, đòi hỏi tài nguyên tính toán đáng kể để đảm bảo sự hội tụ của cả cấu trúc và phong cách.

*a) Chi tiết các giai đoạn huấn luyện của phương pháp đề xuất (Ours Breakdown)*
Bảng dưới đây liệt kê thời gian tiêu tốn cho từng thành phần riêng biệt khi huấn luyện trên cấu hình phần cứng tham chiếu (01 GPU NVIDIA Tesla P100).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Thành phần*], [*Mô tả*], [*Số bước lặp*], [*Batch Size*], [*Thời gian ước tính*]
    ),
    table.hline(),
    
    [Pre-train SCR], [Huấn luyện bộ trích xuất phong cách CL-SCR], [$200,000$], [16], [$approx$ 24 - 30 giờ],
    
    [Phase 1], [Giai đoạn Tái tạo (Reconstruction)], [$400,000$], [16], [$approx$ 72 - 80 giờ],
    
    [Phase 2], [Giai đoạn Tinh chỉnh (Refinement)], [$30,000$], [16], [$approx$ 5 - 8 giờ],
    
    table.hline(stroke: 1pt),
    table.cell(colspan: 4, align: right)[*Tổng thời gian huấn luyện toàn bộ Pipeline:*],
    [*$approx$ 5 - 6 ngày*],
  ),
  caption: [Bóc tách thời gian huấn luyện cho từng giai đoạn của phương pháp đề xuất (Ours).]
) <tab:ours_training_breakdown>

*b) So sánh tổng thời gian huấn luyện với các Baseline*
So với các phương pháp hiện có, FontDiffuser yêu cầu thời gian huấn luyện dài hơn do bản chất hội tụ chậm của quá trình khử nhiễu và yêu cầu số bước lặp lớn.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Mô hình*], [*Cơ chế lõi*], [*Tổng thời gian Huấn luyện* \ (Ước tính trên GPU đơn)]
    ),
    table.hline(),
    
    [DFS @Zhu2020FewShotTextStyle], [CNN (Encoder-Decoder)], [Rất nhanh \ ($approx$ 12 - 24 giờ)],
    
    [FTransGAN @Li2021FTransGAN], [GAN (Cycle-consistent)], [Trung bình \ ($approx$ 1 - 2 ngày)],
    
    [DG-Font @Xie2021DGFont], [GAN (Deformable)], [Trung bình \ ($approx$ 2 - 3 ngày)],
    
    [CF-Font @Wang2023CFFont], [GAN (Few-shot)], [Trung bình \ ($approx$ 2 - 3 ngày)],
    
    [*Ours (FontDiffuser)*], [*Diffusion (Denoising)*], [*Lâu* \ ($approx$ 5 - 6 ngày)],
  ),
  caption: [So sánh tổng thời gian huấn luyện giữa phương pháp đề xuất và các Baseline.]
) <tab:training_comparison>

=== Tốc độ Suy diễn (Inference Speed)

Trong giai đoạn triển khai (Inference), tốc độ sinh ảnh là yếu tố quan trọng đối với trải nghiệm người dùng.

Bảng dưới đây so sánh thời gian trung bình để sinh ra *một ký tự ảnh* (kích thước $64 times 64$). Phương pháp đề xuất sử dụng bộ giải *DPM-Solver++* với 20 bước lấy mẫu.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 10pt,
    align: horizon,
    stroke: 0.5pt,
    table.header(
      [*Mô hình*], [*Cơ chế sinh*], [*Số bước chuyển tiếp* \ (Forward Passes)], [*Thời gian / 1 ảnh*]
    ),
    table.hline(),
    
    [DFS @Zhu2020FewShotTextStyle], [Feed-forward], [1], [Rất nhanh \ ($< 0.05$s)],
    
    [DG-Font @Xie2021DGFont], [Generator (GAN)], [1], [Nhanh \ ($approx$ 0.15s)],
    
    [CF-Font @Wang2023CFFont], [Generator (GAN)], [1], [Trung bình \ ($approx$ 0.20s)],
    
    [*Ours (FontDiffuser)*], [*Iterative Denoising*], [*20*], [*Chậm* \ ($approx$ 2.0 - 3.0s)],
  ),
  caption: [So sánh tốc độ suy diễn. Các mô hình GAN chỉ cần 1 bước chuyển tiếp để tạo ảnh, trong khi Diffusion cần thực hiện lặp lại quá trình khử nhiễu nhiều lần (20 steps).]
) <tab:inference_comparison>

*Nhận xét:*
Sự đánh đổi giữa tốc độ và chất lượng là đặc điểm cố hữu của mô hình Diffusion. Mặc dù tốc độ suy diễn chậm hơn khoảng $10 times 20$ lần so với GAN, nhưng phương pháp đề xuất loại bỏ được các hiện tượng giả (artifacts) và mờ nhòe, mang lại chất lượng bản in thương mại cao hơn. Trong tương lai, các kỹ thuật như *Knowledge Distillation* hoặc *Consistency Models* có thể được áp dụng để giảm số bước lấy mẫu xuống còn 2-4 bước, giúp thu hẹp khoảng cách về tốc độ này.

*Nhận xét:*
Mặc dù phương pháp đề xuất (Ours) yêu cầu tài nguyên huấn luyện lớn hơn và tốc độ suy diễn chậm hơn so với các phương pháp GAN truyền thống, sự đánh đổi này mang lại chất lượng sinh ảnh vượt trội (như đã chứng minh qua chỉ số FID và User Study). Đây là đặc điểm cố hữu của các mô hình khuếch tán: ưu tiên chất lượng (Quality) và độ đa dạng (Diversity) hơn là tốc độ (Speed).