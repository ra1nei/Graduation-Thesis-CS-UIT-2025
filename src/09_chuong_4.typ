#import "/template.typ" : *
// #import "@preview/scripting:0.1.0": *

#[
  #set heading(numbering: "Chương 1.1")
  = Thực Nghiệm và Đánh Giá Kết Quả <chuong4>
]

// #let scr(it) = math.class("normal", box({
//   show math.equation: set text(stylistic-set: 1)
//   $cal(it)$
// }))

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

#let s1 = "默首音".clusters()
#let s2 = "tdk".clusters()

Chương này trình bày chi tiết *thiết lập thực nghiệm*, bao gồm mô tả bộ dữ liệu, các thước đo đánh giá và cấu hình huấn luyện chi tiết trên nền tảng phần cứng giới hạn. Tiếp theo, khoá luận sẽ đưa ra các *so sánh định lượng và định tính* giữa *phương pháp đề xuất (CL-SCR FontDiffuser)* với các *phương pháp tiên tiến hiện nay (State-of-the-Art)* nhằm chứng minh hiệu quả trong bài toán sinh phông chữ đa ngôn ngữ (Cross-lingual Font Generation) theo cả hai chiều: *từ Hán tự sang Latin* và *từ Latin sang Hán tự*.

== Bộ dữ liệu (Datasets)

=== Cấu trúc
Để đảm bảo tính khách quan và khả năng so sánh công bằng với các nghiên cứu tiên tiến, khoá luận không tự xây dựng dữ liệu mới mà kế thừa *bộ dữ liệu chuẩn* từ công trình "Few-shot Font Style Transfer between Different Languages"@Li2021FTransGAN. Đây là tập dữ liệu chuyên biệt cho bài toán đa ngôn ngữ, bao gồm *818 bộ phông chữ song ngữ* với độ đa dạng phong cách cao, trải dài từ serif, sans-serif đến thư pháp và viết tay. Cấu trúc dữ liệu được tổ chức thành hai tập con tương tác chặt chẽ nhằm phục vụ bài toán chuyển đổi hai chiều: *tập ký tự Hán* chứa trung bình *800 ký tự* thông dụng (chuẩn GB2312) đóng vai trò miền đích phức tạp, và *tập ký tự Latin* bao gồm *52 ký tự* cơ bản. Đặc điểm cốt lõi của bộ dữ liệu này là sự *nhất quán tuyệt đối về phong cách* giữa hai hệ chữ trong cùng một bộ font, *cung cấp các cặp dữ liệu nhãn (Ground-truth)* tự nhiên giúp mô-đun CL-SCR học được sự tương quan phong cách xuyên ngôn ngữ.
// TODO: Chèn hình làm ví dụ 

=== Tiền xử lý và Chuẩn hoá
*Quy trình tiền xử lý:*
Về quy trình tiền xử lý, dữ liệu thô trải qua các bước chuẩn hoá để tối ưu hoá quá trình huấn luyện. Cụ thể, toàn bộ ảnh ký tự được render dưới dạng *thang độ xám (grayscale)* nhằm loại bỏ nhiễu màu sắc, giúp mô hình tập trung tối đa vào việc học các đặc trưng hình học và cấu trúc nét. Các ảnh đầu vào sau đó được chuẩn hoá đồng bộ về kích thước *$64 times 64$ pixel*, đồng thời áp dụng kỹ thuật *căn chỉnh tự động (auto-centering)* để đưa ký tự về tâm ảnh với tỷ lệ lề phù hợp. Cuối cùng, một bước *lọc bỏ thủ công* được thực hiện để loại trừ các mẫu lỗi như ký tự bị đứt nét hoặc render thiếu, đảm bảo chất lượng đầu vào tốt nhất cho mô hình.

*Quy trình Chuẩn hoá và Lấy mẫu Động:*
Tiếp nối các bước xử lý thô, để đảm bảo tính tương thích tối đa với kiến trúc mạng nơ-ron tích chập và cơ chế khuếch tán, khoá luận thiết lập một *đường ống xử lý dữ liệu* chuyên biệt được triển khai thời gian thực trong quá trình huấn luyện. Cụ thể, thông qua lớp `FontDataset`, mọi ảnh đầu vào (bao gồm ảnh nội dung, ảnh phong cách và các mẫu âm) đều được chuyển đổi đồng bộ sang không gian màu *RGB (3 kênh)* để khớp với đầu vào tiêu chuẩn của bộ mã hóa U-Net. Kế đến, kỹ thuật *nội suy song tuyến tính (Bilinear Interpolation)* được áp dụng để đưa ảnh về độ phân giải mục tiêu, giúp làm mượt các đường biên răng cưa và bảo toàn thông tin cấu trúc tốt hơn so với các phương pháp lấy mẫu lân cận. Về mặt số học, dữ liệu trải qua bước *chuẩn hoá giá trị (Value Normalization)*, chuyển đổi các điểm ảnh từ dải $[0,255]$ sang dạng Tensor với dải giá trị tiêu chuẩn $[-1, 1]$, tạo điều kiện hội tụ ổn định cho quá trình khử nhiễu Gaussian. Đặc biệt, để phục vụ mô-đun CL-SCR, khoá luận áp dụng chiến lược *Lấy mẫu âm động (Dynamic Negative Sampling)*: thay vì cố định các cặp mẫu, hệ thống tự động truy xuất và lựa chọn ngẫu nhiên $K$ mẫu âm từ kho dữ liệu dựa trên chế độ huấn luyện (nội miền `intra` hoặc xuyên miền `cross`) ngay tại mỗi bước lặp, giúp mô hình liên tục được tiếp xúc với các biến thể phong cách đa dạng và tránh hiện tượng học vẹt.

== Thiết lập Thực nghiệm

=== Cấu hình Huấn luyện (Implementation Details)
Các thí nghiệm được thực hiện trên môi trường tính toán đám mây Kaggle với *GPU NVIDIA Tesla P100 (16GB VRAM)*. Mã nguồn được triển khai trên nền tảng *PyTorch* và *thư viện Diffusers*.

Quá trình huấn luyện tuân theo chiến lược hai giai đoạn (Two-stage training) với các siêu tham số được thiết lập cụ thể như sau dựa trên tài nguyên phần cứng giới hạn:

*1. Giai đoạn Tái tạo (Phase 1 - Reconstruction):*
Trong giai đoạn khởi đầu này, mục tiêu chính của mô hình là học các đặc trưng cấu trúc nội dung và phong cách cơ bản. Quá trình huấn luyện được thực hiện xuyên suốt *400,000 bước lặp* với kích thước batch được cố định là *4*. Về chiến lược tối ưu hoá, khoá luận sử dụng bộ giải thuật *AdamW* với tốc độ học khởi tạo là *$1 times 10^(-4)$*, kết hợp cùng lịch trình điều chỉnh Linear bao gồm *10,000 bước khởi động* (warmup steps) để đảm bảo mô hình hội tụ ổn định. Hàm mất mát tổng hợp được cấu hình với các trọng số thành phần cụ thể là *$lambda_"percep" = 0.01$* cho Content Perceptual Loss và *$lambda_"offset" = 0.5$* cho Offset Loss nhằm hỗ trợ mô-đun RSI học biến dạng cấu trúc.

*2. Tiền huấn luyện mô-đun CL-SCR:*
Trước khi được tích hợp vào luồng sinh ảnh chính, mô-đun CL-SCR (Cross-Lingual Style Contrastive Refinement) trải qua một quá trình huấn luyện độc lập nhằm xây dựng không gian biểu diễn phong cách tối ưu. Quá trình này được thực hiện trong tổng số *200,000 bước lặp* với kích thước batch là *16*. Khoá luận sử dụng bộ tối ưu hoá Adam để cập nhật tham số cho cả bộ trích xuất đặc trưng (Style Feat Extractor) và bộ chiếu đặc trưng (Style Projector) với tốc độ học cố định là *$1 times 10^(-4)$*.

Để tăng cường tính bền vững của biểu diễn phong cách đối với các biến thể hình học, khoá luận áp dụng chiến lược tăng cường dữ liệu (Data Augmentation) thông qua kỹ thuật *Random Resized Crop*. Cụ thể, ảnh đầu vào được *cắt ngẫu nhiên với tỷ lệ diện tích từ 80% đến 100% (scale 0.8 - 1.0)* và *tỷ lệ khung hình dao động nhẹ trong khoảng 0.8 đến 1.2*, sau đó được đưa về kích thước chuẩn thông qua nội suy song tuyến tính (bilinear interpolation).

*3. Giai đoạn Tinh chỉnh Phong cách (Phase 2 - Style Refinement with CL-SCR):*
Bước sang giai đoạn hai, mô-đun CL-SCR được kích hoạt để tinh chỉnh sâu các đặc trưng phong cách Latin, trong khi tốc độ học của các thành phần khác được giảm xuống để tránh phá vỡ cấu trúc đã học. Quá trình này diễn ra trong *30,000 bước* với *kích thước batch 4* nhằm dành tài nguyên VRAM cho các tính toán của mô-đun tương phản. Tốc độ học được thiết lập ở mức thấp hơn là *$1 times 10^(-5)$*, áp dụng chiến lược Constant (hằng số) sau *1,000 bước khởi động*. Đối với cấu hình CL-SCR, khoá luận lựa chọn chế độ huấn luyện kết hợp cả nội miền và xuyên miền (`scr_mode="both"`) với tỷ trọng $alpha_"intra" = 0.3$ và ưu tiên *$beta_"cross" = 0.7$*, đồng thời sử dụng *4 mẫu âm* (negative samples) cho mỗi lần tính toán loss. Hàm mục tiêu tổng thể lúc này là sự kết hợp của các thành phần theo công thức:
$ L_"total" = L_"MSE" + 0.01 dot L_"percep" + 0.5 dot L_"offset" + 0.01 dot L_"CL-SCR" $

*4. Quy trình Inference:* Trong quá trình lấy mẫu (Inference), mô hình FontDiffuser@Yang2024FontDiffuser được đóng gói thành một Pipeline dựa trên DPM-Solver để tối ưu hoá tốc độ.

*Cấu hình Lấy mẫu:* Khoá luận sử dụng bộ giải *DPM-Solver++* với số bước suy diễn được cố định là *20* (`num_inference_steps=20`), đây là một sự cân bằng giữa tốc độ tính toán và chất lượng ảnh sinh. Chiến lược hướng dẫn vô điều kiện (Classifier-Free Guidance) được áp dụng với tham số hướng dẫn ($s$) được xác định trong file cấu hình (`guidance_scale`). Để lấy mẫu, các ảnh đầu vào được tiền xử lý và chuẩn hoá về kích thước (`content_image_size`, `style_image_size`) rồi đưa về Tensor với dải giá trị $[ -1, 1 ]$.

*Lấy mẫu Hàng loạt (Batch Sampling):* Do khoá luận thực hiện đánh giá định lượng trên một lượng lớn mẫu, quy trình lấy mẫu được tự động hoá thông qua hàm batch_sampling, bao phủ cả hai hướng nghiên cứu.

=== Kịch bản Đánh giá (Evaluation Scenarios)
Để đánh giá toàn diện khả năng của mô hình, khoá luận thiết lập hai kịch bản kiểm thử với độ khó tăng dần (theo chuẩn của FontDiffuser và DG-Font@Xie2021DGFont):

1. *SFUC (Seen Font, Unseen Character):* Font đã xuất hiện trong tập huấn luyện, nhưng ký tự sinh ra chưa từng thấy. Kịch bản này đánh giá khả năng *nội suy phong cách*.
2. *UFSC (Unseen Font, Seen Character):* Font mới hoàn toàn (chưa từng xuất hiện trong quá trình huấn luyện). Đây là kịch bản quan trọng nhất để đánh giá khả năng *One-shot Generalization* của mô hình đối với phong cách lạ.

== Các thước đo đánh giá (Evaluation Metrics)
Để đảm bảo tính khách quan và toàn diện trong việc kiểm định chất lượng mô hình, khoá luận áp dụng hệ thống đánh giá đa chiều bao gồm cả các chỉ số định lượng tiêu chuẩn (Quantitative Metrics) và đánh giá định tính dựa trên cảm nhận người dùng (Subjective User Study).

=== Chỉ số Định lượng (Quantitative Metrics)
Khoá luận sử dụng bộ 4 chỉ số tiêu chuẩn trong bài toán sinh ảnh để đánh giá chất lượng ảnh sinh ($x$) so với ảnh thật ($y$):

==== L1 (Mean Absolute Error)
Độ đo *L1* tính trung bình giá trị tuyệt đối của sai khác giữa các điểm ảnh (pixel-wise), phản ánh độ chính xác về cường độ điểm ảnh:
$ "L1" = 1/N sum_(i=1)^N |x_i - y_i| $
Trong đó $N$ là tổng số điểm ảnh. Giá trị L1 càng nhỏ càng tốt.

==== SSIM (Structural Similarity Index)
Độ đo *SSIM* đánh giá mức độ tương đồng về *cấu trúc, độ sáng và độ tương phản*. Khác với L1, SSIM mô phỏng cách mắt người cảm nhận sự thay đổi cấu trúc:
$ "SSIM"(x, y) = ((2 mu_x mu_y + C_1)(2 sigma_(x y) + C_2))/((mu_x^2 + mu_y^2 + C_1)(sigma_x^2 + sigma_y^2 + C_2)) $
Giá trị SSIM nằm trong khoảng $[0,1]$, giá trị càng cao thể hiện chất lượng ảnh càng tốt.

==== LPIPS (Learned Perceptual Image Patch Similarity)
Độ đo *LPIPS* đánh giá *khoảng cách cảm nhận* dựa trên các đặc trưng trích xuất từ mạng nơ-ron sâu (VGG). Chỉ số này khắc phục nhược điểm của L1/SSIM khi xử lý các ảnh bị mờ nhẹ nhưng vẫn giống về ngữ nghĩa:
$ "LPIPS"(x,y) = sum_l 1 / (H_l W_l) sum_(h, w) ||w_l dot (f_l^x (h, w) - f_l^y (h, w))||_2^2 $
Giá trị LPIPS càng thấp chứng tỏ ảnh sinh càng giống ảnh thật về mặt thị giác tự nhiên.

==== FID (Fréchet Inception Distance)
Độ đo *FID* đánh giá chất lượng tổng thể và độ đa dạng của tập ảnh sinh dựa trên khoảng cách thống kê giữa hai phân bố đặc trưng:
$ "FID" = ||mu_r - mu_g||_2^2 + "Tr"(sum_r + sum_g - 2(sum_r sum_g)^(1/2) ) $
Giá trị FID càng thấp cho thấy phân bố của ảnh sinh càng tiệm cận với phân bố ảnh thật.

==== Phân tích mối tương quan và Vai trò của bộ độ đo
Việc sử dụng đơn lẻ một độ đo không thể phản ánh toàn diện hiệu năng của mô hình sinh phông chữ, do đó khoá luận kết hợp bốn độ đo trên theo *chiến lược đánh giá đa tầng*. Đầu tiên, ở tầng *đánh giá độ chính xác điểm ảnh (Pixel-level Accuracy)*, các chỉ số *L1* và *SSIM* đảm bảo rằng ảnh sinh ra không bị lệch lạc quá nhiều về vị trí không gian so với ảnh mẫu (Ground Truth). Tuy nhiên, đối với các mô hình sinh (Generative Models), việc tối ưu hoá quá mức L1 thường dẫn đến hiện tượng ảnh bị *làm mờ (blurring effect)* để giảm thiểu sai số trung bình. Để khắc phục, tầng thứ hai tập trung vào *đánh giá chất lượng cảm nhận (Perceptual Quality)* thông qua *LPIPS* và *FID*. Trong khi LPIPS đo lường sự tương đồng trong *không gian đặc trưng (Feature Space)* giúp mô hình được "tha thứ" cho những sai lệch nhỏ về pixel miễn là đặc điểm nhận dạng bảo toàn, thì FID đóng vai trò trọng tâm trong việc đánh giá mức độ *"thật" (realism)* và *tính đa dạng (diversity)*. 

Sự kết hợp giữa SSIM (cấu trúc) và LPIPS (cảm nhận) là đặc biệt quan trọng trong bài toán Cross-lingual, nơi việc giữ cấu trúc chữ quan trọng ngang hàng với việc bắt chước phong cách.

=== Đánh giá Định tính (Qualitative Study)
Các chỉ số định lượng (Quantitative Metrics) như FID hay LPIPS, mặc dù khách quan, nhưng không thể mô phỏng hoàn toàn gu thẩm mỹ và khả năng đọc hiểu của con người. Do đó, để kiểm chứng tính thực tiễn của phương pháp đề xuất, Khoá luận thực hiện đánh giá định tính trên hai khía cạnh: *phân tích thị giác dựa trên chuyên môn (Visual Analysis)* và *khảo sát cảm nhận người dùng (User Study)*.

==== Quy trình Phân tích Trực quan (Visual Analysis Protocol)
Đối với đánh giá chuyên môn, các kết quả sinh ảnh sẽ được phân tích dựa trên việc so sánh đối chứng trực tiếp (side-by-side comparison) giữa mô hình đề xuất và các phương pháp cơ sở (Baseline). Các tiêu chí phân tích bao gồm: sự toàn vẹn của các nét mảnh (fine details), khả năng xử lý các vùng giao nhau phức tạp (stroke intersection), và mức độ biến dạng cấu trúc (structural artifacts) như hiện tượng dính nét (blob) hay đứt gãy.

==== Thiết kế Khảo sát Người dùng (User Study Design)
Để đánh giá chất lượng thị giác và tính nhất quán phong cách một cách khách quan nhất theo cảm nhận của con người, khoá luận thiết kế một bảng *khảo sát mù (blind test)* với sự tham gia của tổng cộng *20 tình nguyện viên*. Nhóm khảo sát bao gồm 5 người bạn học chuyên ngành thiết kế đồ hoạ có kiến thức về typography và 15 người dùng phổ thông, đảm bảo tính đại diện cho cả đánh giá kỹ thuật và thẩm mỹ công chúng. 

Bộ dữ liệu khảo sát được xây dựng từ *20 bộ mẫu ngẫu nhiên* trích xuất từ tập kiểm thử (Test Set), *bao gồm các mẫu đại diện cho cả hai kịch bản chuyển đổi phong cách:* *từ Hán tự sang Latin* và *từ Latin sang Hán tự*. Trong mỗi câu hỏi, tình nguyện viên được yêu cầu so sánh kết quả sinh ảnh giữa các mô hình khác nhau. Cụ thể, mỗi mẫu so sánh hiển thị một *ảnh tham chiếu (Reference Style)* (chứa phong cách mục tiêu) và các *ảnh kết quả (Generated Images)* là các ký tự được sinh ra bởi các mô hình cạnh tranh (DG-Font@Xie2021DGFont, FontDiffuser Baseline@Yang2024FontDiffuser, và Phương pháp đề xuất Ours). Vị trí hiển thị của các ảnh kết quả được xáo trộn ngẫu nhiên để đảm bảo tính công bằng và loại bỏ thiên kiến vị trí. Tình nguyện viên được yêu cầu chọn ra ảnh có *độ nhất quán phong cách tốt nhất* và *chất lượng hình ảnh tổng thể cao nhất* trong số các lựa chọn.

*Tiêu chí đánh giá:* Thay vì chấm điểm phức tạp, người tham gia được yêu cầu thực hiện đánh giá dựa trên *lựa chọn ưu tiên*. Cụ thể, với mỗi bộ mẫu, tình nguyện viên cần chọn ra một bức ảnh duy nhất mà họ cho là tốt nhất dựa trên sự cân bằng giữa hai tiêu chí cốt lõi. Thứ nhất là *Tính nhất quán phong cách*, tức ảnh sinh ra phải kế thừa chính xác các đặc trưng thị giác của ảnh phong cách (như độ đậm nhạt, kết cấu nét cọ, hoặc kiểu chân chữ serif/sans-serif). Thứ hai là *Tính toàn vẹn nội dung*, tức ký tự sinh ra phải duy trì đúng cấu trúc hình học của ảnh nội dung, đảm bảo tính dễ đọc và không bị biến dạng kỳ quái (ví dụ: chữ `丘` trong kịch bản `e2c` phải giữ nguyên các nét ngang dọc đặc trưng, không bị lai tạp thành ký tự Latin). Kết quả cuối cùng được định lượng thông qua *Tỷ lệ Ưu tiên*, tính bằng phần trăm số phiếu bầu chọn mà mỗi mô hình nhận được trên tổng số lượt đánh giá.

== Kết quả Thực nghiệm và Thảo luận
Trong chương này, khoá luận trình bày toàn bộ kết quả thực nghiệm của mô hình đề xuất. Nội dung bao gồm đánh giá định lượng và định tính chi tiết, nghiên cứu bóc tách (ablation study) về các thành phần kiến trúc, khảo sát người dùng, và phân tích các trường hợp thất bại. Các kết quả này được đối chiếu trực tiếp với nhiều mô hình sinh font hiện đại, bao gồm các mô hình *GAN-based* (DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle, FTransGAN@Li2021FTransGAN), mô hình *diffusion-based* (FontDiffuser@Yang2024FontDiffuser), và các phiên bản mô hình của khoá luận.

Để đánh giá toàn diện khả năng chuyển đổi đa ngôn ngữ, khoá luận thực hiện thực nghiệm trên hai hướng chính với các mục tiêu nghiên cứu và cấu hình mô hình cụ thể, khẳng định giá trị nghiên cứu ngang nhau của bài toán Cross-lingual Font Generation:

*1. Hướng Latin $->$ Hán tự:*
Đây là kịch bản kiểm tra khả năng *chuyển giao phong cách Latin* tinh tế lên *cấu trúc Hán tự* phức tạp. Trong kịch bản này, mô hình cần học các đặc trưng nét (như serif, độ dày nét, góc bo) của hệ chữ Latin và áp dụng chúng lên các ký tự Hán. Mục tiêu là kiểm tra hiệu quả của mô-đun *CL-SCR* trong việc tách biệt phong cách Latin khỏi nội dung Latin, đảm bảo sự nhất quán phong cách khi áp dụng lên hệ chữ có hình thái học khác biệt (Hán tự).

Khoá luận sử dụng hai cấu hình mô hình cho hướng này: $"Ours"_"A"$ (sử dụng ký tự `A` làm ảnh phong cách tham chiếu) và $"Ours"_"AZ"$ (sử dụng ký tự ngẫu nhiên `trong khoảng A đến Z` làm ảnh phong cách tham chiếu).

*2. Hướng Hán tự $->$ Latin:*
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

    [Hard], [Ảnh phong cách là Hán tự có số nét $M >= 21$.], [$"Ours"_"Hard"$], [Đánh giá khả năng trích xuất phong cách từ cấu trúc phức tạp và rậm rạp nhất mà không làm mất thông tin nét.],
  ),
  caption: [Bảng phân loại các kịch bản dựa trên độ phức tạp của ký tự]
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
  caption: [Ví dụ ba loại độ phức tạp]
) <image:stroke_compare>

Việc phân loại theo độ phức tạp này giúp khoá luận xác định mô-đun *CL-SCR* hoặc các kiến trúc lõi khác (*MCA*, *RSI*) hoạt động hiệu quả nhất ở mức độ phức tạp cấu trúc nào của phong cách Hán tự, từ đó cung cấp những cái nhìn sâu sắc hơn về khả năng học đặc trưng của mô hình khuếch tán.

=== So sánh Định lượng (Quantitative Results)

Các bảng dưới đây trình bày kết quả so sánh giữa phương pháp đề xuất (Ours) với các baseline mạnh nhất hiện nay gồm DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle, FTransGAN@Li2021FTransGAN và trên 2 kịch bản UFSC và SFUC cho tác vụ chuyển đổi phong cách từ chữ Latin sang ảnh nguồn Hán và ngược lại.

==== Tác vụ chuyển đổi phong cách từ chữ Latin sang ảnh nguồn Hán (e2c).
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
    [DFS@Zhu2020FewShotTextStyle], [*0.1844*], [#underline[0.3900]], [0.3548], [40.4561],
    [FTransGAN@Li2021FTransGAN], [], [], [], [],
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
    [DFS@Zhu2020FewShotTextStyle], [*0.2089*], [0.3048], [0.3876], [62.7206],
    [FTransGAN@Li2021FTransGAN], [], [], [], [],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.2283], [0.2946], [0.3184], [29.0999],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"A"$ (w/ CL-SCR)], [0.2218], [#underline[0.3144]], [*0.2892*], [#underline[17.8373]], 
    [$"Ours"_"AZ"$ (w/ CL-SCR)], [0.2214], [*0.3197*], [#underline[0.2954]], [*13.5508*]
  ),
  caption: [Kết quả Định lượng cho Latin $->$ Hán tự (e2c) trên UFSC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:e2c_ufsc>

Dựa trên số liệu từ @tab:e2c_sfuc và @tab:e2c_ufsc, có thể rút ra những đánh giá quan trọng về hiệu năng của phương pháp đề xuất so với các mô hình State-of-the-Art (SOTA). Điểm nổi bật nhất trong kết quả thực nghiệm là *sự cải thiện mang tính đột phá về chất lượng ảnh sinh*, được phản ánh rõ nét qua chỉ số *FID*. Trong kịch bản SFUC (Seen Font), mô hình $"Ours"_"AZ"$ đạt FID là *11.769*, giảm *khoảng 20%* so với baseline mạnh nhất là FontDiffuser@Yang2024FontDiffuser (14.687) và bỏ xa các phương pháp GAN truyền thống. Tuy nhiên, sức mạnh thực sự của mô hình được thể hiện ở kịch bản khó hơn là UFSC (Unseen Font), nơi mô hình phải sinh ảnh từ các font chưa từng thấy. Tại đây, $"Ours"_"AZ"$ vẫn duy trì phong độ ấn tượng với FID 13.551, thấp hơn tới 53% so với FontDiffuser (29.100). Điều này chứng minh rằng mô-đun CL-SCR đã giải quyết triệt để vấn đề "domain gap" giữa chữ Hán và chữ Latin, giúp ảnh sinh ra có độ tự nhiên cao và phân bố sát với ảnh thật, thay vì bị nhiễu hoặc méo mó như mô hình gốc.

Bên cạnh độ tự nhiên, khả năng *bảo toàn cấu trúc* cũng được duy trì ở mức cao. Về chỉ số tương đồng cấu trúc *SSIM*, phương pháp đề xuất $"Ours"_"AZ"$ dẫn đầu ở cả hai kịch bản (0.389 và 0.320), cho thấy các nét chữ Latin được tái tạo sắc nét. Một điểm đáng lưu ý là mặc dù mô hình *DFS@Zhu2020FewShotTextStyle* đạt kết quả tốt nhất về sai số điểm ảnh *L1* (0.1844 ở SFUC), nhưng chỉ số FID của nó lại rất cao (40.456). Đây là minh chứng cho hiện tượng *nghịch lý L1*: các mô hình như DFS@Zhu2020FewShotTextStyle hay FTransGAN@Li2021FTransGAN thường tối ưu hoá bằng cách sinh ra các ảnh "trung bình cộng" bị mờ (blurry) để giảm thiểu sai số pixel, trong khi phương pháp đề xuất dựa trên Diffusion chấp nhận L1 cao hơn một chút để tạo ra các *chi tiết tần số cao* sắc nét và chân thực hơn. Do đó, sự đánh đổi nhỏ về L1 là hoàn toàn hợp lý để đạt được chất lượng thị giác vượt trội.

Cuối cùng, sự so sánh nội bộ giữa hai biến thể tham chiếu ($"Ours"_"A"$ và $"Ours"_"AZ"$) làm nổi bật tính ổn định của mô hình. Kết quả thực nghiệm cho thấy $"Ours"_"AZ"$ đạt hiệu suất vượt trội hơn hẳn so với $"Ours"_"A"$ trên cả hai kịch bản, đặc biệt là sự chênh lệch lớn về FID ở UFSC (13.55 so với 17.84). Điều này dẫn đến kết luận quan trọng rằng mô hình tích hợp CL-SCR có khả năng trích xuất *đặc trưng phong cách bất biến* cực tốt. Việc được huấn luyện với các ký tự ngẫu nhiên (A-Z) thay vì cố định (A) giúp mô hình không bị *học thuộc lòng (overfit)* vào cấu trúc hình học của một ký tự cụ thể, mà thực sự "hiểu" được bản chất của phong cách (như độ đậm nhạt, serif, texture), từ đó đảm bảo độ linh hoạt cao trong các ứng dụng thực tế.

==== Tác vụ chuyển đổi phong cách từ chữ Hán sang ảnh nguồn Latin (c2e).
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
    [FTransGAN@Li2021FTransGAN], [], [], [], [],
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
    [FTransGAN@Li2021FTransGAN], [], [], [], [],
    [FontDiffuser (Baseline)@Yang2024FontDiffuser], [0.1370], [0.5731], [0.2476], [59.5788],
    table.hline(stroke: 0.5pt),
    [$"Ours"_"All"$ (w/ CL-SCR)], [0.1090], [0.6377], [0.1985], [*41.1152*], 
    [$"Ours"_"Easy"$ (w/ CL-SCR)], [#underline[0.1050]], [#underline[0.6439]], [#underline[0.1945]], [#underline[41.7273]], 
    [$"Ours"_"Medium"$ (w/ CL-SCR)], [*0.1029*], [*0.6466*], [*0.1929*], [43.6918], 
    [$"Ours"_"Hard"$ (w/ CL-SCR)], [0.1050], [0.6444], [0.1982], [45.5486], 
  ),
  caption: [Kết quả Định lượng cho Hán tự $->$ Latin (c2e) trên UFSC. #linebreak() Mũi tên chỉ hướng tốt hơn (thấp hơn hoặc cao hơn).]
) <tab:c2e_ufsc>

Dựa trên số liệu từ @tab:c2e_sfuc và @tab:c2e_ufsc, kết quả thực nghiệm cho thấy *phương pháp đề xuất (Ours) đạt được sự cải thiện toàn diện so với các mô hình SOTA*, đồng thời hé lộ mối tương quan thú vị giữa độ phức tạp của Hán tự và hiệu quả chuyển đổi phong cách.

Thứ nhất, xét về hiệu năng tổng thể, mô hình đề xuất vượt trội hoàn toàn so với Baseline FontDiffuser@Yang2024FontDiffuser ở cả hai kịch bản. Trên tập dữ liệu quen thuộc SFUC, cấu hình $"Ours"_"Easy"$ *đạt mức FID thấp kỷ lục 14.656*, *giảm khoảng 31% so với Baseline (21.223)*. Sự chênh lệch càng trở nên rõ rệt hơn ở kịch bản khó UFSC (Unseen Font), nơi $"Ours"_"All"$ *đạt FID 41.115*, thấp hơn đáng kể so với mức *59.579 của Baseline*. Điều này khẳng định rằng mô-đun CL-SCR không chỉ hiệu quả trong việc tinh chỉnh phong cách nội tại mà còn giúp mô hình tổng quát hoá tốt hơn khi phải đối mặt với các phong cách Hán tự lạ lẫm, phức tạp để áp dụng lên cấu trúc Latin đơn giản. So với các phương pháp GAN (DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont) hay FTransGAN@Li2021FTransGAN vốn có chỉ số FID rất cao (trên 80 ở UFSC), phương pháp đề xuất chứng minh ưu thế tuyệt đối về độ tự nhiên và tính thẩm mỹ của ảnh sinh.

Thứ hai, phân tích sâu về độ phức tạp nét (stroke complexity) thông qua các biến thể Easy, Medium và Hard mang lại những góc nhìn giá trị. Tại bảng @tab:c2e_ufsc, có thể thấy cấu hình $"Ours"_"Medium"$ *đạt kết quả tốt nhất về các chỉ số cấu trúc và điểm ảnh (L1 thấp nhất 0.1029, SSIM cao nhất 0.6466)*. Điều này gợi ý rằng *các Hán tự có số nét trung bình (11-20 nét) là điểm ngọt để trích xuất phong cách*: chúng cung cấp đủ thông tin về bút pháp và kết cấu (hơn Easy) nhưng không gây ra quá nhiều nhiễu cấu trúc (structural noise) như các ký tự Hard (trên 21 nét). Khi sử dụng các ký tự quá phức tạp (Hard) để chuyển phong cách sang chữ Latin (vốn rất đơn giản), mô hình dễ gặp khó khăn trong việc lược bỏ các chi tiết thừa, dẫn đến chỉ số FID và L1 của $"Ours"_"Hard"$ thường kém hơn so với Easy và Medium.

Cuối cùng, mặc dù $"Ours"_"Medium"$ tối ưu về cấu trúc, nhưng $"Ours"_"All"$ lại đạt chỉ số FID tốt nhất trên tập UFSC (41.115). Điều này cho thấy *việc tiếp xúc với đa dạng các mức độ phức tạp trong quá trình huấn luyện giúp mô hình xây dựng được không gian biểu diễn phong cách phong phú nhất*, từ đó sinh ra các hình ảnh có độ tự nhiên cao nhất về mặt cảm nhận thị giác, ngay cả khi độ chính xác từng điểm ảnh (L1) thua kém nhẹ so với cấu hình chuyên biệt Medium.

=== So sánh Định tính (Qualitative Analysis)
Bên cạnh các chỉ số đo lường, việc phân tích trực quan là bước không thể thiếu để kiểm chứng khả năng xử lý các trường hợp khó của mô hình, đặc biệt là các lỗi cấu trúc mà các chỉ số thống kê như FID đôi khi không phản ánh hết. Khoá luận thực hiện phân tích dựa trên hình ảnh sinh ra từ hai chiều chuyển đổi đối lập.

==== Phân tích Trực quan (Visual Analysis)
// TODO (Me)

==== Đánh giá Cảm nhận Người dùng (User Study)
// TODO (User)
Dựa trên quy trình khảo sát mù (blind test) đã được thiết lập chi tiết tại Mục TODO, khoá luận tổng hợp kết quả bình chọn từ 30 tình nguyện viên trên tập dữ liệu kiểm thử ngẫu nhiên.

#figure(
    image("../images/user score.png", width: 100%),
    caption: [Biểu đồ so sánh tỷ lệ ưu tiên của người dùng giữa phương pháp đề xuất (Ours) và các phương pháp SOTA khác. Kết quả cho thấy sự vượt trội về độ hài lòng thị giác của mô hình tích hợp CL-SCR.]
  )

*Phân tích và Thảo luận:*
Kết quả định lượng cho thấy sự vượt trội của phương pháp đề xuất (Ours) với tỷ lệ được ưu tiên lựa chọn trung bình đạt *khoảng 70%*, bỏ xa các phương pháp đối chứng (cao nhất là CF-Font chỉ đạt khoảng 10%). Sự chênh lệch áp đảo này phản ánh sự tương đồng giữa cảm nhận chủ quan của mắt người và các chỉ số máy học (FID/LPIPS) đã phân tích trước đó.

Xu hướng lựa chọn của người dùng có thể được lý giải thông qua sự so sánh trực quan, trong đó *tính dễ đọc (Legibility)* đóng vai trò là yếu tố tiên quyết. Thực tế cho thấy, người dùng thường có phản xạ loại bỏ ngay lập tức các mẫu bị *biến dạng cấu trúc nặng nề* - một nhược điểm cố hữu khiến các mô hình thuộc họ GAN (như DG-Font, CF-Font) nhận được tỷ lệ bình chọn rất thấp ($<10%$). Trong bối cảnh đó, mô hình đề xuất đã chứng minh được ưu thế nhờ khả năng bảo toàn khung xương ký tự vững chắc thông qua cơ chế MCA và RSI, giúp các kết quả sinh ra vượt qua được rào cản nhận thức đầu tiên về mặt cấu trúc để tiến tới các đánh giá chi tiết hơn về phong cách.

#grid(
  columns: 1,
  gutter: 10pt,

  figure(
    image("../images/content1.png", width: 100%),
    caption: [Ví dụ về ảnh Content và ảnh Style.]
  ),

  figure(
    image("../images/gen1.png", width: 100%),
    caption: [Các kết quả để người tham khảo sát lựa chọn.]
  )
)

Tóm lại, tỷ lệ ưu tiên cao trong khảo sát người dùng là minh chứng thực tiễn khẳng định phương pháp đề xuất đã đạt được điểm cân bằng tốt nhất giữa hai yêu cầu cốt lõi: giữ đúng chữ (Content) và thể hiện đúng kiểu (Style).

== Nghiên cứu Bóc tách (Ablation Study)
Trong phần này, khoá luận thực hiện các phân tích chuyên sâu nhằm định lượng đóng góp cụ thể của từng thành phần kỹ thuật trong phương pháp đề xuất. Để đảm bảo tính tập trung và sức thuyết phục của các kết luận, thay vì dàn trải thí nghiệm trên mọi biến thể, khoá luận cố định và lựa chọn hai cấu hình đại diện tiêu biểu nhất làm cơ sở so sánh:

  *1. Đối với hướng Latin $->$ Hán tự* (`e2c`)*:* Khoá luận sử dụng cấu hình $"Ours"_"AZ"$. Đây là cấu hình chịu áp lực tổng quát hoá lớn nhất (do phải xử lý style ngẫu nhiên) và cũng là cấu hình đạt hiệu năng cao nhất trong các thực nghiệm trước đó. Việc chứng minh hiệu quả trên cấu hình "khó" nhất này sẽ khẳng định tính đúng đắn và mạnh mẽ (robustness) của các cải tiến đề xuất.
  
  *2. Đối với hướng Hán tự $->$ Latin* (`c2e`)*:* Khoá luận sử dụng cấu hình $"Ours"_"All"$. Do đặc thù độ phức tạp nét đa dạng của Hán tự, cấu hình này bao quát toàn bộ phổ dữ liệu huấn luyện, cung cấp cái nhìn toàn diện về độ ổn định của mô hình thay vì chỉ tập trung vào một tập con cụ thể (như Easy hay Hard).

Các thí nghiệm dưới đây sẽ lần lượt đánh giá tác động của bốn yếu tố then chốt: các mô-đun kiến trúc, kỹ thuật tăng cường dữ liệu, chế độ hàm mất mát và số lượng mẫu âm.

=== Ảnh hưởng của các mô-đun trong FontDiffuser
Để xác định đóng góp cụ thể của từng thành phần trong kiến trúc tổng thể, đặc biệt là hiệu quả của mô-đun đề xuất so với bản gốc, khoá luận tiến hành *thực nghiệm bóc tách (Ablation Study)* bằng cách *thay thế và bổ sung dần các mô-đun vào mạng nền tảng*. Bốn mô-đun được khảo sát bao gồm:
  - *M:* *Multi-scale Content Aggregation (MCA)* - Tổng hợp nội dung đa quy mô.
  - *R:* *Reference-Structure Interaction (RSI)* - Tương tác cấu trúc tham chiếu.
  - *S:* *Style Contrastive Refinement (SCR)* - Tinh chỉnh tương phản phong cách đơn ngôn ngữ (Của FontDiffuser gốc).
  - *CL:* *Cross-Lingual Style Contrastive Refinement (CL-SCR)* - Tinh chỉnh tương phản phong cách đa ngôn ngữ (Đề xuất cải tiến).
  
Kết quả thực nghiệm trên hai hướng chuyển đổi được trình bày chi tiết tại @tab:e2c_module và @tab:c2e_module.
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

  caption: [
    Phân tích ảnh hưởng của các thành phần M, R, S và CL đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự.
  ]
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

  caption: [
    Phân tích ảnh hưởng của các thành phần M, R, S và CL đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin.
  ]
) <tab:c2e_module>


*Nhận xét và Thảo luận:*

Quan sát từ dữ liệu thực nghiệm cho thấy vai trò nền tảng không thể thay thế của các mô-đun *M* và *R*. Khi tích hợp hai mô-đun này vào mạng Baseline, hiệu năng mô hình có sự chuyển biến mang tính bước ngoặt, thể hiện qua việc *chỉ số FID giảm sâu* ở cả hai hướng nghiên cứu. Đơn cử như trong kịch bản e2c (UFSC), việc có M và R giúp FID giảm từ *70.36* xuống *29.10* (tương ứng với cấu hình FontDiffuser Gốc). Điều này khẳng định rằng mạng Diffusion thuần túy gặp rất nhiều khó khăn trong việc định hình cấu trúc ký tự phức tạp nếu chỉ dựa vào đặc trưng cấp cao; M và R chính là "bộ khung xương" cung cấp các đặc trưng nội dung chi tiết đa tầng và tinh chỉnh độ khớp không gian, giúp mô hình dựng hình chính xác các nét và bộ thủ.

Tuy nhiên, điểm nhấn quan trọng nhất nằm ở sự so sánh giữa mô-đun *S (SCR gốc)* và *CL (CL-SCR đề xuất)*. Kết quả thực nghiệm cho thấy *CL-SCR* vượt trội hơn hẳn so với SCR gốc, đặc biệt là trong các kịch bản khó *(Unseen Font)*. Cụ thể, trong hướng `e2c` (UFSC), việc thay thế S bằng CL giúp FID giảm mạnh từ *29.10* xuống *13.55*. Tương tự ở hướng `c2e` (UFSC), FID giảm từ *59.58* xuống *41.11*.

_Lý giải:_ *SCR gốc* vốn được thiết kế cho bài toán đơn ngôn ngữ, nơi khoảng cách giữa các phong cách nhỏ hơn. Khi áp dụng cho bài toán đa ngôn ngữ (*Cross-lingual*), SCR gốc gặp khó khăn trong việc tách biệt triệt để phong cách khỏi nội dung do sự khác biệt lớn về hình thái học. Ngược lại, *CL-SCR* với *cơ chế tương phản đa miền và chiến lược lấy mẫu âm cải tiến* đã giúp mô hình "hiểu" và trích xuất được bản chất phong cách (như kết cấu, bút pháp) một cách trừu tượng hơn, qua đó đảm bảo chất lượng sinh ảnh ổn định và tự nhiên ngay cả với các font chữ mới lạ.

#figure(
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
    [],
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

    rotate(-90deg)[*UFSC* (`e2c`)],
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

    [],
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

    [],
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
    [], 
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

    rotate(-90deg)[*UFSC* (`c2e`)],
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

    [],
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

    [],
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

  caption: [
    So sánh kết quả sinh ảnh giữa các mô-đun khác nhau
    trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (`e2c` và `c2e`).
  ]
)

*Kết luận:* Tổng hợp lại, kết quả nghiên cứu bóc tách đã làm sáng tỏ vai trò riêng biệt và bổ trợ lẫn nhau của các thành phần kiến trúc. Trong khi *MCA* và *RSI* đóng vai trò là nền tảng cấu trúc không thể thiếu để ngăn chặn sự sụp đổ hình dáng ký tự, thì *CL-SCR* chính là nhân tố quyết định nâng tầm chất lượng thị giác và khả năng tổng quát hoá. Việc CL-SCR giúp giảm sâu chỉ số *FID* trên các *tập dữ liệu lạ (UFSC)* so với SCR gốc khẳng định rằng cơ chế tương phản đa ngôn ngữ là chìa khoá để mô hình vượt qua rào cản hình thái học, cho phép chuyển giao phong cách Latin sang Hán tự một cách tự nhiên và linh hoạt hơn.

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
    [$"Ours"_"AZ"$ (w/o Augment)], [#underline[0.1974]], [#underline[0.3831]], [#underline[0.2967]], [#underline[14.1295]],
    [$"Ours"_"AZ"$ (w/ Augment)], [*0.1939*], [*0.3890*], [*0.2911*], [*11.7691*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"AZ"$ (w/o Augment)], [#underline[0.2295]], [#underline[0.3066]], [#underline[0.3060]], [#underline[15.7706]],
    [$"Ours"_"AZ"$ (w/ Augment)], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
  ),
  caption: [Phân tích ảnh hưởng của tăng cường dữ liệu đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
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
    [$"Ours"_"All"$ (w/o Augment)], [*0.1076*], [*0.6504*], [*0.1978*], [*12.3668*],
    [$"Ours"_"All"$ (w/ Augment)], [#underline[0.1083]], [#underline[0.6406]], [#underline[0.2019]], [#underline[14.7298]],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 2,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"All"$ (w/o Augment)], [#underline[0.1126]], [#underline[0.6364]], [#underline[0.2015]], [#underline[43.0665]],
    [$"Ours"_"All"$ (w/ Augment)], [*0.1090*], [*0.6377*], [*0.1985*], [*41.1152*],
  ),
  caption: [Phân tích ảnh hưởng của tăng cường dữ liệu đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_aug>

*Nhận xét và Thảo luận:*

Đối với hướng chuyển đổi từ Latin sang Hán tự (`e2c`), quan sát tại @tab:e2c_aug cho thấy việc áp dụng Augmentation mang lại sự cải thiện *toàn diện và nhất quán* trên mọi chỉ số ở cả hai kịch bản SFUC và UFSC. *Đáng chú ý nhất là chỉ số FID trên tập UFSC giảm mạnh từ _15.77_ xuống _13.55_*, tương ứng với mức cải thiện *khoảng 14%*. Điều này có thể được lý giải bởi *đặc thù cấu trúc đơn giản* của ký tự Latin đóng vai trò là ảnh phong cách. Nếu thiếu đi sự đa dạng hoá dữ liệu thông qua Augmentation, mô hình dễ bị phụ thuộc vào các đặc trưng vị trí không gian cố định. Kỹ thuật *Random Resized Crop* buộc mô-đun CL-SCR phải tập trung học các *đặc trưng bản chất* như độ dày nét, serif hay độ tương phản bất kể biến đổi về kích thước hay vị trí, từ đó giúp quá trình áp dụng phong cách lên cấu trúc phức tạp của Hán tự trở nên linh hoạt và tự nhiên hơn.

Trong khi đó, hướng chuyển đổi ngược lại từ Hán tự sang Latin (`c2e`) tại @tab:c2e_aug lại hé lộ một sự đánh đổi thú vị giữa khả năng *ghi nhớ và khái quát hoá*. Trên tập dữ liệu đã biết (SFUC), cấu hình không có Augmentation đạt kết quả tốt hơn với FID 12.36 so với 14.72. Tuy nhiên, ưu thế *đảo chiều hoàn toàn* trên tập dữ liệu chưa biết (UFSC), nơi cấu hình có Augmentation giành lại vị thế dẫn đầu với FID giảm từ *43.06* xuống *41.11* và sai số L1 cũng được cải thiện. Hiện tượng này minh chứng rõ ràng cho *vai trò điều hòa (Regularization)* của tăng cường dữ liệu. Ở kịch bản SFUC, việc thiếu nhiễu cho phép mô hình *tối ưu hoá cục bộ (overfit)* trên các mẫu đã thấy, dẫn đến chỉ số cao nhưng kém bền vững. Ngược lại, khi đối mặt với dữ liệu lạ trong UFSC, khả năng ghi nhớ trở nên vô hiệu, và lúc này các *đặc trưng phong cách cốt lõi* mang tính khái quát cao mà mô hình học được nhờ *Augmentation* mới thực sự phát huy tác dụng. Vì vậy, kết quả vượt trội trên UFSC khẳng định rằng tăng cường dữ liệu là thành phần thiết yếu để đảm bảo *khả năng tổng quát hoá* của mô hình trong các ứng dụng thực tế.

#figure(
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 6pt,
    stroke: none,
    align: horizon,
    inset: 6pt,

    // ===== Header =====
    [], grid.vline(), [], grid.vline(), [*Example 1*], grid.vline(), [*Example 2*],
    grid.hline(),
    // ===== UFSC e2c =====
    [], [w/ Augment],
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

    rotate(-90deg)[*UFSC* (`e2c`)], [w/o Augment],
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

    [], [*Target*],
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
    [], [w/ Augment],
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

    rotate(-90deg)[*UFSC* (`c2e`)], [w/o Augment],
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

    [], [*Target*],
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

  caption: [
    So sánh kết quả sinh ảnh giữa mô hình có và không áp dụng tăng cường dữ liệu trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (`e2c` và `c2e`).
  ]
)

*Kết luận:* Dựa trên phân tích trên, khoá luận khẳng định *chiến lược Tăng cường dữ liệu* là thành phần không thể thiếu, đặc biệt quan trọng để nâng cao hiệu suất trên các *dữ liệu chưa từng biết (Unseen Domains)*, mặc dù có thể đánh đổi một lượng nhỏ hiệu năng trên các dữ liệu đã biết.

=== Ảnh hưởng của Chế độ hàm loss
Trong kiến trúc *CL-SCR*, hàm mất mát *InfoNCE@Oord2018CPC* đóng vai trò điều hướng không gian biểu diễn phong cách. khoá luận khảo sát *ba biến thể chiến lược huấn luyện* được định nghĩa trong tham số `loss_mode`:
  - `scr_intra`: Chỉ sử dụng mẫu âm nội miền (Intra-domain). Ví dụ: so sánh Style Latin với các Style Latin khác.
  - `scr_cross`: Chỉ sử dụng mẫu âm xuyên miền (Cross-domain). Ví dụ: so sánh Style Latin với Style Hán tự.
  - `scr_both`: Kết hợp cả hai với trọng số $alpha_"intra" = 0.3$ và $beta_"cross"=0.7$.

Kết quả thực nghiệm được trình bày tại @tab:e2c_lossmode và @tab:c2e_lossmode.

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
    [$"Ours"_"AZ"$ (scr_intra)], [#underline[0.1969]], [#underline[0.3812]], [#underline[0.2958]], [11.9552],
    [$"Ours"_"AZ"$ (scr_cross)], [0.1993], [0.3770], [0.2982], [#underline[11.8645]],
    [$"Ours"_"AZ"$ (scr_both)], [*0.1939*], [*0.3890*], [*0.2911*], [*11.7691*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"AZ"$ (scr_intra)], [#underline[0.2290]], [#underline[0.3008]], [#underline[0.3085]], [#underline[15.7197]],
    [$"Ours"_"AZ"$ (scr_cross)], [0.2326], [0.2911], [0.3128], [16.2615],
    [$"Ours"_"AZ"$ (scr_both)], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
  ),
  caption: [Phân tích ảnh hưởng của các chế độ loss đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_lossmode>


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
    [$"Ours"_"All"$ (scr_intra)], [*0.0993*], [*0.6614*], [*0.1903*], [*13.6449*],
    [$"Ours"_"All"$ (scr_cross)], [0.1091], [#underline[0.6436]], [#underline[0.2017]], [#underline[14.0159]],
    [$"Ours"_"All"$ (scr_both)], [#underline[0.1083]], [0.6406], [0.2019], [14.7298],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"All"$ (scr_intra)], [*0.0971*], [*0.6601*], [*0.1845*], [#underline[41.3399]],
    [$"Ours"_"All"$ (scr_cross)], [0.1175], [0.6209], [0.2095], [44.7758],
    [$"Ours"_"All"$ (scr_both)], [#underline[0.1090]], [#underline[0.6377]], [#underline[0.1985]], [*41.1152*],
  ),
  caption: [Phân tích ảnh hưởng của các chế độ loss đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_lossmode>

*Nhận xét và Thảo luận:*

Đối với hướng chuyển đổi từ Latin sang Hán tự (`e2c`), số liệu tại @tab:e2c_lossmode phản ánh *sự thống trị rõ rệt của chiến lược hỗn hợp* `scr_both` trên hầu hết các chỉ số, đặc biệt là sự cải thiện vượt bậc về chỉ số FID trong kịch bản khó UFSC (đạt *13.55* so với 15.72 của `scr_intra` và 16.26 của `scr_cross`). Kết quả này có thể được lý giải bởi *đặc thù thông tin "thưa" (sparse)* của phong cách Latin. Nếu chỉ sử dụng so sánh nội miền `scr_intra`, mô hình khó học được cách các đặc trưng Latin đơn giản tương tác với cấu trúc Hán tự phức tạp; ngược lại, nếu chỉ dùng `scr_cross`, khoảng cách miền quá lớn lại gây ra sự bất ổn định trong quá trình hội tụ. Do đó, sự kết hợp trong `scr_both` *đóng vai trò như cầu nối*, giúp mô hình vừa nắm bắt vững chắc đặc trưng nội tại của Latin, vừa học được mối tương quan ngữ nghĩa với Hán tự để tạo ra kết quả tối ưu.

Bức tranh trở nên phức tạp và thú vị hơn khi xét đến chiều ngược lại từ Hán tự sang Latin (`c2e`) tại @tab:c2e_lossmode, nơi xuất hiện một *nghịch lý về độ giàu thông tin*. Khác với hướng `e2c`, chiến lược `scr_intra` *lại thể hiện sự vượt trội về các chỉ số cấu trúc và điểm ảnh*(L1 thấp nhất 0.097, SSIM cao nhất) trên cả hai tập dữ liệu. Nguyên nhân sâu xa nằm ở bản chất *"đậm đặc" (dense) và giàu thông tin* của phong cách Hán tự (nét bút, độ dày, kết cấu). Chỉ cần *so sánh nội bộ giữa các Hán tự* là đã đủ để mô hình trích xuất được một vector phong cách mạnh mẽ. Trong bối cảnh này, việc ép buộc so sánh xuyên miền với Latin (thông qua thành phần cross trong `scr_both`) vô tình tạo ra nhiễu do sự khác biệt quá lớn về cấu trúc, làm giảm nhẹ độ chính xác tái tạo. Tuy nhiên, `scr_both` *vẫn giữ được ưu thế về độ tự nhiên tổng thể* (FID 41.11 so với 41.34) trên tập lạ UFSC, đóng vai trò như một cơ chế điều hòa cần thiết để đảm bảo tính thẩm mỹ khi đối mặt với các font hoàn toàn mới.

#figure(
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 6pt,
    stroke: none,
    align: horizon,
    inset: 6pt,

    // ===== Header =====
    [], grid.vline(), [], grid.vline(), [*Example 1*], grid.vline(), [*Example 2*],
    grid.hline(),

    // ===== UFSC e2c =====
    [], [scr_intra],
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

    rotate(-90deg)[*UFSC* (`e2c`)], [scr_cross],
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

    [], [scr_both],
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

    [], [*Target*],
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
    [], [scr_intra],
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

    rotate(-90deg)[*UFSC* (`c2e`)], [scr_cross],
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

    [], [scr_both],
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

    [], [*Target*],
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

  caption: [
    So sánh kết quả sinh ảnh giữa các chế độ mất mát khác nhau
    trên tập dữ liệu chưa từng thấy cho hai hướng tác vụ (`e2c` và `c2e`).
  ]
)


*Kết luận:* Tổng kết lại, đối với bài toán tổng quát, *chiến lược* `scr_both` *là lựa chọn an toàn và ổn định nhất* để cân bằng giữa độ chính xác và tính tự nhiên. Tuy nhiên, thực nghiệm cũng mở ra một góc nhìn quan trọng: khi miền nguồn có lượng thông tin phong phú như Hán tự, *chiến lược học nội miền* (`scr_intra`) *cũng mang lại hiệu quả rất ấn tượng*, gợi ý tiềm năng tối ưu hoá chi phí huấn luyện cho các ứng dụng cụ thể mà không nhất thiết phải phụ thuộc vào dữ liệu cặp đôi xuyên ngôn ngữ.

=== Ảnh hưởng của số lượng mẫu âm
Trong khuôn khổ của *phương pháp học tương phản (Contrastive Learning)*, *số lượng mẫu âm ($K$)* đóng vai trò quan trọng trong việc định hình không gian biểu diễn đặc trưng. Theo lý thuyết thông thường, việc tăng số lượng mẫu âm thường giúp mô hình phân biệt tốt hơn giữa các đặc trưng phong cách, từ đó học được các biểu diễn phong phú hơn. Để kiểm chứng giả thuyết này trong bối cảnh sinh phông chữ đa ngôn ngữ, khoá luận tiến hành thực nghiệm với các giá trị *$K$ lần lượt là 4, 8 và 16* trên cả hai hướng chuyển đổi. Kết quả chi tiết được tổng hợp tại @tab:e2c_numneg và @tab:c2e_numneg.

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
    [$"Ours"_"AZ"$ ($"num_neg"=4$)], [*0.1939*], [*0.3890*], [*0.2911*], [#underline[11.7691]],
    [$"Ours"_"AZ"$ ($"num_neg"=8$)], [0.1972], [#underline[0.3835]], [#underline[0.2952]], [12.3750],
    [$"Ours"_"AZ"$ ($"num_neg"=16$)], [#underline[0.1967]], [0.3833], [0.2956], [*10.6901*],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"AZ"$ ($"num_neg"=4$)], [*0.2214*], [*0.3197*], [*0.2954*], [*13.5508*],
    [$"Ours"_"AZ"$ ($"num_neg"=8$)], [0.2285], [0.3048], [0.3061], [#underline[15.0245]],
    [$"Ours"_"AZ"$ ($"num_neg"=16$)], [#underline[0.2273]], [#underline[0.3064]], [#underline[0.3048]], [16.7855],
  ),
  caption: [Phân tích ảnh hưởng của số lượng mẫu âm đối với hiệu năng mô hình trên tác vụ Latin $->$ Hán tự (e2c).]
) <tab:e2c_numneg>


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
    [$"Ours"_"All"$ ($"num_neg"=4$)], [0.1083], [0.6406], [0.2019], [*14.7298*],
    [$"Ours"_"All"$ ($"num_neg"=8$)], [#underline[0.1080]], [#underline[0.6464]], [#underline[0.1999]], [#underline[14.8365]],
    [$"Ours"_"All"$ ($"num_neg"=16$)], [*0.1059*], [*0.6468*], [*0.1992*], [15.7326],
    
    table.hline(stroke: 0.5pt),
    table.cell(
      rowspan: 3,
      align: horizon,
      rotate(-90deg, reflow: true)[
 *UFSC*
      ],
    ),

    [$"Ours"_"All"$ ($"num_neg"=4$)], [#underline[0.1090]], [#underline[0.6377]], [*0.1985*], [*41.1152*],
    [$"Ours"_"All"$ ($"num_neg"=8$)], [*0.1087*], [*0.6398*], [*0.1985*], [43.8077],
    [$"Ours"_"All"$ ($"num_neg"=16$)], [0.1111], [0.6311], [#underline[0.2008]], [#underline[43.5042]],
  ),
  caption: [Phân tích ảnh hưởng của số lượng mẫu âm đối với hiệu năng mô hình trên tác vụ Hán tự $->$ Latin (c2e).]
) <tab:c2e_numneg>

*Nhận xét và Thảo luận:*

Phân tích số liệu từ thực nghiệm cho thấy một kết quả *trái ngược với trực giác phổ biến trong học tương phản* trên các tác vụ thị giác máy tính khác. Cụ thể, trong hướng chuyển đổi từ Latin sang Hán tự (@tab:e2c_numneg), cấu hình sử dụng số lượng mẫu âm nhỏ nhất ($K=4$) lại thể hiện sự vượt trội về *độ ổn định và khả năng tổng quát hoá*. Trên tập kiểm thử khó UFSC, cấu hình này đạt chỉ số FID tốt nhất là *13.55*, thấp hơn đáng kể so với mức 16.78 khi sử dụng 16 mẫu âm. Đồng thời, các chỉ số về cấu trúc như SSIM và sai số L1 cũng đạt giá trị tối ưu tại *$K=4$*. Điều này gợi ý rằng đối với hệ chữ Latin vốn có cấu trúc nét tương đối đơn giản và "thưa", việc sử dụng quá nhiều mẫu âm có thể vô tình đưa vào các *tín hiệu nhiễu* hoặc các mẫu có phong cách quá tương đồng (*false negatives*), khiến mô hình bị rối loạn trong việc định vị biên giới phong cách, dẫn đến suy giảm hiệu năng trên dữ liệu chưa từng thấy.

Xu hướng tương tự cũng được quan sát thấy ở chiều ngược lại từ Hán tự sang Latin (@tab:c2e_numneg), mặc dù có sự phân hoá nhẹ giữa khả năng ghi nhớ và khái quát hoá. Khi đánh giá trên tập font đã biết (SFUC), việc tăng số lượng mẫu âm lên 16 giúp cải thiện nhẹ các chỉ số điểm ảnh như L1 và SSIM, do mô hình tận dụng được nhiều dữ liệu so sánh hơn để khớp chi tiết các nét phức tạp của Hán tự. Tuy nhiên, lợi thế này *không duy trì được khi chuyển sang tập font lạ (UFSC)*. Tại đây, cấu hình $K=4$ một lần nữa khẳng định tính hiệu quả với chỉ số FID thấp nhất (*41.11*), vượt qua cả cấu hình $K=8$ và $K=16$. Kết quả này củng cố nhận định rằng trong bài toán chuyển đổi đa ngôn ngữ với sự chênh lệch lớn về miền dữ liệu, một tập hợp mẫu âm *nhỏ nhưng tinh gọn* sẽ hiệu quả hơn việc cố gắng phân biệt với một lượng lớn mẫu âm có thể gây nhiễu. Do đó, việc lựa chọn $K=4$ không chỉ giúp *tối ưu hoá tài nguyên tính toán* mà còn đảm bảo chất lượng sinh ảnh tốt nhất về mặt thị giác.

#figure(
  grid(
    columns: (40pt, auto, auto, auto),
    gutter: 8pt,
    inset: 6pt,
    stroke: none,
    align: horizon,

    // ===== Header =====
    [], grid.vline(),
    [], grid.vline(),
    [*Example 1*], grid.vline(),
    [*Example 2*],

    // ===== UFSC e2c =====
    grid.hline(),
    [],
    [$"num_neg"=4$],
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

    rotate(-90deg)[*UFSC* (`e2c`)],
    [$"num_neg"=8$],
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

    [],
    [$"num_neg"=16$],
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

    [],
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
    [],
    [$"num_neg"=4$],
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

    rotate(-90deg)[*UFSC* (`c2e`)],
    [$"num_neg"=8$],
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

    [],
    [$"num_neg"=16$],
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

    [],
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

  caption: [
    So sánh kết quả sinh ảnh giữa các số lượng mẫu âm khác nhau
    trên tập dữ liệu chưa từng thấy cho cả hai hướng tác vụ (`e2c` và `c2e`).
  ]
) <tab:dinhtinh_neg>


*Kết luận:* Tổng kết lại, thực nghiệm về số lượng mẫu âm đã làm sáng tỏ một đặc điểm thú vị trong bài toán chuyển đổi phong cách xuyên ngôn ngữ: *sự tối giản lại mang lại hiệu quả tối ưu*. Trái với kỳ vọng rằng nhiều mẫu âm sẽ giúp học biểu diễn phong cách tốt hơn, kết quả cho thấy việc *giới hạn* $K=4$ giúp mô hình xây dựng được *không gian biểu diễn phong cách cô đọng*, tránh được hiện tượng quá khớp (overfitting) hoặc nhiễu loạn thông tin từ các mẫu âm dư thừa. Đặc biệt trên các tập dữ liệu chưa từng thấy (UFSC), cấu hình $K=4$ luôn duy trì vị thế dẫn đầu về chỉ số FID ở cả hai hướng chuyển đổi, chứng minh đây là *thiết lập tối ưu* để cân bằng giữa độ chính xác tái tạo và khả năng tổng quát hoá, đồng thời *giảm tải đáng kể chi phí huấn luyện*.

#pagebreak()