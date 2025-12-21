#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Giới thiệu <chuong1>
]

== Giới thiệu bài toán
Thiết kế phông chữ (Typeface design) từ lâu đã được xem là một loại hình nghệ thuật đòi hỏi sự kết hợp tinh tế giữa thẩm mĩ và kĩ thuật. Để tạo ra một bộ phông chữ hoàn chỉnh, các nhà thiết kế (typographers) phải vẽ thủ công hàng nghìn ký tự (glyphs) nhằm đảm bảo sự nhất quán về phong cách (style) như độ dày nét, hình dáng chân chữ (serif), và độ cong. Thách thức này càng trở nên lớn hơn đối với các hệ chữ tượng hình phức tạp như CJK (Chinese, Japanese, Korean), nơi số lượng ký tự có thể lên tới hàng chục nghìn. Do đó, các phương pháp truyền thống dựa trên nội suy (interpolation) hoặc vector hóa thủ công thường tốn kém nhiều chi phí, thời gian và khó mở rộng quy mô.

Trong bối cảnh đó, bài toán Sinh phông chữ tự động (Automatic Font Generation) đã trở thành một hướng nghiên cứu mũi nhọn trong lĩnh vực Thị giác máy tính (Computer Vision) và Học sâu (Deep Learning). Sự chuyển dịch từ các mô hình Generative Adversarial Networks (GANs)@Goodfellow2014GAN sang Denoising Diffusion Probabilistic Models (DDPMs)@SohlDickstein2015ICML@Ho2020DDPM gần đây đã tạo ra bước đột phá về chất lượng ảnh sinh. Các mô hình Diffusion, điển hình như FontDiffuser@Yang2024FontDiffuser, đã chứng minh khả năng vượt trội trong việc tái tạo các chi tiết nét chữ phức tạp và duy trì cấu trúc tô pô học của ký tự mà không gặp phải các vấn đề về mất ổn định khi huấn luyện (mode collapse) thường thấy ở GAN@Goodfellow2014GAN.

Tuy nhiên, phần lớn các nghiên cứu hiện tại chỉ tập trung vào bài toán đơn ngôn ngữ (intra-lingual), tức là sinh chữ cái Latin từ mẫu Latin, hoặc sinh chữ Hán từ mẫu Hán@Xie2021DGFont@Wang2023CFFont@Park2021LFFont@Park2021MXFont@Tang2022FsFont@Kong2022CGGAN. Một thách thức lớn hơn và vẫn còn nhiều "khoảng trống" nghiên cứu là bài toán sinh phông chữ đa ngôn ngữ (cross-lingual font generation).

Vấn đề cốt lõi của bài toán đa ngôn ngữ nằm ở "khoảng cách miền" (domain gap) giữa các hệ chữ viết. Ví dụ, việc chuyển đổi phong cách từ một chữ Hán (với cấu trúc nét phức tạp, ô vuông) sang chữ cái Latin (cấu trúc đơn giản, tuyến tính) đòi hỏi mô hình phải có khả năng:

#tab_eq[
  *Tách biệt hoàn toàn (Disentanglement)* giữa *nội dung (content)* và *phong cách (style)*.
  #parbreak()

  Học được các *đặc trưng phong cách bất biến (invariant style features)* – những đặc điểm thẩm mỹ trừu tượng không phụ thuộc vào cấu trúc hình học của ngôn ngữ gốc.
  ]

#untab_para[
  Đây là một bài toán khó, bởi nếu không được xử lý tốt, mô hình thường có xu hướng "áp đặt" cấu trúc của ngôn ngữ nguồn lên ngôn ngữ đích, dẫn đến các ký tự bị biến dạng hoặc mất đi tính dễ đọc (legibility).
  ]

== Mô tả bài toán
Phần này sẽ định nghĩa bài toán sinh phông chữ đa ngôn ngữ dưới dạng một bài toán chuyển đổi phong cách ảnh (Image-to-Image Translation)@Isola2017Pix2Pix@Liu2017UNIT@Zhu2017CycleGAN@Liu2019FUNIT có điều kiện.

=== Định nghĩa Đầu vào (Input)
Mô hình nhận vào hai luồng thông tin chính: #linebreak()
#h(1.5em) _*Ảnh tham chiếu nội dung (Content Image - *_$I_c$)_*:*_
#tab_eq(indent: 3em, space: 1.2em)[
  Là một *hình ảnh chứa ký tự mục tiêu $c$ (target glyph)* trong một phông chữ tiêu chuẩn (ví dụ: Arial hoặc Noto Sans).
  #parbreak()

  _*Mục đích:*_ *Cung cấp thông tin về cấu trúc hình học và định danh của ký tự cần sinh* (ví dụ: chữ 'A', chữ 'g').
  #parbreak()

  Trong bài toán cross-lingual, $I_c$ *thuộc _hệ ngôn ngữ đích_* (Target Language, ví dụ: Latin).
  ]

#figure(
  kind: image,
  caption: [Ví dụ minh hoạ các ảnh mẫu trong tập dữ liệu.],
  grid(
    columns: 3,
    gutter: 8pt,

    image("../images/example_image/ダ.png", width: auto),
    image("../images/example_image/c.png", width: auto),
    image("../images/example_image/L+.png", width: auto),
  )
)

#h(1.5em) _*Ảnh tham chiếu phong cách (Style Images - *_$I_s$)_*:*_
#tab_eq(indent: 3em, space: 1.2em)[
  Là *tập hợp một hoặc một vài hình ảnh ($k$-shot)* chứa *các ký tự bất kỳ mang phong cách $s$ mong muốn*.
  #parbreak()

  _*Mục đích:*_ *Cung cấp các đặc trưng thẩm mỹ (nét xước, độ đậm nhạt, serif...)*.
  #parbreak()

  Trong bài toán cross-lingual, $I_s$ thường *thuộc _hệ ngôn ngữ nguồn_* (Source Language, ví dụ: Chinese) khác với ngôn ngữ của $I_c$.
  ]

#figure(
  kind: image,
  caption: [Ví dụ minh hoạ các ảnh tham chiếu phong cách.],
  grid(
    columns: 3,
    gutter: 8pt,

    image("../images/example_image/║║╥╟▒¿╦╬╝≥_chinese+产.png", width: auto),
    image("../images/example_image/A-OTF-ShinMGoMin-Shadow-2_english+M+.png", width: auto),
    image("../images/example_image/Bai zhou Tian zhen shu ti Font-Traditional Chinese_english+m.png", width: auto),
  )
)
  
=== Định nghĩa Đầu ra (Output)
_*Ảnh được sinh ra (Generated Image - $I_"gen"$):*_ Là hình ảnh kết quả thể hiện ký tự $c$ nhưng mang phong cách $s$.
#linebreak()
_*Yêu cầu:*_ $I_"gen"$ phải giữ được cấu trúc nội dung của $I_c$ (đọc được là chữ gì) và mang đầy đủ đặc điểm thẩm mỹ của $I_s$ (nhìn giống font mẫu).

=== Mục tiêu toán học
Mục tiêu là huấn luyện một hàm ánh xạ $G$ (Generator/Diffusion Model) sao cho:
$ I_"gen" = G(I_c, I_s) $
Thỏa mãn điều kiện: 
$"Content"(I_"gen") approx "Content"(I_c)$ và $"Style"(I_"gen") approx "Style"(I_s)$.

== Mục tiêu của đề tài
Khoá luận này đề xuất mở rộng mô hình FontDiffuser để giải quyết bài toán *sinh phông chữ đa ngôn ngữ (Cross-lingual Font Generation)*, cụ thể:
#tab_eq[
  Thiết kế quy trình (pipeline) cho phép chuyển đổi phong cách hai chiều linh hoạt: trích xuất phong cách từ hệ chữ Latin để áp dụng lên Hán tự và ngược lại.
  #parbreak()

  Đề xuất cơ chế *Cross-Lingual Style Contrastive Refinement (CL-SCR)* cải tiến từ mô-đun SCR gốc, tích hợp chiến lược lấy mẫu âm đa dạng (cả nội miền và xuyên miền) nhằm buộc mô hình học được các đặc trưng phong cách bất biến, không phụ thuộc vào ngôn ngữ.
  #parbreak()

  Thực hiện huấn luyện và tinh chỉnh mô hình khuếch tán trên dữ liệu song ngữ, đồng thời đánh giá toàn diện chất lượng đầu ra dựa trên các thước đo định lượng (LPIPS, FID, SSIM, L1) và khảo sát cảm nhận người dùng.
  ]

#untab_para[
  Mục tiêu cuối cùng là tạo ra một mô hình có khả năng sinh bộ font nhất quán đa ngôn ngữ chỉ từ một mẫu tham chiếu duy nhất, mở ra tiềm năng ứng dụng trong số hoá phông chữ, thiết kế tự động và cá nhân hoá chữ viết xuyên biên giới.
  ] 

== Đối tượng và phạm vi nghiên cứu
Để đảm bảo tính khả thi và tập trung sâu vào giải pháp kỹ thuật, đề tài xác định rõ đối tượng và giới hạn phạm vi nghiên cứu như sau:

=== Đối tượng nghiên cứu
_*Mô hình lý thuyết và phát triển:*_ Trọng tâm nghiên cứu được đặt vào *Mô hình sinh ảnh dựa trên cơ chế khuếch tán (Diffusion Models)*, lấy kiến trúc *FontDiffuser* làm nền tảng cốt lõi để cải tiến. Đề tài tập trung nghiên cứu các kỹ thuật *điều hướng phong cách (Style Guidance)* và cơ chế *học tương phản (Contrastive Learning)* trong không gian khuếch tán nhằm giải quyết bài toán chuyển đổi đa ngôn ngữ.

_*Mô hình đối chứng (Baseline):*_ Để thiết lập một hệ quy chiếu đánh giá toàn diện và làm nổi bật ưu thế của phương pháp đề xuất, khóa luận thực hiện so sánh với *hai nhóm phương pháp hiện có*. Nhóm thứ nhất bao gồm *các phương pháp dựa trên GAN@Goodfellow2014GAN tiên tiến* như *DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle và FTransGAN@Li2021FTransGAN*, nhằm chứng minh khả năng vượt trội của mô hình Khuếch tán trong việc tạo ra hình ảnh chất lượng cao và ổn định. Nhóm thứ hai là *mô hình FontDiffuser nguyên bản@Yang2024FontDiffuser*, được sử dụng để đối sánh trực tiếp nhằm định lượng chính xác hiệu quả đóng góp của các cải tiến kỹ thuật được đề xuất trong khóa luận (như mô-đun CL-SCR) so với thuật toán ban đầu.

_*Đối tượng dữ liệu:*_ Khoá luận sử dụng *hai hệ chữ viết có đặc trưng hình thái đối lập*. Hệ chữ nguồn bao gồm các bộ phông chữ chứa ký tự Hán (theo chuẩn GB2312) với độ phức tạp cấu trúc đa dạng. Đối ứng với đó là hệ chữ đích gồm bộ 52 ký tự tiếng Anh cơ bản (26 chữ hoa và 26 chữ thường) thuộc hệ Latin.

=== Phạm vi nghiên cứu
_*Phạm vi về ngôn ngữ:*_ Đề tài tập trung nghiên cứu và thực nghiệm trên bài toán *chuyển đổi phong cách hai chiều (Bidirectional Transfer)* giữa Tiếng Anh (Latin) và Tiếng Trung Quốc (Hán). Việc lựa chọn cặp ngôn ngữ này nhằm giải quyết hai thách thức bổ trợ cho nhau. Ở hướng Latin sang Hán tự (`e2c`), thách thức nằm ở việc ngoại suy phong cách từ một hệ chữ đơn giản, cấu trúc thưa sang một hệ chữ phức tạp hơn rất nhiều, đòi hỏi mô hình phải học cách áp dụng phong cách lên các cấu trúc dày đặc mà không làm vỡ nét. Ngược lại, ở hướng Hán tự sang Latin (`c2e`), thách thức nằm ở việc trích xuất phong cách từ hệ chữ nhiều chi tiết để áp dụng lên hệ chữ đơn giản, buộc mô hình phải có khả năng tổng quát hóa cao để lọc bỏ các nhiễu cấu trúc.

_*Phạm vi về bài toán:*_ Khoá luận tập trung vào *bài toán One-shot Generation*, trong đó mô hình chỉ được cung cấp một ký tự duy nhất làm ảnh tham chiếu phong cách (Style Reference) để sinh ra ký tự mục tiêu mang nội dung khác. Cụ thể, một ký tự Latin sẽ được dùng để định hình phong cách cho một Hán tự ở chiều xuôi, và một ký tự Hán sẽ được dùng để định hình phong cách cho một chữ cái Latin ở chiều ngược.

_*Phạm vi về dữ liệu:*_ Sử dụng *các bộ dữ liệu phông chữ mã nguồn mở hỗ trợ đồng thời cả hai bảng mã*, ví dụ như các bộ font thuộc dự án Google Noto CJK hoặc các font nghệ thuật song ngữ. Điều này nhằm đảm bảo luôn tồn tại cặp dữ liệu đối chứng (Ground Truth) chính xác: cùng một bộ font phải chứa cả ký tự Hán và Latin tương ứng để phục vụ cho quá trình huấn luyện giám sát và đánh giá định lượng.

== Cấu trúc của khoá luận
Phần còn lại của khoá luận này được trình bày như sau:

#tab_eq[
  *@chuong2 – Cơ sở lý thuyết:*
  #parbreak()
  Trình bày các khái niệm nền tảng về bài toán sinh font chữ. Đồng thời, chương này tổng hợp và phân tích các phương pháp sinh font trước đây, bao gồm nhóm mô hình dựa trên GAN@Goodfellow2014GAN (DG-Font@Xie2021DGFont, CF-Font@Wang2023CFFont, DFS@Zhu2020FewShotTextStyle, FTransGAN@Li2021FTransGAN) và nhóm mô hình khuếch tán@SohlDickstein2015ICML (FontDiffuser@Yang2024FontDiffuser), chỉ ra ưu nhược điểm và xu hướng phát triển.
  #parbreak()

  *@chuong3 – Phương pháp đề xuất:*
  #parbreak()
  Trình bày chi tiết pipeline gốc của FontDiffuser@Yang2024FontDiffuser, bao gồm hai giai đoạn huấn luyện (Giai đoạn 1 – Tái tạo cấu trúc, Giai đoạn 2 – Tinh chỉnh phong cách).
  Phân tích cơ chế hoạt động của các mô-đun chính như MCA (Multi-scale Content Aggregation), RSI (Reference-Structure Interaction) và SCR (Style Contrastive Refinement).
  Trên cơ sở đó, chương này giới thiệu ý tưởng cải tiến nhằm mở rộng khả năng chuyển phong cách đa ngôn ngữ (cross-lingual style transfer) thông qua việc thay thế và điều chỉnh mô-đun SCR.
  #parbreak()

  *@chuong4 – Thực nghiệm và Đánh giá kết quả:*
  #parbreak()
  Chương này mô tả chi tiết quy trình thiết lập thực nghiệm, bao gồm việc xây dựng tập dữ liệu đa ngôn ngữ (Latin–Hán), cấu hình huấn luyện và các tiêu chí đánh giá được sử dụng (FID@Heusel2017TTUR, SSIM@Wang2004SSIM, LPIPS@Zhang2018LPIPS, L1, User Study). Đồng thời, chương trình bày các kết quả định lượng, định tính và đánh giá của con người, so sánh mô hình đề xuất (FontDiffuser + CL-SCR) với các mô hình nền tảng (GAN-based và Diffusion-based). Phần phân tích chuyên sâu sẽ đánh giá hiệu quả của mô-đun CL-SCR, nghiên cứu Ablation về các thành phần cải tiến, và thảo luận về ưu điểm, hạn chế cũng như ảnh hưởng của các tham số then chốt (như số lượng mẫu âm, Guidance Scale) đối với khả năng chuyển phong cách đa ngôn ngữ..
  #parbreak()

  *@ketluan – Kết luận và Hướng phát triển:*
  #parbreak()
  Tóm tắt toàn bộ đóng góp chính của khóa luận, bao gồm việc tái hiện pipeline FontDiffuser và đề xuất CL-SCR cho cross-lingual font generation.
  Đề xuất các hướng nghiên cứu mở rộng, như mở rộng sang nhiều ngôn ngữ hơn (tiếng Việt, tiếng Nhật, tiếng Ả Rập), và áp dụng parameter-efficient fine-tuning (như LoRA@Hu2022LoRA hoặc Adapter@Houlsby2019PETL) để tối ưu tài nguyên huấn luyện.

  *#link(<phuluc>)[Phụ lục] – Trình bày phụ lục của khoá luận:*
  ]

#pagebreak()
