#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Thực nghiệm và Đánh giá kết quả <chuong4>
]

#let glyph-grid(chars, base, font, suffix) = grid(
  columns: (45pt,) * chars.len(),
  inset: 1pt,
  ..chars.map(char =>
    box(
      width: 50pt,
      height: 30pt,
      // align: center,
      image(
        base + font + "_" + char + "_" + suffix + ".png",
        width: 40pt,
        height: 40pt,
        fit: "contain"
      )
    )
  )
)

#let glyph-grid2(chars, base, font) = grid(
  columns: (45pt,) * chars.len(),
  inset: 1pt,
  ..chars.map(char =>
    box(
      width: 50pt,
      height: 50pt,
      // align: center,
      image(
        base + font + "_" + char + ".png",
        width: 40pt,
        height: 40pt,
        fit: "contain"
      )
    )
  )
)

#let s1 = "默首音".clusters()
#let s2 = "tdk".clusters()

Chương này trình bày chi tiết *thiết lập thực nghiệm*, bao gồm mô tả bộ dữ liệu, các thước đo đánh giá và cấu hình huấn luyện chi tiết trên nền tảng phần cứng giới hạn. Tiếp theo, khoá luận sẽ đưa ra các *so sánh định lượng và định tính* giữa *phương pháp đề xuất (CL-SCR FontDiffuser)* với các *phương pháp tiên tiến hiện nay (State-of-the-Art)* nhằm chứng minh hiệu quả trong bài toán sinh phông chữ đa ngôn ngữ (Cross-Lingual Font Generation) theo cả hai chiều: *từ Hán tự sang Latin* và *từ Latin sang Hán tự*.

== Bộ dữ liệu (Datasets)

=== Cấu trúc
Để đảm bảo tính khách quan và khả năng so sánh công bằng với các nghiên cứu tiên tiến, khoá luận không tự xây dựng dữ liệu mới mà kế thừa *bộ dữ liệu chuẩn* từ công trình "Few-shot Font Style Transfer between Different Languages"@Li2021FTransGAN. Đây là tập dữ liệu chuyên biệt cho bài toán đa ngôn ngữ, bao gồm *818 bộ phông chữ song ngữ* với độ đa dạng phong cách cao, trải dài từ serif, sans-serif đến thư pháp và viết tay. Cấu trúc dữ liệu được tổ chức thành hai tập con tương tác chặt chẽ nhằm phục vụ bài toán chuyển đổi hai chiều: *tập ký tự Hán* chứa trung bình *800 ký tự* thông dụng (chuẩn GB2312) đóng vai trò miền đích phức tạp, và *tập ký tự Latin* bao gồm *52 ký tự* cơ bản. Đặc điểm cốt lõi của bộ dữ liệu này là sự *nhất quán tuyệt đối về phong cách* giữa hai hệ chữ trong cùng một bộ font, *cung cấp các cặp dữ liệu nhãn (Ground-truth)* tự nhiên giúp mô-đun CL-SCR học được sự tương quan phong cách xuyên ngôn ngữ.

#let image-row(folder, size: auto) = (
  image(folder + "/" + "A.png", width: size),
  image(folder + "/" + "B.png", width: size),
  image(folder + "/" + "C.png", width: size),
  image(folder + "/" + "D.png", width: size),
  image(folder + "/" + "E.png", width: size),
  image(folder + "/" + "一.png", width: size),
  image(folder + "/" + "七.png", width: size),
  image(folder + "/" + "万.png", width: size),
  image(folder + "/" + "丈.png", width: size),
  image(folder + "/" + "三.png", width: size),
)

#figure(
  grid(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    gutter: 4pt,
    inset: 6pt,
    stroke: none,
    align: center,

    ..image-row("../images/dataset_example/font1"),
    ..image-row("../images/dataset_example/font2"),
    ..image-row("../images/dataset_example/font3"),
    ..image-row("../images/dataset_example/font4"),
    ..image-row("../images/dataset_example/font5"),
    ..image-row("../images/dataset_example/font6"),
    ..image-row("../images/dataset_example/font7"),
    ..image-row("../images/dataset_example/font8"),
    ..image-row("../images/dataset_example/font9"),
    ..image-row("../images/dataset_example/font10"),
  ),

  caption: [Minh hoạ hai hệ chữ trong cùng một bộ font.]
)

=== Tiền xử lý và Chuẩn hoá
_*Quy trình tiền xử lý*_:
Về quy trình tiền xử lý, dữ liệu thô trải qua các bước chuẩn hoá để tối ưu hoá quá trình huấn luyện. Cụ thể, toàn bộ ảnh ký tự được render dưới dạng *thang độ xám (grayscale)* nhằm loại bỏ nhiễu màu sắc, giúp mô hình tập trung tối đa vào việc học các đặc trưng hình học và cấu trúc nét. Các ảnh đầu vào sau đó được chuẩn hoá đồng bộ về kích thước *$64 times 64$ pixel*, đồng thời áp dụng kỹ thuật *căn chỉnh tự động (auto-centering)* để đưa ký tự về tâm ảnh với tỷ lệ lề phù hợp. Cuối cùng, một bước *lọc bỏ thủ công* được thực hiện để loại trừ các mẫu lỗi như ký tự bị đứt nét hoặc render thiếu, đảm bảo chất lượng đầu vào tốt nhất cho mô hình.

_*Quy trình Chuẩn hoá và Lấy mẫu Động*_:
Tiếp nối các bước xử lý thô, để đảm bảo tính tương thích tối đa với kiến trúc mạng nơ-ron tích chập và cơ chế khuếch tán, khoá luận thiết lập một *đường ống xử lý dữ liệu* chuyên biệt được triển khai thời gian thực trong quá trình huấn luyện. Cụ thể, thông qua lớp `FontDataset`, mọi ảnh đầu vào (bao gồm ảnh nội dung, ảnh phong cách và các mẫu âm) đều được chuyển đổi đồng bộ sang không gian màu *RGB (3 kênh)* để khớp với đầu vào tiêu chuẩn của bộ mã hoá U-Net. Kế đến, kỹ thuật *nội suy song tuyến tính (Bilinear Interpolation)* được áp dụng để đưa ảnh về độ phân giải mục tiêu, giúp làm mượt các đường biên răng cưa và bảo toàn thông tin cấu trúc tốt hơn so với các phương pháp lấy mẫu lân cận. Về mặt số học, dữ liệu trải qua bước *chuẩn hoá giá trị (Value Normalization)*, chuyển đổi các điểm ảnh từ dải $[0,255]$ sang dạng Tensor với dải giá trị tiêu chuẩn $[-1, 1]$, tạo điều kiện hội tụ ổn định cho quá trình khử nhiễu Gaussian. Đặc biệt, để phục vụ mô-đun CL-SCR, khoá luận áp dụng chiến lược *Lấy mẫu âm động (Dynamic Negative Sampling)*: thay vì cố định các cặp mẫu, hệ thống tự động truy xuất và lựa chọn ngẫu nhiên $K$ mẫu âm từ kho dữ liệu dựa trên chế độ huấn luyện (nội miền `intra` hoặc xuyên miền `cross`) ngay tại mỗi bước lặp, giúp mô hình liên tục được tiếp xúc với các biến thể phong cách đa dạng và tránh hiện tượng học vẹt.

== Thiết lập Thực nghiệm

=== Cấu hình Huấn luyện (Implementation Details)
Các thí nghiệm được thực hiện trên môi trường tính toán đám mây Kaggle với *GPU NVIDIA Tesla P100 (16GB VRAM)*. Mã nguồn được triển khai trên nền tảng *PyTorch* và *thư viện Diffusers*.

Quá trình huấn luyện tuân theo chiến lược *hai giai đoạn (Two-stage training)* với các siêu tham số được thiết lập cụ thể như sau dựa trên tài nguyên phần cứng giới hạn:

1. *_Giai đoạn Tái tạo (Phase 1 - Reconstruction)_*:
Trong giai đoạn khởi đầu này, mục tiêu chính của mô hình là học các đặc trưng cấu trúc nội dung và phong cách cơ bản. Quá trình huấn luyện được thực hiện xuyên suốt *400,000 bước lặp* với kích thước batch được cố định là *4*. Về chiến lược tối ưu hoá, khoá luận sử dụng bộ giải thuật *AdamW* với tốc độ học khởi tạo là *$1 times 10^(-4)$*, kết hợp cùng lịch trình điều chỉnh Linear bao gồm *10,000 bước khởi động* (warmup steps) để đảm bảo mô hình hội tụ ổn định. Hàm mất mát tổng hợp được cấu hình với các trọng số thành phần cụ thể là *$lambda_"percep" = 0.01$* cho Content Perceptual Loss và *$lambda_"offset" = 0.5$* cho Offset Loss nhằm hỗ trợ mô-đun RSI học biến dạng cấu trúc.

2. *_Tiền huấn luyện mô-đun CL-SCR_*:
Trước khi được tích hợp vào luồng sinh ảnh chính, mô-đun CL-SCR (Cross-Lingual Style Contrastive Refinement) trải qua một quá trình huấn luyện độc lập nhằm xây dựng không gian biểu diễn phong cách tối ưu. Quá trình này được thực hiện trong tổng số *200,000 bước lặp* với kích thước batch là *16*. Khoá luận sử dụng bộ tối ưu hoá Adam để cập nhật tham số cho cả bộ trích xuất đặc trưng (Style Feat Extractor) và bộ chiếu đặc trưng (Style Projector) với tốc độ học cố định là *$1 times 10^(-4)$*.

Để tăng cường tính bền vững của biểu diễn phong cách đối với các biến thể hình học, khoá luận áp dụng chiến lược tăng cường dữ liệu (Data Augmentation) thông qua kỹ thuật *Random Resized Crop*. Cụ thể, ảnh đầu vào được *cắt ngẫu nhiên với tỷ lệ diện tích từ 80% đến 100% (scale 0.8 - 1.0)* và *tỷ lệ khung hình dao động nhẹ trong khoảng 0.8 đến 1.2*, sau đó được đưa về kích thước chuẩn thông qua nội suy song tuyến tính (bilinear interpolation).

3. *_Giai đoạn Tinh chỉnh Phong cách bằng mô-đun CL-SCR (Phase 2 - Style Refinement with CL-SCR)_*:
Bước sang giai đoạn hai, mô-đun CL-SCR được kích hoạt để tinh chỉnh sâu các đặc trưng phong cách Latin, trong khi tốc độ học của các thành phần khác được giảm xuống để tránh phá vỡ cấu trúc đã học. Quá trình này diễn ra trong *30,000 bước* với *kích thước batch 4* nhằm dành tài nguyên VRAM cho các tính toán của mô-đun tương phản. Tốc độ học được thiết lập ở mức thấp hơn là *$1 times 10^(-5)$*, áp dụng chiến lược Constant (hằng số) sau *1,000 bước khởi động*. Đối với cấu hình CL-SCR, khoá luận lựa chọn chế độ huấn luyện kết hợp cả nội miền và xuyên miền (`scr_mode="both"`) với tỷ trọng $alpha_"intra" = 0.3$ và ưu tiên *$beta_"cross" = 0.7$*, đồng thời sử dụng *4 mẫu âm* (negative samples) cho mỗi lần tính toán loss. Hàm mục tiêu tổng thể lúc này là sự kết hợp của các thành phần theo công thức:

#numbered_equation[
  $ L_"total" = L_"MSE" + 0.01 dot L_"percep" + 0.5 dot L_"offset" + 0.01 dot L_"CL-SCR" $
]

4. *_Quy trình Inference_*: 
Trong quá trình lấy mẫu (Inference), mô hình FontDiffuser@Yang2024FontDiffuser được đóng gói thành một Pipeline dựa trên DPM-Solver để tối ưu hoá tốc độ.

_*Cấu hình Lấy mẫu*_: Khoá luận sử dụng bộ giải *DPM-Solver++* với số bước suy diễn được cố định là *20* (`num_inference_steps=20`), đây là một sự cân bằng giữa tốc độ tính toán và chất lượng ảnh sinh. Chiến lược hướng dẫn vô điều kiện (Classifier-Free Guidance@JonathanGuidance) được áp dụng với tham số hướng dẫn ($s$) được xác định trong file cấu hình (`guidance_scale`). Để lấy mẫu, các ảnh đầu vào được tiền xử lý và chuẩn hoá về kích thước (`content_image_size`, `style_image_size`) rồi đưa về Tensor với dải giá trị $[ -1, 1 ]$.

_*Lấy mẫu Hàng loạt (Batch Sampling)*_: Do khoá luận thực hiện đánh giá định lượng trên một lượng lớn mẫu, quy trình lấy mẫu được tự động hoá thông qua hàm batch_sampling, bao phủ cả hai hướng nghiên cứu.

=== Kịch bản Đánh giá (Evaluation Scenarios)
Để đánh giá toàn diện khả năng của mô hình, khoá luận thiết lập *_hai_ kịch bản kiểm thử* với *độ khó _tăng dần_* (theo chuẩn của FontDiffuser@Yang2024FontDiffuser và DG-Font@Xie2021DGFont):

#tab_eq[
  _*SFUC (Seen Font, Unseen Character)*_: Font đã xuất hiện trong tập huấn luyện, nhưng ký tự sinh ra chưa từng thấy. Kịch bản này đánh giá khả năng *nội suy phong cách*.

  _*UFSC (Unseen Font, Seen Character)*_: Font mới hoàn toàn (chưa từng xuất hiện trong quá trình huấn luyện). Đây là kịch bản quan trọng nhất để đánh giá khả năng *One-shot Generalization* của mô hình đối với phong cách lạ.
]

== Các thước đo đánh giá (Evaluation Metrics)
Để đảm bảo *tính khách quan* và *toàn diện* trong việc kiểm định chất lượng mô hình, khoá luận áp dụng hệ thống đánh giá đa chiều bao gồm cả các *chỉ số định lượng tiêu chuẩn (Quantitative Metrics)* và *đánh giá định tính dựa trên cảm nhận người dùng (Subjective User Study)*.

=== Chỉ số Định lượng (Quantitative Metrics)
Khoá luận sử dụng bộ 4 chỉ số tiêu chuẩn trong bài toán sinh ảnh để đánh giá chất lượng ảnh sinh ($x$) so với ảnh thật ($y$):

==== L1 (Mean Absolute Error)
Độ đo *L1* tính trung bình giá trị tuyệt đối của sai khác giữa các điểm ảnh (pixel-wise), phản ánh độ chính xác về cường độ điểm ảnh:

#numbered_equation[
  $ "L1" = 1/N sum_(i=1)^N |x_i - y_i| $
]

Trong đó:
#tab_eq[
  *$N$*: Tổng số lượng điểm ảnh (pixels) trong hình ảnh.
  
  *$x_i$*: Giá trị cường độ điểm ảnh tại vị trí $i$ của ảnh sinh ra.
  
  *$y_i$*: Giá trị cường độ điểm ảnh tại vị trí $i$ của ảnh mẫu (Ground Truth).

  *$| dot |$*: Phép tính giá trị tuyệt đối.
]

#untab_para[
  *_Ý nghĩa_*: *Giá trị L1 càng nhỏ* thể hiện *sai số tái tạo càng thấp*, tức *ảnh sinh càng sát với ảnh gốc về mặt tín hiệu*. Tuy nhiên, L1 thường *không phản ánh tốt cảm nhận thị giác của mắt người* (ví dụ: ảnh mờ vẫn có thể có L1 thấp).
]

==== SSIM (Structural Similarity Index)
Độ đo *SSIM@Wang2004SSIM* đánh giá mức độ tương đồng về *cấu trúc, độ sáng và độ tương phản*. Khác với L1, SSIM mô phỏng cách mắt người cảm nhận sự thay đổi cấu trúc cục bộ:

#numbered_equation[
  $ "SSIM"(x, y) = ((2 mu_x mu_y + C_1)(2 sigma_(x y) + C_2))/((mu_x^2 + mu_y^2 + C_1)(sigma_x^2 + sigma_y^2 + C_2)) $
]

Trong đó:
#tab_eq[
  *$mu_x, mu_y$*: Giá trị trung bình cục bộ của ảnh $x$ và ảnh $y$ (đại diện cho *độ sáng*).
  
  *$sigma_x^2, sigma_y^2$*: Phương sai cục bộ của ảnh $x$ và ảnh $y$ (đại diện cho *độ tương phản*).
  
  *$sigma_(x y)$*: Hiệp phương sai giữa $x$ và $y$ (đại diện cho *sự tương đồng cấu trúc*).

  *$C_1, C_2$*: Các hằng số nhỏ để đảm bảo tính ổn định khi mẫu số tiến tới 0 (thường được tính theo $C_1 = (k_1 L)^2$, $C_2 = (k_2 L)^2$ với $L$ là dải giá trị động của pixel).
]

#untab_para[
  *_Ý nghĩa_*: Giá trị SSIM nằm trong khoảng $[0,1]$, *giá trị càng cao* thể hiện *chất lượng ảnh càng tốt*.
]

==== LPIPS (Learned Perceptual Image Patch Similarity)
Độ đo *LPIPS@Zhang2018LPIPS* đánh giá *khoảng cách cảm nhận* dựa trên các đặc trưng trích xuất từ mạng nơ-ron sâu (thường là VGG@SimonyanZ14aVGG hoặc AlexNet@KrizhevskySH12AlexNet). Chỉ số này khắc phục nhược điểm của L1/SSIM khi xử lý các ảnh bị mờ nhẹ nhưng vẫn giống về ngữ nghĩa:

#numbered_equation[
  $ "LPIPS"(x,y) = sum_l 1 / (H_l W_l) sum_(h, w) ||w_l dot (f_l^x (h, w) - f_l^y (h, w))||_2^2 $
]

Trong đó:
#tab_eq[
  *$f_l^x, f_l^y$*: Bản đồ đặc trưng (feature map) tại lớp thứ $l$ của mạng nơ-ron trích xuất từ ảnh $x$ và $y$.
  
  *$H_l, W_l$*: Chiều cao và chiều rộng của bản đồ đặc trưng tại lớp $l$.

  *$w_l$*: Vector trọng số dùng để chuẩn hoá kênh (channel scaling factors).

  *$dot$*: Phép nhân từng phần tử (element-wise product).

  *$|| . ||_2^2$*: Bình phương khoảng cách Euclid.
]

#untab_para[
  *_Ý nghĩa_*: LPIPS khắc phục nhược điểm của L1/SSIM khi xử lý các ảnh bị mờ nhẹ nhưng vẫn đúng về ngữ nghĩa. *Giá trị LPIPS càng thấp* chứng tỏ *ảnh sinh càng giống ảnh thật về mặt thị giác tự nhiên theo cảm nhận của mắt người*.
]

==== FID (Fréchet Inception Distance)
Độ đo *FID@Heusel2017FID* đánh giá chất lượng tổng thể và độ đa dạng của tập ảnh sinh dựa trên khoảng cách thống kê giữa hai phân bố đặc trưng (thường được trích xuất từ lớp *Pool3* của mạng InceptionV3):

#numbered_equation[
  $ "FID"(r, g) = ||mu_r - mu_g||_2^2 + "Tr"(sum_r + sum_g - 2(sum_r sum_g)^(1/2) ) $
]

Trong đó:
#tab_eq[
  *$mu_r, mu_g$*: Vector trung bình đặc trưng (mean feature vector) của tập ảnh thật ($r$) và tập ảnh sinh ($g$).

  *$sum_r, sum_g$*: Ma trận hiệp phương sai (covariance matrix) của tập ảnh thật và tập ảnh sinh.

  *$|| dot ||_2^2$*: Bình phương khoảng cách Euclid giữa hai vector trung bình.
  
  *$"Tr"$*: Phép tính vết của ma trận (Trace - tổng các phần tử trên đường chéo chính).
]

#untab_para[
  *_Ý nghĩa_*: FID đo khoảng cách Fréchet giữa hai phân bố Gaussian đa biến. *Giá trị FID càng thấp* cho thấy *phân bố của ảnh sinh càng tiệm cận với phân bố ảnh thật*, đồng nghĩa với việc mô hình *sinh ra ảnh vừa chân thực (realism) vừa đa dạng (diversity)*.
]

==== Phân tích mối tương quan và Vai trò của bộ độ đo
Việc sử dụng đơn lẻ một độ đo không thể phản ánh toàn diện hiệu năng của mô hình sinh phông chữ, do đó khoá luận kết hợp bốn độ đo trên theo *chiến lược đánh giá đa tầng*. Đầu tiên, ở tầng *đánh giá độ chính xác điểm ảnh (Pixel-level Accuracy)*, các chỉ số *L1* và *SSIM* đảm bảo rằng ảnh sinh ra không bị lệch lạc quá nhiều về vị trí không gian so với ảnh mẫu (Ground Truth). Tuy nhiên, đối với các mô hình sinh (Generative Models), việc tối ưu hoá quá mức L1 thường dẫn đến hiện tượng ảnh bị *làm mờ (blurring effect)* để giảm thiểu sai số trung bình. Để khắc phục, tầng thứ hai tập trung vào *đánh giá chất lượng cảm nhận (Perceptual Quality)* thông qua *LPIPS* và *FID*. Trong khi LPIPS đo lường sự tương đồng trong *không gian đặc trưng (Feature Space)* giúp mô hình được "tha thứ" cho những sai lệch nhỏ về pixel miễn là đặc điểm nhận dạng bảo toàn, thì FID đóng vai trò trọng tâm trong việc đánh giá mức độ *"thật" (realism)* và *tính đa dạng (diversity)*. 

Sự kết hợp giữa SSIM (cấu trúc) và LPIPS (cảm nhận) là đặc biệt quan trọng trong bài toán Cross-Lingual, nơi việc giữ cấu trúc chữ quan trọng ngang hàng với việc bắt chước phong cách.

=== Đánh giá Định tính (Qualitative Evaluation)
Các chỉ số định lượng (Quantitative Metrics) như FID hay LPIPS, mặc dù khách quan, nhưng không thể mô phỏng hoàn toàn gu thẩm mỹ và khả năng đọc hiểu của con người. Do đó, để kiểm chứng tính thực tiễn của phương pháp đề xuất, Khoá luận thực hiện *đánh giá định tính* trên hai khía cạnh: *phân tích thị giác dựa trên chuyên môn (Visual Analysis)* và *khảo sát cảm nhận người dùng (User Study)*.

==== Quy trình Phân tích Trực quan (Visual Analysis Protocol)
Để kiểm chứng chất lượng thực tế, khoá luận thực hiện *so sánh song song* giữa ảnh sinh ra từ mô hình đề xuất và các mô hình khác nhằm soi xét các *lỗi thị giác cụ thể* bằng mắt thường, tập trung vào việc quan sát xem các nét chữ — đặc biệt là những *nét mảnh* hoặc *các vùng giao nhau phức tạp* — có giữ được *độ liền mạch và dứt khoát* hay bị *đứt gãy*, đồng thời kiểm tra xem ảnh có gặp phải các lỗi "khó coi" như bị *mờ nhoè*, *lem luốc* hoặc xuất hiện các *vết mực thừa* khiến cấu trúc chữ bị biến dạng hay không.

==== Thiết kế Khảo sát Người dùng (User Study Design) <user-study-design>
Để đánh giá chất lượng thị giác và tính nhất quán phong cách một cách khách quan nhất theo cảm nhận của con người, khoá luận thiết kế một bảng *khảo sát mù (blind test)* với sự tham gia của tổng cộng *20 tình nguyện viên*. Nhóm khảo sát bao gồm 5 người bạn học chuyên ngành thiết kế đồ hoạ có kiến thức về typography và 15 người dùng phổ thông, đảm bảo tính đại diện cho cả đánh giá kỹ thuật và thẩm mỹ công chúng. 

Bộ dữ liệu khảo sát được xây dựng từ *20 bộ mẫu ngẫu nhiên* trích xuất từ tập kiểm thử (Test Set), *bao gồm các mẫu đại diện cho cả hai kịch bản chuyển đổi phong cách*: *từ Hán tự sang Latin* và *từ Latin sang Hán tự*. Trong mỗi câu hỏi, tình nguyện viên được yêu cầu so sánh kết quả sinh ảnh giữa các mô hình khác nhau. Cụ thể, trong mỗi câu hỏi, tình nguyện viên được cung cấp hai dữ liệu đầu vào gồm: một *ảnh nội dung (Content Image)* để xác định cấu trúc ký tự và một *ảnh tham chiếu (Reference Style)* để xác định phong cách mục tiêu.

#figure(
  image("../images/userscore_question.png", width: 100%),
  caption: [Ví dụ về ảnh nội dung và ảnh tham chiếu.]
)

Dựa trên hai dữ liệu này, người tham gia được yêu cầu quan sát các *ảnh kết quả* được sinh ra bởi 5 mô hình khác nhau (bao gồm DG-Font, CF-Font, DFS, FTransGAN và Phương pháp đề xuất Ours). Vị trí hiển thị của các ảnh kết quả này được *xáo trộn ngẫu nhiên* nhằm loại bỏ thiên kiến vị trí. Nhiệm vụ của tình nguyện viên là chọn ra bức ảnh duy nhất mà họ đánh giá là tối ưu nhất dựa trên hai tiêu chí: *độ nhất quán phong cách* so với ảnh tham chiếu và *chất lượng hình ảnh tổng thể* (độ sắc nét và tính toàn vẹn cấu trúc).

#figure(
  image("../images/userscore_answer.png", width: 100%),
  caption: [Ví dụ về các kết quả mà người tham khảo sát có thể chọn.]
)

_*Tiêu chí đánh giá*_: Thay vì chấm điểm phức tạp, người tham gia được yêu cầu thực hiện đánh giá dựa trên *lựa chọn ưu tiên*. Cụ thể, với mỗi bộ mẫu, tình nguyện viên cần chọn ra một bức ảnh duy nhất mà họ cho là tốt nhất dựa trên sự cân bằng giữa hai tiêu chí cốt lõi. Thứ nhất là *Tính nhất quán phong cách*, tức ảnh sinh ra phải kế thừa chính xác các đặc trưng thị giác của ảnh phong cách (như độ đậm nhạt, kết cấu nét cọ, hoặc kiểu chân chữ serif/sans-serif). Thứ hai là *Tính toàn vẹn nội dung*, tức ký tự sinh ra phải duy trì đúng cấu trúc hình học của ảnh nội dung, đảm bảo tính dễ đọc và không bị biến dạng kỳ quái (ví dụ: chữ `丘` trong kịch bản `e2c` phải giữ nguyên các nét ngang dọc đặc trưng, không bị lai tạp thành ký tự Latin). Kết quả cuối cùng được định lượng thông qua *Tỷ lệ Ưu tiên*, tính bằng phần trăm số phiếu bầu chọn mà mỗi mô hình nhận được trên tổng số lượt đánh giá.

== Kết quả Thực nghiệm và Thảo luận
Trong chương này, khoá luận trình bày toàn bộ kết quả thực nghiệm của mô hình đề xuất. Nội dung bao gồm đánh giá định lượng và định tính chi tiết, nghiên cứu bóc tách (ablation study) về các thành phần kiến trúc, khảo sát người dùng, và phân tích các trường hợp thất bại. Các kết quả này được đối chiếu trực tiếp với nhiều mô hình sinh font hiện đại, bao gồm các mô hình *GAN-based* (DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle, FTransGAN@Li2021FTransGAN), mô hình *diffusion-based* (FontDiffuser@Yang2024FontDiffuser), và các phiên bản mô hình của khoá luận.

Để đánh giá toàn diện khả năng chuyển đổi đa ngôn ngữ, khoá luận thực hiện thực nghiệm trên hai hướng chính với các mục tiêu nghiên cứu và cấu hình mô hình cụ thể, khẳng định giá trị nghiên cứu ngang nhau của bài toán Cross-Lingual Font Generation:

1. *Hướng Latin $->$ Hán tự*:
Đây là kịch bản kiểm tra khả năng *chuyển giao phong cách Latin* tinh tế lên *cấu trúc Hán tự* phức tạp. Trong kịch bản này, mô hình cần học các đặc trưng nét (như serif, độ dày nét, góc bo) của hệ chữ Latin và áp dụng chúng lên các ký tự Hán. Mục tiêu là kiểm tra hiệu quả của mô-đun *CL-SCR* trong việc tách biệt phong cách Latin khỏi nội dung Latin, đảm bảo sự nhất quán phong cách khi áp dụng lên hệ chữ có hình thái học khác biệt (Hán tự).

Khoá luận sử dụng hai cấu hình mô hình cho hướng này: $"Ours"_"A"$ (sử dụng ký tự `A` làm ảnh phong cách tham chiếu) và $"Ours"_"AZ"$ (sử dụng ký tự ngẫu nhiên `trong khoảng A đến Z` làm ảnh phong cách tham chiếu).

2. *Hướng Hán tự $->$ Latin*:
Đây là kịch bản kiểm tra khả năng *khái quát hoá phong cách Hán tự* phức tạp lên *cấu trúc Latin* đơn giản. Trong kịch bản này, mô hình phải học các đặc trưng phong cách đa dạng (ví dụ: nét bút lông, độ dày-mỏng bất đối xứng) từ Hán tự và áp dụng chúng lên cấu trúc Latin. Sự thành công trong hướng này chứng tỏ mô hình có thể trích xuất các đặc trưng phong cách bậc cao của Hán tự để áp dụng hợp lý lên các ký tự Latin có cấu trúc tuyến tính hơn.

Đối với hướng Hán tự $->$ Latin, khoá luận tiến hành phân loại và đánh giá các kịch bản dựa trên *độ phức tạp của ký tự Hán tự* (số nét $M$) được sử dụng làm ảnh tham chiếu phong cách, nhằm phân tích độ nhạy của mô hình đối với sự đa dạng của nét:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    rows: (auto, auto, auto, auto, auto),
    stroke: (x, y) => if x >= 0 and y >= 0 { 0.5pt },
    align: horizon,
    table.header(
      [*Cấp độ*], [*Định nghĩa (Số nét $M$)*], [*Cấu hình Mô hình*], [*Mục tiêu Phân tích*],
    ),
    table.hline(),

    [All], [Đánh giá tổng thể trên các ký tự Hán tự có số nét ngẫu nhiên.], [$"Ours"_"All"$], [Đánh giá hiệu năng trung bình của mô hình trên toàn bộ miền dữ liệu Hán tự.],

    [Easy], [Ảnh phong cách là Hán tự có số nét $6 <= M <= 10$.], [$"Ours"_"Easy"$], [Kiểm tra khả năng học các đặc trưng phong cách từ cấu trúc đơn giản.],

    [Medium], [Ảnh phong cách là Hán tự có số nét $11 <= M <= 20$.], [$"Ours"_"Medium"$], [Kiểm tra hiệu quả của các mô-đun bảo toàn nét (MCA) khi đối mặt với cấu trúc trung bình.],

    [Hard], [Ảnh phong cách là Hán tự có số nét $M >= 21$.], [$"Ours"_"Hard"$], [Đánh giá khả năng trích xuất phong cách từ cấu trúc phức tạp và dày đặc nhất mà không làm mất thông tin nét.],
  ),
  caption: [Bảng phân loại các kịch bản dựa trên độ phức tạp của ký tự.]
) <tab:stroke_compare>

#let size = 100
#let image-grid(paths) = grid(
  columns: (100pt,) * paths.len(),
  inset: 1pt,
  gutter: 15pt,
  ..paths.map(path =>
    box(
      width: 100pt,
      height: 100pt,
      image(
        path,
        width: 100pt,
        height: 100pt,
        fit: "contain"
      )
    )
  )
)

#figure(
  image-grid((
    "../images/FontDiffuser/segment_a.pdf",
    "../images/FontDiffuser/segment_b.pdf",
    "../images/FontDiffuser/segment_c.pdf",
  )),
  caption: [Ví dụ ba loại độ phức tạp.]
) <image:stroke_compare>

Việc phân loại theo độ phức tạp này giúp khoá luận xác định mô-đun *CL-SCR* hoặc các kiến trúc lõi khác (*MCA*, *RSI*) hoạt động hiệu quả nhất ở mức độ phức tạp cấu trúc nào của phong cách Hán tự, từ đó cung cấp những cái nhìn sâu sắc hơn về khả năng học đặc trưng của mô hình khuếch tán.

=== So sánh Định lượng
Các bảng dưới đây trình bày kết quả so sánh giữa phương pháp đề xuất (Ours) với các baseline mạnh nhất hiện nay gồm DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle, FTransGAN@Li2021FTransGAN và trên 2 kịch bản UFSC và SFUC cho tác vụ chuyển đổi phong cách từ chữ Latin sang ảnh nguồn Hán và ngược lại.

==== Tác vụ chuyển đổi phong cách từ chữ Latin sang ảnh nguồn Hán (e2c)
#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),
    table.hline(),
    [DG-Font@Xie2021DGFont], [0.2773], [0.2702], [0.4023], [106.3833],
    [CF-Font@Wang2023CFFont], [0.2659], [0.2740], [0.3979], [91.2134],
    [DFS@Zhu2020FewShotTextStyle], [0.2131], [0.3558], [0.3812], [45.4212],
    [FTransGAN@Li2021FTransGAN], [*0.1844*], [#underline[0.3900]], [0.3548], [40.4561],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.1976], [0.3775], [0.2968], [14.6871],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"A"$ (w/ CL-SCR)], [#underline[0.1927]], [*0.3912*], [*0.2868*], [#underline[12.3964]],
    [$"Ours"_"AZ"$ (w/ CL-SCR)], [0.1939], [0.3890], [#underline[0.2911]], [*11.7691*]
  ),
  caption: [Kết quả Định lượng cho Latin $->$ Hán tự (e2c) trên SFUC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:e2c_sfuc>

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),
    table.hline(),
    [DG-Font@Xie2021DGFont], [0.2797], [0.2654], [0.3649], [54.0974],
    [CF-Font@Wang2023CFFont], [0.2638], [0.2716], [0.3615], [51.3925],
    [DFS@Zhu2020FewShotTextStyle], [*0.2008*], [0.3048], [0.3876], [62.7206],
    [FTransGAN@Li2021FTransGAN], [#underline[0.2089]], [0.3109], [0.3329], [42.1053],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.2283], [0.2946], [0.3184], [29.0999],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"A"$ (w/ CL-SCR)], [0.2218], [#underline[0.3144]], [*0.2892*], [#underline[17.8373]], 
    [$"Ours"_"AZ"$ (w/ CL-SCR)], [0.2214], [*0.3197*], [#underline[0.2954]], [*13.5508*]
  ),
  caption: [Kết quả Định lượng cho Latin $->$ Hán tự (e2c) trên UFSC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:e2c_ufsc>

Dựa trên số liệu từ @tab:e2c_sfuc và @tab:e2c_ufsc, có thể rút ra những đánh giá quan trọng về hiệu năng của phương pháp đề xuất so với các mô hình State-of-the-Art (SOTA).

*Thứ nhất, về chất lượng thị giác và độ tự nhiên của ảnh sinh*: Kết quả thực nghiệm cho thấy sự cải thiện mang tính đột phá được phản ánh qua chỉ số FID. Trong kịch bản SFUC (Seen Font), biến thể tốt nhất $"Ours"_"AZ"$ đạt FID là *11.769*, giảm khoảng *20%* so với baseline mạnh nhất là FontDiffuser@Yang2024FontDiffuser (14.687) và bỏ xa các phương pháp GAN truyền thống. Sức mạnh thực sự của mô hình được thể hiện rõ nét hơn ở kịch bản khó UFSC (Unseen Font), nơi mô hình phải sinh ảnh từ các font chưa từng thấy. Tại đây, $"Ours"_"AZ"$ đạt FID *13.551*, thấp hơn tới *53%* so với FontDiffuser (29.100). Điều này chứng minh mô-đun CL-SCR đã giải quyết hiệu quả vấn đề "domain gap" (khoảng cách miền dữ liệu) giữa chữ Hán và chữ Latin, giúp ảnh sinh ra có phân bố sát với ảnh thật thay vì bị nhiễu hoặc méo mó.

*Thứ hai, về khả năng bảo toàn cấu trúc và nghịch lý L1*: Phương pháp đề xuất dẫn đầu về chỉ số tương đồng cấu trúc SSIM ở cả hai kịch bản (đạt *0.391* ở SFUC và *0.320* ở UFSC), cho thấy các nét chữ được tái tạo sắc nét và đúng cấu trúc.Một điểm đáng lưu ý là mô hình FTransGAN@Li2021FTransGAN đạt kết quả tốt nhất về sai số điểm ảnh L1 (0.1844 ở SFUC), nhưng chỉ số FID của nó lại rất cao (40.456). Đây là minh chứng điển hình cho "nghịch lý L1": các mô hình hồi quy (như FTransGAN hay DFS) thường tối ưu hoá bằng cách sinh ra các ảnh "trung bình cộng" bị mờ để giảm thiểu sai số pixel tuyệt đối. Ngược lại, phương pháp đề xuất chấp nhận chỉ số L1 cao hơn một chút để tái tạo các chi tiết tần số cao, mang lại độ sắc nét và tính chân thực vượt trội cho thị giác con người.

*Thứ ba, hiệu quả của chiến lược tham chiếu ngẫu nhiên (A vs. AZ)*: Sự so sánh nội bộ giữa hai biến thể ($"Ours"_"A"$ và $"Ours"_"AZ"$) khẳng định tầm quan trọng của việc đa dạng hoá dữ liệu tham chiếu đầu vào. $"Ours"_"AZ"$ đạt hiệu suất vượt trội hơn hẳn so với $"Ours"_"A"$, đặc biệt là sự chênh lệch lớn về FID ở kịch bản UFSC (*13.55* so với *17.84*). Điều này chứng minh rằng việc sử dụng linh hoạt các ký tự ngẫu nhiên (A-Z) làm ảnh mẫu giúp quá trình trích xuất đặc trưng tách biệt được phong cách khỏi nội dung hiệu quả hơn, thay vì bị chi phối (bias) bởi cấu trúc hình học cố định của ký tự `A`. Nhờ đó, mô hình nắm bắt được bản chất của phong cách (như độ đậm nhạt, serif, texture) để áp dụng nhất quán cho các font chữ lạ, tránh tình trạng sao chép máy móc các đặc điểm cục bộ của một ký tự tham chiếu duy nhất.

#pagebreak()

#figure(
  grid(
    columns: (auto, auto, auto),
    gutter: 0.5pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== SFUC e2c =====
    grid.cell(
      rowspan: 8,
      align: horizon,
      rotate(-90deg, reflow: true)[*SFUC*],
    ),
    grid.vline(),

    [Ảnh nội dung],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "Content"
    ),

    [Ảnh phong cách],
    glyph-grid2(
      ("B", "I", "N", "U", "V"),
      "../images/eval/eng2chi/",
      "Content"
    ),

    [DG-Font],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "DG"
    ),

    [CF-Font],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "CF"
    ),

    [DFS],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "DFS"
    ),

    [FTransGAN],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "FTransGAN"
    ),

    grid.hline(),

    [$"Ours"_"AZ"$],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "FontDiffuser"
    ),

    [*Target*],
    glyph-grid2(
      ("泡", "玉", "瓜", "瓦", "申"),
      "../images/eval/eng2chi/",
      "GroundTruth"
    ),
  ),
  caption: [So sánh ảnh sinh trên tập SFUC cho kịch bản Latin $->$ Hán tự (e2c) \ giữa các phương pháp và ground truth.]
) <compare-e2c-sfuc>

#pagebreak()

#figure(
  grid(
    columns: (auto, auto, auto),
    gutter: 0.5pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== UFSC e2c =====
    grid.cell(
      rowspan: 8,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC*],
    ),
    grid.vline(),

    [Ảnh nội dung],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "Content"
    ),

    [Ảnh phong cách],
    glyph-grid2(
      ("Z", "D", "W", "B", "J"),
      "../images/eval/eng2chi_style/",
      "Content"
    ),

    [DG-Font],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "DG"
    ),

    [CF-Font],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "CF"
    ),

    [DFS],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "DFS"
    ),

    [FTransGAN],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "FTransGAN"
    ),

    grid.hline(),

    [$"Ours"_"AZ"$],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "FontDiffuser"
    ),

    [*Target*],
    glyph-grid2(
      ("毛", "毫", "民", "气", "水"),
      "../images/eval/eng2chi_style/",
      "GroundTruth"
    ),
  ),
  caption: [So sánh ảnh sinh trên tập UFSC cho kịch bản Latin $->$ Hán tự (e2c) \ giữa các phương pháp và ground truth.]
) <compare-e2c-ufsc>

#pagebreak()

==== Tác vụ chuyển đổi phong cách từ chữ Hán sang ảnh nguồn Latin (c2e)
#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),
    table.hline(),
    [DG-Font@Xie2021DGFont], [0.1462], [0.5542], [0.2821], [74.1655],
    [CF-Font@Wang2023CFFont], [0.1402], [0.5621], [0.2790], [67.1241],
    [DFS@Zhu2020FewShotTextStyle], [0.1083], [0.6140], [0.2585], [40.4042],
    [FTransGAN@Li2021FTransGAN], [0.1381], [0.5291], [0.2851], [55.5859],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.1223], [0.6107], [0.2270], [21.2234],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"All"$ (w/ CL-SCR)], [0.1083], [0.6406], [0.2019], [14.7298], 
    [$"Ours"_"Easy"$ (w/ CL-SCR)], [*0.1079*], [*0.6413*], [*0.2018*], [*14.6558*],
    [$"Ours"_"Medium"$ (w/ CL-SCR)], [#underline[0.1082]], [#underline[0.6406]], [#underline[0.2024]], [#underline[14.8556]], 
    [$"Ours"_"Hard"$ (w/ CL-SCR)], [0.1114], [0.6318], [0.2084], [15.7662], 
  ),
  caption: [Kết quả Định lượng cho Hán tự $->$ Latin (c2e) trên SFUC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:c2e_sfuc>

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),
    table.hline(),
    [DG-Font@Xie2021DGFont], [0.1397], [0.5624], [0.2751], [89.8197],
    [CF-Font@Wang2023CFFont], [0.1317], [0.5756], [0.2726], [84.3787],
    [DFS@Zhu2020FewShotTextStyle], [0.1139], [0.5819], [0.2907], [75.2760],
    [FTransGAN@Li2021FTransGAN], [0.1456], [0.4949], [0.3023], [88.4450],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.1370], [0.5731], [0.2476], [59.5788],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"All"$ (w/ CL-SCR)], [0.1090], [0.6377], [0.1985], [*41.1152*], 
    [$"Ours"_"Easy"$ (w/ CL-SCR)], [#underline[0.1050]], [#underline[0.6439]], [#underline[0.1945]], [#underline[41.7273]], 
    [$"Ours"_"Medium"$ (w/ CL-SCR)], [*0.1029*], [*0.6466*], [*0.1929*], [43.6918], 
    [$"Ours"_"Hard"$ (w/ CL-SCR)], [0.1050], [0.6444], [0.1982], [45.5486], 
  ),
  caption: [Kết quả Định lượng cho Hán tự $->$ Latin (c2e) trên UFSC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:c2e_ufsc>

Dựa trên số liệu từ @tab:c2e_sfuc và @tab:c2e_ufsc, kết quả thực nghiệm cho thấy *phương pháp đề xuất (Ours) đạt được sự cải thiện toàn diện so với các mô hình SOTA*, đồng thời hé lộ mối tương quan thú vị giữa độ phức tạp của Hán tự nguồn và hiệu quả chuyển đổi phong cách lên chữ Latin.

*Thứ nhất, về hiệu năng tổng thể và khả năng tổng quát hoá*: Mô hình đề xuất vượt trội hoàn toàn so với Baseline FontDiffuser@Yang2024FontDiffuser ở cả hai kịch bản. Trên tập dữ liệu quen thuộc SFUC, cấu hình $"Ours"_"Easy"$ đạt mức FID thấp kỷ lục *14.656*, giảm khoảng 31% so với Baseline (21.223). Sự chênh lệch càng trở nên rõ rệt hơn ở kịch bản khó UFSC (Unseen Font), nơi $"Ours"_"All"$ đạt FID *41.115*, thấp hơn đáng kể so với mức *59.579* của Baseline. Khi so sánh với các phương pháp GAN (như DG-Font, CF-Font, FTransGAN), vốn có chỉ số FID rất cao (trên 80 tại UFSC), phương pháp đề xuất chứng minh ưu thế tuyệt đối về độ tự nhiên và tính thẩm mỹ. Điều này khẳng định mô-đun CL-SCR không chỉ hiệu quả trong việc tinh chỉnh phong cách nội tại mà còn giúp mô hình tổng quát hoá tốt hơn khi phải áp dụng các phong cách Hán tự lạ lẫm, phức tạp lên cấu trúc Latin đơn giản.

*Thứ hai, phân tích "Điểm ngọt" về độ phức tạp nét*: Việc phân tách ảnh tham chiếu (reference images) thành các nhóm Easy, Medium và Hard mang lại những góc nhìn giá trị về hiệu quả của việc chuyển đổi phong cách. Tại bảng @tab:c2e_ufsc, cấu hình $"Ours"_"Medium"$ đạt kết quả tốt nhất về các chỉ số cấu trúc và điểm ảnh (*L1 thấp nhất 0.1029, SSIM cao nhất 0.6466*). Điều này gợi ý rằng các Hán tự có số nét trung bình (11-20 nét) là *"điểm ngọt" để làm ảnh mẫu trích xuất phong cách*: chúng cung cấp đủ thông tin về bút pháp và kết cấu (tốt hơn Easy) nhưng không gây ra quá nhiều nhiễu cấu trúc cho quá trình suy luận như các ký tự Hard (trên 21 nét). Vì chữ Latin có cấu trúc hình học rất đơn giản, việc sử dụng các ký tự nguồn quá phức tạp (Hard) khiến mô hình gặp khó khăn trong việc lọc bỏ các chi tiết thừa khi mapping sang đích, dẫn đến hiệu suất tái tạo cấu trúc (SSIM) thấp hơn.

*Thứ ba, sự đánh đổi giữa độ chính xác và độ tự nhiên*: Một điểm đáng lưu ý là mặc dù việc sử dụng ảnh tham chiếu nhóm Medium ($"Ours"_"Medium"$) giúp tối ưu hóa các chỉ số kỹ thuật (L1/SSIM), nhưng cấu hình sử dụng toàn bộ không gian tham chiếu ($"Ours"_"All"$) lại đạt chỉ số *FID tốt nhất* trên tập UFSC (*41.115*). Điều này cho thấy việc đa dạng hóa độ phức tạp của ảnh đầu vào (input reference) giúp mô hình tiếp cận được không gian biểu diễn phong cách phong phú và liên tục hơn. Nhờ đó, ảnh sinh ra có độ tự nhiên cao nhất về mặt cảm nhận thị giác (visual perception), ngay cả khi độ khớp chính xác từng điểm ảnh thua kém nhẹ so với việc chỉ sử dụng nhóm ảnh mẫu Medium.

#figure(
  grid(
    columns: (auto, auto, auto),
    gutter: 0.5pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== SFUC c2e =====
    grid.cell(
      rowspan: 8,
      align: horizon,
      rotate(-90deg, reflow: true)[*SFUC*],
    ),
    grid.vline(),

    [Ảnh nội dung],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "Content"
    ),

    [Ảnh phong cách],
    glyph-grid2(
      ("李", "线", "她", "坦", "与"),
      "../images/eval/chi2eng/",
      "Content"
    ),

    [DG-Font],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "DG"
    ),

    [CF-Font],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "CF"
    ),

    [DFS],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "DFS"
    ),

    [FTransGAN],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "FTransGAN"
    ),

    grid.hline(),

    [$"Ours"_"All"$],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "FontDiffuser"
    ),

    [*Target*],
    glyph-grid2(
      ("k", "l", "m", "n", "o"),
      "../images/eval/chi2eng/",
      "GroundTruth"
    ),
  ),
  caption: [So sánh ảnh sinh trên tập SFUC cho kịch bản Hán tự $->$ Latin (c2e) \ giữa các phương pháp và ground truth.]
) <compare-c2e-sfuc>

#figure(
  grid(
    columns: (auto, auto, auto),
    gutter: 0.5pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== UFSC e2c =====
    grid.cell(
      rowspan: 8,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC*],
    ),
    grid.vline(),

    [Ảnh nội dung],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "Content"
    ),

    [Ảnh phong cách],
    glyph-grid2(
      ("衣", "牛", "土", "生", "至"),
      "../images/eval/chi2eng_style/",
      "Content"
    ),

    [DG-Font],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "DG"
    ),

    [CF-Font],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "CF"
    ),

    [DFS],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "DFS"
    ),

    [FTransGAN],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "FTransGAN"
    ),

    grid.hline(),

    [$"Ours"_"All"$],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "FontDiffuser"
    ),

    [*Target*],
    glyph-grid2(
      ("c", "d", "e", "f", "g"),
      "../images/eval/chi2eng_style/",
      "GroundTruth"
    ),
  ),
  caption: [So sánh ảnh sinh trên tập UFSC cho kịch bản Hán tự $->$ Latin (c2e) \ giữa các phương pháp và ground truth.]
) <compare-c2e-ufsc>

=== So sánh Định tính
Bên cạnh các chỉ số đo lường, việc phân tích trực quan là bước không thể thiếu để kiểm chứng khả năng xử lý các trường hợp khó của mô hình, đặc biệt là các lỗi cấu trúc mà các chỉ số thống kê như FID đôi khi không phản ánh hết. Khoá luận thực hiện phân tích dựa trên hình ảnh sinh ra từ hai chiều chuyển đổi đối lập.

==== Phân tích Trực quan
Để kiểm chứng các chỉ số định lượng, phân tích trực quan tại các @compare-e2c-sfuc đến @compare-c2e-ufsc cho thấy sự vượt trội của phương pháp đề xuất (Ours) về *độ sắc nét* và *khả năng bảo toàn nội dung* xuyên ngôn ngữ; cụ thể, đối với tác vụ Latin sang Hán tự, trong khi *DFS* sinh ra các nét mảnh thiếu sức sống tại @compare-e2c-sfuc và *FTransGAN* gặp hiện tượng *"bóng ma" mờ nhoè* do tối ưu hoá L1 tại @compare-e2c-ufsc, mô hình $"Ours"_"AZ"$ lại tái tạo chính xác *độ đậm* và *cấu trúc* của nét bút. Đối với chiều ngược lại từ Hán tự sang Latin, phương pháp đề xuất khắc phục hoàn toàn lỗi *rò rỉ nội dung* của *DG-Font* tại @compare-c2e-sfuc (nơi các chữ cái Latin bị biến dạng thành giả Hán tự) và đặc biệt thể hiện khả năng *học kết cấu tinh vi* tại Hình @compare-c2e-ufsc, nơi $"Ours"_"All"$ là mô hình duy nhất tái hiện thành công hiệu ứng *"in kim" (dot-matrix)* thay vì sinh ra các nét viền rỗng như FTransGAN hay hình ảnh vỡ nát như DFS, qua đó khẳng định *giá trị thực tiễn* và *khả năng tổng quát hoá* ưu việt của mô-đun CL-SCR.

==== Đánh giá Cảm nhận Người dùng
Dựa trên quy trình khảo sát mù (blind test) đã được thiết lập chi tiết tại @user-study-design, khoá luận tổng hợp kết quả bình chọn từ 20 tình nguyện viên trên tập dữ liệu kiểm thử ngẫu nhiên.

#figure(
    image("../images/userscore_chart.png", width: 100%),
    caption: [Biểu đồ so sánh tỷ lệ ưu tiên của người dùng giữa phương pháp đề xuất (Ours) và các phương pháp SOTA khác. Kết quả cho thấy sự vượt trội về độ hài lòng thị giác của mô hình tích hợp CL-SCR.]
  )

_*Phân tích và Thảo luận*_:

#untab_para[
  Kết quả định lượng cho thấy sự vượt trội của phương pháp đề xuất (Ours) với tỷ lệ được ưu tiên lựa chọn trung bình đạt *khoảng 70%*, bỏ xa các phương pháp đối chứng (cao nhất là CF-Font chỉ đạt khoảng 10%). Sự chênh lệch áp đảo này phản ánh sự tương đồng giữa cảm nhận chủ quan của mắt người và các chỉ số máy học (FID/LPIPS) đã phân tích trước đó.
]

Xu hướng lựa chọn của người dùng có thể được lý giải thông qua sự so sánh trực quan, trong đó *tính dễ đọc (Legibility)* đóng vai trò là yếu tố tiên quyết. Thực tế cho thấy, người dùng thường có phản xạ loại bỏ ngay lập tức các mẫu bị *biến dạng cấu trúc nặng nề* - một nhược điểm cố hữu khiến các mô hình thuộc họ GAN (như DG-Font, CF-Font) nhận được tỷ lệ bình chọn rất thấp ($<10%$). Trong bối cảnh đó, mô hình đề xuất đã chứng minh được ưu thế nhờ khả năng bảo toàn khung xương ký tự vững chắc thông qua cơ chế MCA và RSI, giúp các kết quả sinh ra vượt qua được rào cản nhận thức đầu tiên về mặt cấu trúc để tiến tới các đánh giá chi tiết hơn về phong cách.

Tóm lại, tỷ lệ ưu tiên cao trong khảo sát người dùng là minh chứng thực tiễn khẳng định phương pháp đề xuất đã đạt được điểm cân bằng tốt nhất giữa hai yêu cầu cốt lõi: giữ đúng chữ (Content) và thể hiện đúng kiểu (Style).

== Nghiên cứu Bóc tách (Ablation Study)
Trong phần này, khoá luận thực hiện các phân tích chuyên sâu nhằm định lượng đóng góp cụ thể của từng thành phần kỹ thuật trong phương pháp đề xuất. Để đảm bảo tính tập trung và sức thuyết phục của các kết luận, thay vì dàn trải thí nghiệm trên mọi biến thể, khoá luận cố định và lựa chọn hai cấu hình đại diện tiêu biểu nhất làm cơ sở so sánh:

#tab_eq[
  _*Đối với hướng Latin $->$ Hán tự*_ (`e2c`): Khoá luận sử dụng cấu hình $"Ours"_"AZ"$. Đây là cấu hình chịu áp lực tổng quát hoá lớn nhất (do phải xử lý style ngẫu nhiên) và cũng là cấu hình đạt hiệu năng cao nhất trong các thực nghiệm trước đó. Việc chứng minh hiệu quả trên cấu hình "khó" nhất này sẽ khẳng định tính đúng đắn và mạnh mẽ (robustness) của các cải tiến đề xuất.

  _*Đối với hướng Hán tự $->$ Latin*_ (`c2e`): Khoá luận sử dụng cấu hình $"Ours"_"All"$. Do đặc thù độ phức tạp nét đa dạng của Hán tự, cấu hình này bao quát toàn bộ phổ dữ liệu huấn luyện, cung cấp cái nhìn toàn diện về độ ổn định của mô hình thay vì chỉ tập trung vào một tập con cụ thể (như Easy hay Hard).
]

#untab_para[
  Các thí nghiệm dưới đây sẽ lần lượt đánh giá tác động của bốn yếu tố then chốt: các mô-đun kiến trúc, kỹ thuật tăng cường dữ liệu, chế độ hàm mất mát và số lượng mẫu âm.
]

=== Ảnh hưởng của các mô-đun trong FontDiffuser
Để xác định đóng góp cụ thể của từng thành phần trong kiến trúc tổng thể, đặc biệt là hiệu quả của mô-đun đề xuất so với bản gốc, khoá luận tiến hành *thực nghiệm bóc tách (Ablation Study)* bằng cách *thay thế và bổ sung dần các mô-đun vào mạng nền tảng*. Bốn mô-đun được khảo sát bao gồm:

#tab_eq[
  *M*: *Multi-scale Content Aggregation (MCA)* - Tổng hợp nội dung đa quy mô.

  *R*: *Reference-Structure Interaction (RSI)* - Tương tác cấu trúc tham chiếu.

  *S*: *Style Contrastive Refinement (SCR)* - Tinh chỉnh tương phản phong cách đơn ngôn ngữ (Của FontDiffuser gốc).

  *CL*: *Cross-Lingual Style Contrastive Refinement (CL-SCR)* - Tinh chỉnh tương phản phong cách đa ngôn ngữ (Đề xuất cải tiến).
]

#untab_para[
  Kết quả thực nghiệm trên hai hướng chuyển đổi được trình bày chi tiết tại @tab:e2c_module và @tab:c2e_module.
]

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,

    table.header(
      [], [],
      [*Mô-đun #linebreak() M $"  "$ R $"  "$ S $"  "$ CL*],
      [*L1 $arrow.b$*],
      [*SSIM $arrow.t$*],
      [*LPIPS $arrow.b$*],
      [*FID $arrow.b$*],
    ),

    table.hline(),

    // ================= Ours - AZ =================
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[*$"Ours"_"AZ"$*],
    ),

    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*SFUC*],
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    [0.2441], [0.2983], [0.4434], [70.3650],

    [$checkmark.heavy "  " checkmark.heavy "  " checkmark.heavy "   " crossmark.heavy$],
    [#underline[0.1976]], [#underline[0.3775]], [#underline[0.2968]], [#underline[14.6871]],

    [$checkmark.heavy "  " checkmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    [*0.1939*], [*0.3890*], [*0.2911*], [*11.7691*],

    table.hline(stroke: 0.5pt),

    // ================= Ours - UFSC =================
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC*],
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    [0.2815], [0.1965], [0.4854], [75.7399],

    [$checkmark.heavy "  " checkmark.heavy "  " checkmark.heavy "   " crossmark.heavy$],
    [#underline[0.2283]], [#underline[0.2946]], [#underline[0.3184]], [#underline[29.0999]],

    [$checkmark.heavy "  " checkmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
  ),

  caption: [Ảnh hưởng của các thành phần M, R, S và CL đến hiệu năng mô hình trên tác vụ Latin → Hán tự.]
) <tab:e2c_module>


#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,

    table.header(
      [], [],
      [*Mô-đun #linebreak() M $"  "$ R $"  "$ S $"  "$ CL*],
      [*L1 $arrow.b$*],
      [*SSIM $arrow.t$*],
      [*LPIPS $arrow.b$*],
      [*FID $arrow.b$*],
    ),

    table.hline(),

    // ================= Ours - All =================
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[*$"Ours"_"All"$*],
    ),

    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*SFUC*],
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    [0.2763], [0.2491], [0.4792], [84.7434],

    [$checkmark.heavy "  " checkmark.heavy "  " checkmark.heavy "   " crossmark.heavy$],
    [#underline[0.1223]], [#underline[0.6107]], [#underline[0.2270]], [#underline[21.2234]],

    [$checkmark.heavy "  " checkmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    [*0.1083*], [*0.6406*], [*0.2019*], [*14.7298*],

    table.hline(stroke: 0.5pt),

    // ================= UFSC =================
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC*],
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    [0.3017], [0.1793], [0.5102], [119.9425],

    [$checkmark.heavy "  " checkmark.heavy "  " checkmark.heavy "   " crossmark.heavy$],
    [#underline[0.1370]], [#underline[0.5731]], [#underline[0.2476]], [#underline[59.5788]],

    [$checkmark.heavy "  " checkmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    [*0.1090*], [*0.6377*], [*0.1985*], [*41.1152*],
  ),

  caption: [Ảnh hưởng của các thành phần M, R, S và CL đến hiệu năng mô hình trên tác vụ Hán tự → Latin.]
) <tab:c2e_module>


_*Nhận xét và Thảo luận*_:

#untab_para[
  Quan sát từ dữ liệu thực nghiệm cho thấy vai trò nền tảng không thể thay thế của các mô-đun *M* và *R*. Khi tích hợp hai mô-đun này vào mạng Baseline, hiệu năng mô hình có sự chuyển biến mang tính bước ngoặt, thể hiện qua việc *chỉ số FID giảm sâu* ở cả hai hướng nghiên cứu. Đơn cử như trong kịch bản e2c (UFSC), việc có M và R giúp FID giảm từ *70.36* xuống *29.10* (tương ứng với cấu hình FontDiffuser Gốc). Điều này khẳng định rằng mạng Diffusion thuần tuý gặp rất nhiều khó khăn trong việc định hình cấu trúc ký tự phức tạp nếu chỉ dựa vào đặc trưng cấp cao; M và R chính là "bộ khung xương" cung cấp các đặc trưng nội dung chi tiết đa tầng và tinh chỉnh độ khớp không gian, giúp mô hình dựng hình chính xác các nét và bộ thủ.
]

Tuy nhiên, điểm nhấn quan trọng nhất nằm ở sự so sánh giữa mô-đun *S (SCR gốc)* và *CL (CL-SCR đề xuất)*. Kết quả thực nghiệm cho thấy *CL-SCR* vượt trội hơn hẳn so với SCR gốc, đặc biệt là trong các kịch bản khó *(Unseen Font)*. Cụ thể, trong hướng `e2c` (UFSC), việc thay thế S bằng CL giúp FID giảm mạnh từ *29.10* xuống *13.55*. Tương tự ở hướng `c2e` (UFSC), FID giảm từ *59.58* xuống *41.11*.

#set par(first-line-indent: 0pt)
_*Lý giải*_: *SCR gốc* vốn được thiết kế cho bài toán đơn ngôn ngữ, nơi khoảng cách giữa các phong cách nhỏ hơn. Khi áp dụng cho bài toán đa ngôn ngữ (*Cross-Lingual*), SCR gốc gặp khó khăn trong việc tách biệt triệt để phong cách khỏi nội dung do sự khác biệt lớn về hình thái học. Ngược lại, *CL-SCR* với *cơ chế tương phản đa miền và chiến lược lấy mẫu âm cải tiến* đã giúp mô hình "hiểu" và trích xuất được bản chất phong cách (như kết cấu, bút pháp) một cách trừu tượng hơn, qua đó đảm bảo chất lượng sinh ảnh ổn định và tự nhiên ngay cả với các font chữ mới lạ.
#set par(first-line-indent: 1.5em)

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 8pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== Header =====
    [], grid.vline(),
    [*Mô-đun \ M $"  "$ R $"  "$ S $"  "$ CL*], grid.vline(),
    [*Example 1*], grid.vline(),
    [*Example 2*],

    // ===== UFSC e2c =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )],
    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/noMCA_noRSI/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/noMCA_noRSI/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " checkmark.heavy "  " crossmark.heavy$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/intra/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/intra/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    // ===== UFSC c2e =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )],
    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/noMCA_noRSI/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/noMCA_noRSI/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " checkmark.heavy "  " crossmark.heavy$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/intra/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/intra/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [$crossmark.heavy "  " crossmark.heavy "  " crossmark.heavy "  " checkmark.heavy$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa các mô-đun khác nhau trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (e2c và c2e).
  ]
)
_*Kết luận*_: Tổng hợp lại, kết quả nghiên cứu bóc tách đã làm sáng tỏ vai trò riêng biệt và bổ trợ lẫn nhau của các thành phần kiến trúc. Trong khi *MCA* và *RSI* đóng vai trò là nền tảng cấu trúc không thể thiếu để ngăn chặn sự sụp đổ hình dáng ký tự, thì *CL-SCR* chính là nhân tố quyết định nâng tầm chất lượng thị giác và khả năng tổng quát hoá. Việc CL-SCR giúp giảm sâu chỉ số *FID* trên các *tập dữ liệu lạ (UFSC)* so với SCR gốc khẳng định rằng cơ chế tương phản đa ngôn ngữ là chìa khoá để mô hình vượt qua rào cản hình thái học, cho phép chuyển giao phong cách Latin sang Hán tự một cách tự nhiên và linh hoạt hơn.

=== Ảnh hưởng của Tăng cường dữ liệu (Data Augmentation)
Mục tiêu của nghiên cứu này là đánh giá vai trò của *chiến lược tăng cường dữ liệu*, cụ thể là kỹ thuật *Random Resized Crop* (cắt và thay đổi tỷ lệ ngẫu nhiên) được áp dụng trong quá trình huấn luyện mô-đun *CL-SCR*. Về mặt lý thuyết, việc tăng cường dữ liệu giúp mô hình học được *các đặc trưng phong cách bất biến theo tỷ lệ* và tránh hiện tượng *quá khớp (overfitting)*. Để kiểm chứng điều này, khoá luận *so sánh hiệu năng* của mô hình tiêu biểu ($"Ours"_"AZ"$ cho hướng `e2c` và $"Ours"_"All"$ cho hướng `c2e`) trong hai cấu hình: *có* và *không có Augmentation*.

Kết quả thực nghiệm được trình bày chi tiết tại @tab:e2c_aug và @tab:c2e_aug.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [w/o Augment], [#underline[0.1974]], [#underline[0.3831]], [#underline[0.2967]], [#underline[14.1295]],
    [w/ Augment], [*0.1939*], [*0.3890*], [*0.2911*], [*11.7691*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [w/o Augment], [#underline[0.2295]], [#underline[0.3066]], [#underline[0.3060]], [#underline[15.7706]],
    [w/ Augment], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
  ),
  caption: [Ảnh hưởng của tăng cường dữ liệu đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_aug>

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [w/o Augment], [*0.1076*], [*0.6504*], [*0.1978*], [*12.3668*],
    [w/ Augment], [#underline[0.1083]], [#underline[0.6406]], [#underline[0.2019]], [#underline[14.7298]],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [w/o Augment], [#underline[0.1126]], [#underline[0.6364]], [#underline[0.2015]], [#underline[43.0665]],
    [w/ Augment], [*0.1090*], [*0.6377*], [*0.1985*], [*41.1152*],
  ),
  caption: [Ảnh hưởng của tăng cường dữ liệu đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_aug>

_*Nhận xét và Thảo luận*_:

#untab_para[
  Đối với hướng chuyển đổi từ Latin sang Hán tự (`e2c`), quan sát tại @tab:e2c_aug cho thấy việc áp dụng Augmentation mang lại sự cải thiện *toàn diện và nhất quán* trên mọi chỉ số ở cả hai kịch bản SFUC và UFSC. *Đáng chú ý nhất là chỉ số FID trên tập UFSC giảm mạnh từ _15.77_ xuống _13.55_*, tương ứng với mức cải thiện *khoảng 14%*. Điều này có thể được lý giải bởi *đặc thù cấu trúc đơn giản* của ký tự Latin đóng vai trò là ảnh phong cách. Nếu thiếu đi sự đa dạng hoá dữ liệu thông qua Augmentation, mô hình dễ bị phụ thuộc vào các đặc trưng vị trí không gian cố định. Kỹ thuật *Random Resized Crop* buộc mô-đun CL-SCR phải tập trung học các *đặc trưng bản chất* như độ dày nét, serif hay độ tương phản bất kể biến đổi về kích thước hay vị trí, từ đó giúp 
  quá trình áp dụng phong cách lên cấu trúc phức tạp của Hán tự trở nên linh hoạt và tự nhiên hơn.
]

Trong khi đó, hướng chuyển đổi ngược lại từ Hán tự sang Latin (`c2e`) tại @tab:c2e_aug lại hé lộ một sự đánh đổi thú vị giữa khả năng *ghi nhớ và khái quát hoá*. Trên tập dữ liệu đã biết (SFUC), cấu hình không có Augmentation đạt kết quả tốt hơn với FID 12.36 so với 14.72. Tuy nhiên, ưu thế *đảo chiều hoàn toàn* trên tập dữ liệu chưa biết (UFSC), nơi cấu hình có Augmentation giành lại vị thế dẫn đầu với FID giảm từ *43.06* xuống *41.11* và sai số L1 cũng được cải thiện. Hiện tượng này minh chứng rõ ràng cho *vai trò điều hoà (Regularization)* của tăng cường dữ liệu. Ở kịch bản SFUC, việc thiếu nhiễu cho phép mô hình *tối ưu hoá cục bộ (overfit)* trên các mẫu đã thấy, dẫn đến chỉ số cao nhưng kém bền vững. Ngược lại, khi đối mặt với dữ liệu lạ trong UFSC, khả năng ghi nhớ trở nên vô hiệu, và lúc này các *đặc trưng phong cách cốt lõi* mang tính khái quát cao mà mô hình học được nhờ *Augmentation* mới thực sự phát huy tác dụng. Vì vậy, kết quả vượt trội trên UFSC khẳng định rằng tăng cường dữ liệu là thành phần thiết yếu để đảm bảo *khả năng tổng quát hoá* của mô hình trong các ứng dụng thực tế.

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 6pt,
    stroke: none,
    align: horizon,
    inset: 6pt,

    // ===== Header =====
    [], grid.vline(), [*Phương pháp*], grid.vline(), [*Example 1*], grid.vline(), [*Example 2*],
    grid.hline(),
    // ===== UFSC e2c =====
    [#grid.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )], [w/ Augment],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [w/o Augment],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/noaug/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/noaug/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    grid.hline(),
    // ===== UFSC c2e =====
    [#grid.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )], [w/ Augment],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [w/o Augment],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/noaug/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/noaug/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa mô hình có và không áp dụng tăng cường dữ liệu trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (e2c và c2e).]
)

_*Kết luận*_: Dựa trên phân tích trên, khoá luận khẳng định *chiến lược Tăng cường dữ liệu* là thành phần không thể thiếu, đặc biệt quan trọng để nâng cao hiệu suất trên các *dữ liệu chưa từng biết (Unseen Domains)*, mặc dù có thể đánh đổi một lượng nhỏ hiệu năng trên các dữ liệu đã biết.

=== Ảnh hưởng của Chế độ hàm loss (Loss Mode)
Trong kiến trúc *CL-SCR*, hàm mất mát *InfoNCE@Oord2018InfoNCE* đóng vai trò điều hướng không gian biểu diễn phong cách. khoá luận khảo sát *ba biến thể chiến lược huấn luyện* được định nghĩa trong tham số `loss_mode`:
`scr_intra`: Chỉ sử dụng mẫu âm nội miền (Intra-domain). Ví dụ: so sánh Style Latin với các Style Latin khác.
`scr_cross`: Chỉ sử dụng mẫu âm xuyên miền (Cross-domain). Ví dụ: so sánh Style Latin với Style Hán tự.
`scr_both`: Kết hợp cả hai với trọng số $alpha_"intra" = 0.3$ và $beta_"cross"=0.7$.

Kết quả thực nghiệm được trình bày tại @tab:e2c_lossmode và @tab:c2e_lossmode.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Chế độ mất mát*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [scr_intra], [#underline[0.1969]], [#underline[0.3812]], [#underline[0.2958]], [11.9552],
    [scr_cross], [0.1993], [0.3770], [0.2982], [#underline[11.8645]],
    [scr_both], [*0.1939*], [*0.3890*], [*0.2911*], [*11.7691*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [scr_intra], [#underline[0.2290]], [#underline[0.3008]], [#underline[0.3085]], [#underline[15.7197]],
    [scr_cross], [0.2326], [0.2911], [0.3128], [16.2615],
    [scr_both], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
  ),
  caption: [Ảnh hưởng của các chế độ loss đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_lossmode>


#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Chế độ mất mát*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [scr_intra], [*0.0993*], [*0.6614*], [*0.1903*], [*13.6449*],
    [scr_cross], [0.1091], [#underline[0.6436]], [#underline[0.2017]], [#underline[14.0159]],
    [scr_both], [#underline[0.1083]], [0.6406], [0.2019], [14.7298],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [scr_intra], [*0.0971*], [*0.6601*], [*0.1845*], [#underline[41.3399]],
    [scr_cross], [0.1175], [0.6209], [0.2095], [44.7758],
    [scr_both], [#underline[0.1090]], [#underline[0.6377]], [#underline[0.1985]], [*41.1152*],
  ),
  caption: [Ảnh hưởng của các chế độ loss đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_lossmode>

_*Nhận xét và Thảo luận*_:

#untab_para[
  Đối với hướng chuyển đổi từ Latin sang Hán tự (`e2c`), số liệu tại @tab:e2c_lossmode phản ánh *sự thống trị rõ rệt của chiến lược hỗn hợp* `scr_both` trên hầu hết các chỉ số, đặc biệt là sự cải thiện vượt bậc về chỉ số FID trong kịch bản khó UFSC (đạt *13.55* so với 15.72 của `scr_intra` và 16.26 của `scr_cross`). Kết quả này có thể được lý giải bởi *đặc thù thông tin "thưa" (sparse)* của phong cách Latin. Nếu chỉ sử dụng so sánh nội miền `scr_intra`, mô hình khó học được cách các đặc trưng Latin đơn giản tương tác với cấu trúc Hán tự phức tạp; ngược lại, nếu chỉ dùng `scr_cross`, khoảng cách miền quá lớn lại gây ra sự bất ổn định trong quá trình hội tụ. Do đó, sự kết hợp trong `scr_both` *đóng vai trò như cầu nối*, giúp mô hình vừa nắm bắt vững chắc đặc trưng nội tại của Latin, vừa học được mối tương quan ngữ nghĩa với Hán tự để tạo ra kết quả tối ưu.
]

Bức tranh trở nên phức tạp và thú vị hơn khi xét đến chiều ngược lại từ Hán tự sang Latin (`c2e`) tại @tab:c2e_lossmode, nơi xuất hiện một *nghịch lý về độ giàu thông tin*. Khác với hướng `e2c`, chiến lược `scr_intra` *lại thể hiện sự vượt trội về các chỉ số cấu trúc và điểm ảnh*(L1 thấp nhất 0.097, SSIM cao nhất) trên cả hai tập dữ liệu. Nguyên nhân sâu xa nằm ở bản chất *"đậm đặc" (dense) và giàu thông tin* của phong cách Hán tự (nét bút, độ dày, kết cấu). Chỉ cần *so sánh nội bộ giữa các Hán tự* là đã đủ để mô hình trích xuất được một vector phong cách mạnh mẽ. Trong bối cảnh này, việc ép buộc so sánh xuyên miền với Latin (thông qua thành phần cross trong `scr_both`) vô tình tạo ra nhiễu do sự khác biệt quá lớn về cấu trúc, làm giảm nhẹ độ chính xác tái tạo. Tuy nhiên, `scr_both` *vẫn giữ được ưu thế về độ tự nhiên tổng thể* (FID 41.11 so với 41.34) trên tập lạ UFSC, đóng vai trò như một cơ chế điều hoà cần thiết để đảm bảo tính thẩm mỹ khi đối mặt với các font hoàn toàn mới.

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 6pt,
    stroke: none,
    align: horizon,
    inset: 6pt,

    // ===== Header =====
    [], grid.vline(), [*Chế độ mất mát*], grid.vline(), [*Example 1*], grid.vline(), [*Example 2*],
    grid.hline(),

    // ===== UFSC e2c =====
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )], [scr_intra],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/intra/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/intra/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [scr_cross],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/cross/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/cross/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [scr_both],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    grid.hline(),

    // ===== UFSC c2e =====
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )], [scr_intra],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/intra/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/intra/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [scr_cross],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/cross/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/cross/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [scr_both],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa các chế độ mất mát khác nhau trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (e2c và c2e).]
)


_*Kết luận*_: Tổng kết lại, đối với bài toán tổng quát, *chiến lược* `scr_both` *là lựa chọn an toàn và ổn định nhất* để cân bằng giữa độ chính xác và tính tự nhiên. Tuy nhiên, thực nghiệm cũng mở ra một góc nhìn quan trọng: khi miền nguồn có lượng thông tin phong phú như Hán tự, *chiến lược học nội miền* (`scr_intra`) *cũng mang lại hiệu quả rất ấn tượng*, gợi ý tiềm năng tối ưu hoá chi phí huấn luyện cho các ứng dụng cụ thể mà không nhất thiết phải phụ thuộc vào dữ liệu cặp đôi xuyên ngôn ngữ.

=== Ảnh hưởng của Số lượng mẫu âm (Negative Sample Numbers)
Trong khuôn khổ của *phương pháp học tương phản (Contrastive Learning)*, *số lượng mẫu âm ($K$)* đóng vai trò quan trọng trong việc định hình không gian biểu diễn đặc trưng. Theo lý thuyết thông thường, việc tăng số lượng mẫu âm thường giúp mô hình phân biệt tốt hơn giữa các đặc trưng phong cách, từ đó học được các biểu diễn phong phú hơn. Để kiểm chứng giả thuyết này trong bối cảnh sinh phông chữ đa ngôn ngữ, khoá luận tiến hành thực nghiệm với các giá trị *$K$ lần lượt là 4, 8 và 16* trên cả hai hướng chuyển đổi. Kết quả chi tiết được tổng hợp tại @tab:e2c_numneg và @tab:c2e_numneg.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Số lượng mẫu âm*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [4], [*0.1939*], [*0.3890*], [*0.2911*], [#underline[11.7691]],
    [8], [0.1972], [#underline[0.3835]], [#underline[0.2952]], [12.3750],
    [16], [#underline[0.1967]], [0.3833], [0.2956], [*10.6901*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [4], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
    [8], [0.2285], [0.3048], [0.3061], [#underline[15.0245]],
    [16], [#underline[0.2273]], [#underline[0.3064]], [#underline[0.3048]], [16.7855],
  ),
  caption: [Ảnh hưởng của số lượng mẫu âm đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_numneg>


#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Số lượng mẫu âm*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [4], [0.1083], [0.6406], [0.2019], [*14.7298*],
    [8], [#underline[0.1080]], [#underline[0.6464]], [#underline[0.1999]], [#underline[14.8365]],
    [16], [*0.1059*], [*0.6468*], [*0.1992*], [15.7326],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [4], [#underline[0.1090]], [#underline[0.6377]], [*0.1985*], [*41.1152*],
    [8], [*0.1087*], [*0.6398*], [*0.1985*], [43.8077],
    [16], [0.1111], [0.6311], [#underline[0.2008]], [#underline[43.5042]],
  ),
  caption: [Ảnh hưởng của số lượng mẫu âm đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_numneg>

_*Nhận xét và Thảo luận*_:

#untab_para[
  Phân tích số liệu từ thực nghiệm cho thấy một kết quả *trái ngược với trực giác phổ biến trong học tương phản* trên các tác vụ thị giác máy tính khác. Cụ thể, trong hướng chuyển đổi từ Latin sang Hán tự (@tab:e2c_numneg), cấu hình sử dụng số lượng mẫu âm nhỏ nhất ($K=4$) lại thể hiện sự vượt trội về *độ ổn định và khả năng tổng quát hoá*. Trên tập kiểm thử khó UFSC, cấu hình này đạt chỉ số FID tốt nhất là *13.55*, thấp hơn đáng kể so với mức 16.78 khi sử dụng 16 mẫu âm. Đồng thời, các chỉ số về cấu trúc như SSIM và sai số L1 cũng đạt giá trị tối ưu tại *$K=4$*. Điều này gợi ý rằng đối với hệ chữ Latin vốn có cấu trúc nét tương đối đơn giản và "thưa", việc sử dụng quá nhiều mẫu âm có thể vô tình đưa vào các *tín hiệu nhiễu* hoặc các mẫu có phong cách quá tương đồng (*false negatives*), khiến mô hình bị rối loạn trong việc định vị biên giới phong cách, dẫn đến suy giảm hiệu năng trên dữ liệu chưa từng thấy.
]

Xu hướng tương tự cũng được quan sát thấy ở chiều ngược lại từ Hán tự sang Latin (@tab:c2e_numneg), mặc dù có sự phân hoá nhẹ giữa khả năng ghi nhớ và khái quát hoá. Khi đánh giá trên tập font đã biết (SFUC), việc tăng số lượng mẫu âm lên 16 giúp cải thiện nhẹ các chỉ số điểm ảnh như L1 và SSIM, do mô hình tận dụng được nhiều dữ liệu so sánh hơn để khớp chi tiết các nét phức tạp của Hán tự. Tuy nhiên, lợi thế này *không duy trì được khi chuyển sang tập font lạ (UFSC)*. Tại đây, cấu hình $K=4$ một lần nữa khẳng định tính hiệu quả với chỉ số FID thấp nhất (*41.11*), vượt qua cả cấu hình $K=8$ và $K=16$. Kết quả này củng cố nhận định rằng trong bài toán chuyển đổi đa ngôn ngữ với sự chênh lệch lớn về miền dữ liệu, một tập hợp mẫu âm *nhỏ nhưng tinh gọn* sẽ hiệu quả hơn việc cố gắng phân biệt với một lượng lớn mẫu âm có thể gây nhiễu. Do đó, việc lựa chọn $K=4$ không chỉ giúp *tối ưu hoá tài nguyên tính toán* mà còn đảm bảo chất lượng sinh ảnh tốt nhất về mặt thị giác.

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 8pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== Header =====
    [], grid.vline(),
    [*Số lượng mẫu âm*], grid.vline(),
    [*Example 1*], grid.vline(),
    [*Example 2*],

    // ===== UFSC e2c =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )],
    [4],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [8],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg08/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg08/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [16],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg16/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg16/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    // ===== UFSC c2e =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )],
    [4],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [8],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg08/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg08/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [16],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg16/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg16/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa các số lượng mẫu âm khác nhau \ trên tập dữ liệu chưa từng thấy cho cả hai hướng tác vụ (e2c và c2e).
  ]
) <tab:dinhtinh_neg>

_*Kết luận*_: Tổng kết lại, thực nghiệm về số lượng mẫu âm đã làm sáng tỏ một đặc điểm thú vị trong bài toán chuyển đổi phong cách xuyên ngôn ngữ: *sự tối giản lại mang lại hiệu quả tối ưu*. Trái với kỳ vọng rằng nhiều mẫu âm sẽ giúp học biểu diễn phong cách tốt hơn, kết quả cho thấy việc *giới hạn* $K=4$ giúp mô hình xây dựng được *không gian biểu diễn phong cách cô đọng*, tránh được hiện tượng quá khớp (overfitting) hoặc nhiễu loạn thông tin từ các mẫu âm dư thừa. Đặc biệt trên các tập dữ liệu chưa từng thấy (UFSC), cấu hình $K=4$ luôn duy trì vị thế dẫn đầu về chỉ số FID ở cả hai hướng chuyển đổi, chứng minh đây là *thiết lập tối ưu* để cân bằng giữa độ chính xác tái tạo và khả năng tổng quát hoá, đồng thời *giảm tải đáng kể chi phí huấn luyện*.

=== Ảnh hưởng của Alpha và Beta

Trong kiến trúc CL-SCR được đề xuất, hàm mất mát tổng thể được thiết lập dưới dạng tổng trọng số của hai thành phần: mất mát nội tại (Intra-Lingual loss) và mất mát chéo (Cross-Lingual loss), tuân theo công thức: $L_"CL-SCR" = alpha L_"intra" + beta L_"cross"$. Trong đó, $alpha$ điều chỉnh mức độ tập trung vào việc bảo toàn tính nhất quán phong cách trong cùng một ngôn ngữ, còn $beta$ kiểm soát lực ràng buộc để kéo các biểu diễn phong cách của hai ngôn ngữ lại gần nhau trong không gian đặc trưng. Để xác định tỷ lệ tối ưu giữa hai cơ chế này, khoá luận tiến hành khảo sát thực nghiệm với ba cấu hình trọng số đối ngẫu $(alpha, beta)$ lần lượt là $(0.3, 0.7)$, $(0.5, 0.5)$ và $(0.7, 0.3)$. Mục tiêu là phân tích sự đánh đổi giữa khả năng tái tạo chi tiết (do $alpha$ chi phối) và khả năng chuyển đổi phong cách liên ngôn ngữ (do $beta$ chi phối) trên cả hai chiều bài toán. Kết quả chi tiết được tổng hợp tại @tab:e2c_alp_beta và @tab:c2e_alp_beta.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [$alpha = 0.3, beta = 0.7$], [*0.1939*], [*0.3890*], [#underline[0.2911]], [11.7691],
    [$alpha = 0.5, beta = 0.5$], [0.1964], [#underline[0.3855]], [0.2934], [#underline[11.1352]],
    [$alpha = 0.7, beta = 0.3$], [#underline[0.1963]], [0.3827], [*0.2908*], [*10.3742*],

    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$alpha = 0.3, beta = 0.7$], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
    [$alpha = 0.5, beta = 0.5$], [0.2277], [0.3088], [0.3026], [15.1777],
    [$alpha = 0.7, beta = 0.3$], [#underline[0.2264]], [#underline[0.3095]], [#underline[0.2991]], [#underline[14.4760]],
    
  ),
  caption: [Ảnh hưởng của alpha và beta đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_alp_beta>


#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Phương pháp*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [$alpha = 0.3, beta = 0.7$], [#underline[0.1083]], [#underline[0.6406]], [#underline[0.2019]], [*14.7298*],
    [$alpha = 0.5, beta = 0.5$], [0.1099], [0.6392], [0.2051], [#underline[15.5683]],
    [$alpha = 0.7, beta = 0.3$], [*0.1072*], [*0.6432*], [*0.2002*], [16.3548],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$alpha = 0.3, beta = 0.7$], [#underline[0.1090]], [#underline[0.6377]], [#underline[0.1985]], [*41.1152*],
    [$alpha = 0.5, beta = 0.5$], [*0.1053*], [*0.6434*], [*0.1957*], [#underline[43.4240]],
    [$alpha = 0.7, beta = 0.3$], [0.1115], [0.6287], [0.2014], [45.2293],
  ),
  caption: [Ảnh hưởng của alpha và beta đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_alp_beta>

_*Nhận xét và Thảo luận*_:

#untab_para[
  Kết quả thực nghiệm cho thấy vai trò đối trọng thú vị giữa *tính nhất quán nội tại (Intra-Lingual)* và *sự ràng buộc xuyên ngôn ngữ (Cross-Lingual)*. Đối với hướng chuyển đổi từ Latin sang Hán tự (@tab:e2c_alp_beta), ta quan sát thấy sự đảo chiều về hiệu năng giữa kịch bản quen thuộc (SFUC) và kịch bản lạ (UFSC). Trên tập SFUC, cấu hình ưu tiên tính nội tại ($alpha=0.7, beta=0.3$) đạt kết quả FID tốt nhất (*10.37*), cho thấy khi phong cách đã biết, việc tập trung tinh chỉnh cấu trúc nội bộ của Hán tự giúp ảnh sinh sắc nét hơn. Tuy nhiên, trên tập kiểm thử khó UFSC, cấu hình ưu tiên liên kết chéo ($alpha=0.3, beta=0.7$) lại vượt trội với FID đạt *13.55* (so với *14.47* và *15.17*). Điều này gợi ý rằng để tổng quát hoá tốt trên các font chữ chưa từng thấy, mô hình cần dựa nhiều hơn vào "cầu nối" tương đồng giữa hai ngôn ngữ ($beta$) thay vì quá tập trung vào đặc trưng cục bộ của từng hệ chữ.
]

Xu hướng này trở nên nhất quán và rõ rệt hơn ở chiều ngược lại từ Hán tự sang Latin (@tab:c2e_alp_beta). Trong cả hai kịch bản SFUC và UFSC, việc gán trọng số cao cho thành phần Cross-Lingual ($beta=0.7$) đều mang lại hiệu suất FID tối ưu (*14.73* và *41.11*). Nguyên nhân có thể xuất phát từ *khoảng cách thông tin (information gap)*: Hán tự có cấu trúc phức tạp và giàu thông tin hơn nhiều so với Latin. Do đó, khi sinh chữ Latin từ nguồn Hán, mô hình cần một cơ chế ràng buộc xuyên ngôn ngữ mạnh mẽ ($beta$ lớn) để định hướng việc lọc bỏ các chi tiết thừa và ánh xạ chính xác phong cách, thay vì bị "sa lầy" vào việc học cấu trúc nội tại phức tạp của Hán tự ($alpha$). Kết quả này khẳng định rằng trong bài toán Cross-Lingual bất đối xứng, *tăng cường giám sát liên ngôn ngữ* là chìa khoá để cải thiện chất lượng sinh ảnh và độ tự nhiên thị giác.

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 8pt,
    inset: 6pt,
    stroke: none,
    align: (horizon, horizon),

    // ===== Header =====
    [], grid.vline(),
    [*Phương pháp*], grid.vline(),
    [*Example 1*], grid.vline(),
    [*Example 2*],

    // ===== UFSC e2c =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )],
    [$alpha = 0.3, beta = 0.7$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/p2_cross_both_a0.7_b0.3/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/p2_cross_both_a0.7_b0.3/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [$alpha = 0.5, beta = 0.5$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/p2_cross_both_a0.5_b0.5/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/p2_cross_both_a0.5_b0.5/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [$alpha = 0.7, beta = 0.3$],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    // ===== UFSC c2e =====
    grid.hline(),
    [#grid.cell(
      rowspan: 4,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )],
    [$alpha = 0.3, beta = 0.7$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/p2_cross_both_a0.7_b0.3/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/p2_cross_both_a0.7_b0.3/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [$alpha = 0.5, beta = 0.5$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/p2_cross_both_a0.5_b0.5/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/p2_cross_both_a0.5_b0.5/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [$alpha = 0.7, beta = 0.3$],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa các alpha và beta khác nhau \ trên tập dữ liệu chưa từng thấy cho cả hai hướng tác vụ (e2c và c2e).
  ]
) <tab:dinhtinh_alp_beta>

_*Kết luận*_: Tổng kết lại, thực nghiệm về trọng số $alpha$ và $beta$ đã chỉ ra sự bất đối xứng về nhu cầu giám sát của mô hình. Trong khi thành phần Intra-Lingual ($alpha$) chỉ thực sự phát huy tác dụng tối đa trong các kịch bản dữ liệu đã biết, thì thành phần *Cross-Lingual ($beta$) lại đóng vai trò chủ đạo* trong các tác vụ yêu cầu khả năng khái quát hoá cao hoặc chuyển đổi từ tập mẫu phức tạp sang đơn giản. Dựa trên kết quả này, khoá luận đề xuất cấu hình ưu tiên liên kết chéo ($alpha=0.3, beta=0.7$) là thiết lập mặc định cho mô hình cuối cùng, nhằm tối ưu hoá hiệu suất cho các ứng dụng thực tế nơi dữ liệu đầu vào thường xuyên biến đổi và chưa biết trước.

=== Ảnh hưởng của Trọng số hướng dẫn (Guidance Scale)

Trong cơ chế sinh ảnh của mô hình khuếch tán (Diffusion Models), *Trọng số hướng dẫn (Guidance Scale, $s$)* đóng vai trò như một "cần gạt" kiểm soát sự cân bằng giữa độ đa dạng của ảnh sinh và độ bám sát vào điều kiện đầu vào (content/style). Theo nguyên lý của phương pháp Classifier-free Guidance@JonathanGuidance được áp dụng trong FontDiffuser, công thức cập nhật mẫu là: $ epsilon.alt_"pred" = epsilon.alt_"uncond" + s (epsilon.alt_"cond" - epsilon.alt_"uncond") $
Về mặt lý thuyết, việc tăng giá trị $s$ sẽ ép buộc mô hình tuân thủ chặt chẽ hơn các đặc trưng phong cách mục tiêu, nhưng nếu $s$ quá lớn sẽ dẫn đến hiện tượng bão hoà (saturation) và xuất hiện các chi tiết giả (artifacts). Để tìm ra "điểm ngọt" (sweet spot) cho tác vụ sinh font chữ, khoá luận thực hiện khảo sát với giải giá trị $s$ chạy từ $2.5$ đến $15$.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Trọng số \ hướng dẫn*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [2.5], [0.1982], [0.3812], [0.2957], [14.1162],
    [5], [0.1955], [0.3861], [0.2922], [12.8616],
    [7.5], [0.1939], [0.3890], [*0.2911*], [#underline[11.7691]],
    [10], [0.1932], [*0.3894*], [#underline[0.2921]], [*11.5753*],
    [12.5], [*0.1927*], [#underline[0.3893]], [0.2936], [12.3513],
    [15], [#underline[0.1929]], [0.3874], [0.2971], [14.1336],

    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$2.5$], [0.2262], [0.3096], [0.2985], [*13.2760*],
    [5], [0.2229], [0.3176], [#underline[0.2955]], [#underline[13.3922]],
    [7.5], [0.2214], [*0.3197*], [*0.2954*], [13.5508],
    [10], [0.2209], [#underline[0.3194]], [0.2970], [13.7769],
    [12.5], [#underline[0.2207]], [0.3187], [0.2991], [14.7846],
    [15], [*0.2204*], [0.3185], [0.3025], [17.0116],
    
  ),
  caption: [Ảnh hưởng của trọng số hướng dẫn đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_guidance>


#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    inset: 10pt,
    align: center,
    stroke: none,
    table.header(
      [], [*Trọng số \ hướng dẫn*], [*L1 $arrow.b$*], [*SSIM $arrow.t$*], [*LPIPS $arrow.b$*], [*FID $arrow.b$*],
    ),

    table.hline(),
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *SFUC*
      ],
    ),
    [$2.5$], [0.1108], [0.6369], [0.2027], [*12.3777*],
    [5], [0.1093], [0.6395], [*0.2010*], [#underline[13.3989]],
    [7.5], [0.1083], [#underline[0.6406]], [#underline[0.2019]], [14.7298],
    [10], [0.1075], [*0.6408*], [0.2038], [16.4067],
    [12.5], [#underline[0.1070]], [0.6402], [0.2077], [19.7855],
    [15], [*0.1069*], [0.6385], [0.2129], [24.2096],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 6,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$2.5$], [0.1096], [0.6352], [0.2002], [#underline[40.0501]],
    [5], [0.1060], [0.6418], [*0.1944*], [*40.0024*],
    [7.5], [0.1090], [0.6377], [0.1985], [41.1152],
    [10], [0.1070], [0.6391], [0.2014], [44.7385],
    [12.5], [*0.1025*], [*0.6477*], [#underline[0.1976]], [47.1480],
    [15], [#underline[0.1031]], [#underline[0.6426]], [0.2045], [52.7596],
  ),
  caption: [Ảnh hưởng của trọng số hướng dẫn đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_guidance>

_*Nhận xét và Thảo luận*_:

#untab_para[
  Kết quả thực nghiệm tại hai bảng trên cho thấy một xu hướng *nhạy cảm ngược chiều* so với các tác vụ sinh ảnh thông thường (nơi $s$ thường được đặt quanh mức 7.5). Cụ thể, trong tác vụ Latin sang Hán tự (@tab:e2c_guidance), các chỉ số chất lượng đạt đỉnh ở mức guidance scale trung bình thấp. Trên tập dữ liệu đã biết (SFUC), giá trị FID tối ưu nằm tại ngưỡng $s=10$ (11.57), tuy nhiên sự chênh lệch so với $s=7.5$ là không đáng kể. Đáng chú ý, khi chuyển sang tập dữ liệu lạ (UFSC), việc giữ guidance scale ở mức thấp ($2.5 - 7.5$) giúp duy trì chỉ số FID ổn định nhất (quanh mức 13.5), trong khi việc tăng $s$ lên 15 khiến chất lượng ảnh suy giảm rõ rệt (FID tăng vọt lên 17.01). Điều này gợi ý rằng đối với các cấu trúc phức tạp như Hán tự, việc cưỡng ép mô hình quá mức bằng guidance scale cao sẽ làm mất đi tính tự nhiên của nét bút.
]

Hiện tượng này càng trở nên cực đoan hơn ở chiều ngược lại từ Hán tự sang Latin (@tab:c2e_guidance). Dữ liệu chỉ ra rằng mô hình đạt hiệu suất tốt nhất tại các mức guidance scale *rất thấp ($s=2.5$ hoặc $s=5$)*. Trên tập UFSC, cấu hình $s=5$ đạt FID tốt nhất là *40.00*, trong khi việc tăng $s$ lên 15 khiến chỉ số này tệ đi gần 30% (lên mức 52.75). Nguyên nhân cốt lõi nằm ở việc không gian phong cách của Hán tự dày đặc hơn rất nhiều so với Latin. Khi sử dụng guidance scale lớn để ép các đặc trưng phong cách phong phú của Hán tự vào khung xương đơn giản của chữ Latin, mô hình dễ sinh ra các nhiễu (artifacts) hoặc biến dạng cấu trúc không mong muốn. Các chỉ số về cấu trúc như SSIM và L1 cũng đồng thuận với nhận định này khi đạt giá trị tối ưu ở ngưỡng thấp ($s <= 7.5$).

#pagebreak()
#figure(
  kind: table,
  grid(
    columns: (40pt, auto, auto, auto),
    // gutter: 8pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== Header =====
    [], grid.vline(),
    [*Trọng số \ hướng dẫn*], grid.vline(),
    [*Example 1*], grid.vline(),
    [*Example 2*],

    // ===== UFSC e2c =====
    grid.hline(),
    [#grid.cell(
      rowspan: 7,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`e2c`)],
    )],
    [2.5],
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G2.5/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G2.5/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [5],
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G5.0/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G5.0/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [7.5],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [10],
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G10/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G10/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [12.5],
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G12.5/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G12.5/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [15],
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G15/",
      "Free letter fonts Font-Simplified Chinese",
      "generated"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/UFSC_G15/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Free letter fonts Font-Simplified Chinese",
      "gt"
    ),
    glyph-grid(
      s1,
      "../result_image/eng_chi/AZ/style/p2_neg04/",
      "Zoomla Small Handwriting Chinese Font – Simplified Chinese Fonts",
      "gt"
    ),

    // ===== UFSC c2e =====
    grid.hline(),grid.hline(),
    [#grid.cell(
      rowspan: 7,
      align: horizon,
      rotate(-90deg, reflow: true)[*UFSC* (`c2e`)],
    )],
    [2.5],
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G2.5/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G2.5/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [5],
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G5.0/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G5.0/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [7.5],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [10],
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G10/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G10/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [12.5],
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G12.5/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G12.5/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [15],
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G15/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "generated"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/UFSC_G15/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "generated"
    ),

    [*Target*],
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Benmo Robust Bold Elegant Chinese Font -Simplified Chinese Fonts",
      "gt"
    ),
    glyph-grid(
      s2,
      "../result_image/chi_eng/all/style/p2_neg04/",
      "Font housekeeper impression Chinese Font-Simplified Chinese",
      "gt"
    ),
  ),

  caption: [So sánh kết quả sinh ảnh giữa các trọng số hướng dẫn khác nhau \ trên tập dữ liệu chưa từng thấy cho cả hai hướng tác vụ (e2c và c2e).
  ]
) <tab:dinhtinh_guidance>

_*Kết luận*_: Tổng kết lại, thực nghiệm khẳng định rằng *Trọng số hướng dẫn thấp đến trung bình* là lựa chọn tối ưu cho bài toán chuyển đổi font chữ đa ngôn ngữ. Khác với các mô hình tạo sinh nghệ thuật cần $s$ cao để đảm bảo đúng prompt, FontDiffuser hoạt động hiệu quả nhất khi $s$ nằm trong khoảng $[2.5, 7.5]$. Việc thiết lập giá trị này giúp mô hình cân bằng tốt nhất giữa việc chuyển tải phong cách và bảo toàn cấu trúc hình học, tránh được các biến dạng do quá khớp (over-exposure). Dựa trên sự ổn định qua các kịch bản thử nghiệm, khoá luận đề xuất thiết lập mặc định $s=7.5$ cho chiều Latin-Hán (để cân bằng độ nét) và $s=5.0$ cho chiều Hán-Latin (để đảm bảo độ tự nhiên).

#pagebreak()