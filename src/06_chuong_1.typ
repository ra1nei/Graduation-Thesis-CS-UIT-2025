#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Giới Thiệu <chuong1>
]

== Giới thiệu bài toán
Thiết kế phông chữ (Typeface design) từ lâu đã được xem là một loại hình nghệ thuật đòi hỏi sự kết hợp tinh tế giữa thẩm mĩ và kĩ thuật. Để tạo ra một bộ phông chữ hoàn chỉnh, các nhà thiết kế (typographers) phải vẽ thủ công hàng nghìn ký tự (glyphs) nhằm đảm bảo sự nhất quán về phong cách (style) như độ dày nét, hình dáng chân chữ (serif), và độ cong. Thách thức này càng trở nên lớn hơn đối với các hệ chữ tượng hình phức tạp như CJK (Chinese, Japanese, Korean), nơi số lượng ký tự có thể lên tới hàng chục nghìn. Do đó, các phương pháp truyền thống dựa trên nội suy (interpolation) hoặc vector hóa thủ công thường tốn kém nhiều chi phí, thời gian và khó mở rộng quy mô.

Trong bối cảnh đó, bài toán Sinh phông chữ tự động (Automatic Font Generation) đã trở thành một hướng nghiên cứu mũi nhọn trong lĩnh vực Thị giác máy tính (Computer Vision) và Học sâu (Deep Learning). Sự chuyển dịch từ các mô hình Generative Adversarial Networks (GANs) sang Denoising Diffusion Probabilistic Models (DDPMs) gần đây đã tạo ra bước đột phá về chất lượng ảnh sinh. Các mô hình Diffusion, điển hình như FontDiffuser, đã chứng minh khả năng vượt trội trong việc tái tạo các chi tiết nét chữ phức tạp và duy trì cấu trúc tô pô học của ký tự mà không gặp phải các vấn đề về mất ổn định khi huấn luyện (mode collapse) thường thấy ở GAN.

Tuy nhiên, phần lớn các nghiên cứu hiện tại chỉ tập trung vào bài toán đơn ngôn ngữ (intra-lingual), tức là sinh chữ cái Latin từ mẫu Latin, hoặc sinh chữ Hán từ mẫu Hán. Một thách thức lớn hơn và vẫn còn nhiều "khoảng trống" nghiên cứu là bài toán sinh phông chữ đa ngôn ngữ (cross-lingual font generation).

Vấn đề cốt lõi của bài toán đa ngôn ngữ nằm ở "khoảng cách miền" (domain gap) giữa các hệ chữ viết. Ví dụ, việc chuyển đổi phong cách từ một chữ Hán (với cấu trúc nét phức tạp, ô vuông) sang chữ cái Latin (cấu trúc đơn giản, tuyến tính) đòi hỏi mô hình phải có khả năng:

- Tách biệt hoàn toàn (Disentanglement) giữa nội dung (content) và phong cách (style).

- Học được các đặc trưng phong cách bất biến (invariant style features) – những đặc điểm thẩm mỹ trừu tượng không phụ thuộc vào cấu trúc hình học của ngôn ngữ gốc.

Đây là một bài toán khó, bởi nếu không được xử lý tốt, mô hình thường có xu hướng "áp đặt" cấu trúc của ngôn ngữ nguồn lên ngôn ngữ đích, dẫn đến các ký tự bị biến dạng hoặc mất đi tính dễ đọc (legibility).

== Mô tả bài toán
Phần này sẽ định nghĩa bài toán sinh phông chữ đa ngôn ngữ dưới dạng một bài toán chuyển đổi phong cách ảnh (Image-to-Image Translation) có điều kiện.

=== Định nghĩa đầu vào (Input)
Mô hình nhận vào hai luồng thông tin chính:
- Ảnh tham chiếu nội dung (Content Image - $I_c$):
  - Là một hình ảnh chứa ký tự mục tiêu $c$ (target glyph) trong một phông chữ tiêu chuẩn (ví dụ: Arial hoặc Noto Sans).
  - Mục đích: Cung cấp thông tin về cấu trúc hình học và định danh của ký tự cần sinh (ví dụ: chữ 'A', chữ 'g').
  - Trong bài toán cross-lingual, $I_c$ thuộc hệ ngôn ngữ đích (Target Language, ví dụ: Latin).

#grid(
  columns: 3,
  gutter: 5pt,
  fill: rgb("ffffff"),     // nền chung cho các ô
  inset: 4pt,             // padding trong mỗi ô
  stroke: (0.5pt),        // đường kẻ lưới
  image("../images/example_image/ダ.png", width:100%),
  image("../images/example_image/c.png", width:100%),
  image("../images/example_image/L+.png", width:100%),
)

#text[Ví dụ về một số ảnh Content]

- Ảnh tham chiếu phong cách (Style Images - $I_s$):
  - Là tập hợp một hoặc một vài hình ảnh ($k$-shot) chứa các ký tự bất kỳ mang phong cách $s$ mong muốn.
  - Mục đích: Cung cấp các đặc trưng thẩm mỹ (nét xước, độ đậm nhạt, serif...).
  - Trong bài toán cross-lingual, $I_s$ thường thuộc hệ ngôn ngữ nguồn (Source Language, ví dụ: Chinese) khác với ngôn ngữ của $I_c$.

#grid(
  columns: 3,
  gutter: 5pt,
  fill: rgb("ffffff"),     // nền chung cho các ô
  inset: 4pt,             // padding trong mỗi ô
  stroke: (0.5pt),        // đường kẻ lưới
  image("../images/example_image/║║╥╟▒¿╦╬╝≥_chinese+产.png", width:100%),
  image("../images/example_image/A-OTF-ShinMGoMin-Shadow-2_english+M+.png", width:100%),
  image("../images/example_image/Bai zhou Tian zhen shu ti Font-Traditional Chinese_english+m.png", width:100%),
)
  
=== Định nghĩa đầu ra (Output)
Ảnh được sinh ra (Generated Image - $I_"gen"$):
- Là hình ảnh kết quả thể hiện ký tự $c$ nhưng mang phong cách $s$.
- Yêu cầu: $I_"gen"$ phải giữ được cấu trúc nội dung của $I_c$ (đọc được là chữ gì) và mang đầy đủ đặc điểm thẩm mỹ của $I_s$ (nhìn giống font mẫu).

=== Mục tiêu toán học
Mục tiêu là huấn luyện một hàm ánh xạ $G$ (Generator/Diffusion Model) sao cho:
$ I_"gen" = G(I_c, I_s) $
Thỏa mãn điều kiện: 
$"Content"(I_"gen") approx "Content"(I_c)$ và $"Style"(I_"gen") approx "Style"(I_s)$.

== Mục tiêu của đề tài
Khoá luận này đề xuất mở rộng mô hình FontDiffuser để giải quyết bài toán *cross-lingual font generation*, cụ thể:
- Thiết kế pipeline cho phép trích xuất phong cách từ một ngôn ngữ và áp dụng lên glyph của ngôn ngữ khác.
- Đề xuất cơ chế *Style-Content Regularization (SCR) mở rộng* với cả positive/negative pair cross-lingual nhằm buộc mô hình học đặc trưng phong cách bất biến theo ngôn ngữ.
- Tích hợp quá trình huấn luyện lại (fine-tuning) mô hình diffusion với dữ liệu đa ngôn ngữ và đánh giá chất lượng đầu ra theo các thước đo định lượng (LPIPS, FID) và đánh giá trực quan.

Mục tiêu cuối cùng là tạo ra một mô hình có khả năng sinh bộ font nhất quán đa ngôn ngữ, mở ra tiềm năng ứng dụng trong số hoá phông chữ, thiết kế tự động, và cá nhân hoá chữ viết.

== Đối tượng và phạm vi nghiên cứu
Để đảm bảo tính khả thi và tập trung sâu vào giải pháp kỹ thuật, đề tài xác định rõ đối tượng và giới hạn phạm vi nghiên cứu như sau:

=== Đối tượng nghiên cứu
Mô hình lý thuyết: Các mô hình sinh ảnh dựa trên khuếch tán (Diffusion Models), trọng tâm là kiến trúc FontDiffuser và các kỹ thuật điều hướng phong cách (Style Guidance).

Đối tượng dữ liệu:
Hệ chữ nguồn (Source): Các bộ phông chữ Hán (Chinese Fonts) đa dạng về phong cách (Mincho, Gothic, Thư pháp...).
Hệ chữ đích (Target): Bộ 52 ký tự tiếng Anh cơ bản (26 chữ hoa và 26 chữ thường) thuộc hệ Latin.

=== Phạm vi nghiên cứu
Phạm vi về ngôn ngữ: Đề tài chỉ giới hạn việc nghiên cứu và thực nghiệm trên quá trình chuyển đổi phong cách từ Tiếng Anh (Latin) sang Tiếng Trung Quốc (Hán). Lý do là vì độ phức tạp của chữ Hán thường cao hơn đáng kể so với chữ Latin: số nét nhiều, cấu trúc không tuyến tính, và chứa các thành phần hình thái mà chữ Latin không có. Điều này khiến quá trình chuyển giao phong cách trở nên thách thức hơn, buộc mô hình phải linh hoạt, tổng quát hóa tốt và giữ được tính ổn định khi tái tạo phong cách từ một hệ chữ đơn giản sang một hệ chữ phức tạp hơn. Vì vậy, việc lựa chọn cặp ngôn ngữ này giúp đánh giá rõ ràng hơn khả năng thích ứng và độ mạnh của mô hình trong các tình huống chuyển đổi phong cách có mức độ khó cao.

Phạm vi về bài toán:
Tập trung vào bài toán One-shot Generation: Đối với chữ Latin, mô hình được yêu cầu sinh toàn bộ bảng chữ cái tiếng Anh chỉ từ một ký tự đầu vào duy nhất. Tuy nhiên, khi mở rộng sang chữ Hán, số lượng ký tự là quá lớn để thực hiện cùng một yêu cầu. Do đó, nghiên cứu chỉ hướng tới việc sử dụng phong cách của một ký tự Latin làm “style input” và áp dụng nó lên một tập con ký tự Hán đóng vai trò “content input”, nhằm đánh giá khả năng chuyển giao phong cách trong bối cảnh hệ chữ mục tiêu phức tạp và đồ sộ hơn rất nhiều.

Phạm vi về dữ liệu: Sử dụng các bộ dữ liệu phông chữ mã nguồn mở hỗ trợ đồng thời cả hai bảng mã Unicode cho tiếng Trung và tiếng Anh (ví dụ: Google Noto CJK, Adobe Source Han Serif) để đảm bảo có cặp dữ liệu đối chứng (Ground Truth) chính xác cho quá trình huấn luyện và đánh giá.

== Cấu trúc của khoá luận
Phần còn lại của khoá luận này được trình bày như sau:
- @chuong2 – Tổng Quan Lý Thuyết và Các Nghiên Cứu Liên Quan:
Trình bày các khái niệm nền tảng về bài toán sinh font chữ. Đồng thời, chương này tổng hợp và phân tích các phương pháp sinh font trước đây, bao gồm nhóm mô hình dựa trên GAN (DG-Font, CF-Font, DFS, GAS-NeXt) và nhóm mô hình diffusion (FontDiffuser), chỉ ra ưu nhược điểm và xu hướng phát triển.

- @chuong3 – Phương Pháp Đề Xuất:
Trình bày chi tiết pipeline gốc của FontDiffuser, bao gồm hai giai đoạn huấn luyện (Phase 1 – Reconstruction, Phase 2 – Style Refinement).
Phân tích cơ chế hoạt động của các module chính như MCA (Multi-scale Content Aggregation), RSI (Reference-Structure Interaction) và SCR (Style Contrastive Refinement).
Trên cơ sở đó, chương này giới thiệu ý tưởng cải tiến nhằm mở rộng khả năng chuyển phong cách đa ngôn ngữ (cross-lingual style transfer) thông qua việc thay thế và điều chỉnh module SCR.

- @chuong4 – Thực Nghiệm, Kết Quả và Phân Tích
Chương này mô tả chi tiết quy trình thiết lập thực nghiệm, bao gồm việc xây dựng tập dữ liệu đa ngôn ngữ (Latin–Hán), cấu hình huấn luyện và các tiêu chí đánh giá được sử dụng (FID, SSIM, LPIPS, L1, User Study). Đồng thời, chương trình bày các kết quả định lượng và định tính, so sánh mô hình đề xuất (FontDiffuser + CL-SCR) với các mô hình nền tảng (GAN-based và Diffusion-based). Phần phân tích chuyên sâu sẽ đánh giá hiệu quả của module CL-SCR, nghiên cứu Ablation về các thành phần cải tiến, và thảo luận về ưu điểm, hạn chế cũng như ảnh hưởng của các tham số then chốt (như số lượng mẫu âm, Guidance Scale) đối với khả năng chuyển phong cách đa ngôn ngữ..

- @ketluan – Kết Luận và Hướng Phát Triển:
Tóm tắt toàn bộ đóng góp chính của khóa luận, bao gồm việc tái hiện pipeline FontDiffuser và đề xuất CL-SCR cho cross-lingual font generation.
Đề xuất các hướng nghiên cứu mở rộng, như mở rộng sang nhiều ngôn ngữ hơn (tiếng Việt, tiếng Nhật, tiếng Ả Rập), và áp dụng parameter-efficient fine-tuning (như LoRA hoặc Adapter) để tối ưu tài nguyên huấn luyện.
#pagebreak()
