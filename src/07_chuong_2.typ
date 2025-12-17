#import "/template.typ" : *

// Định nghĩa hàm hiển thị font toán học đẹp hơn (Calligraphic)
#let scr(it) = math.class("normal", box({
  show math.equation: set text(stylistic-set: 1)
  $cal(it)$
}))

#[
  #set heading(numbering: "Chương 1.1")
  = Cơ sở Lý thuyết và Tổng quan Tài liệu <chuong2>
]

Trong chương này, khoá luận trình bày hệ thống cơ sở lý thuyết nền tảng về các mô hình sinh (Generative Models) và tổng quan tình hình nghiên cứu trong lĩnh vực sinh phông chữ tự động. Cấu trúc chương đi từ các phương pháp truyền thống dựa trên GAN, đến sự trỗi dậy của Mô hình khuếch tán (Diffusion Models). Đồng thời, phần cuối chương sẽ tập trung phân tích sâu về các kỹ thuật biểu diễn phong cách (Style Representation) và những thách thức đặc thù trong bài toán chuyển đổi đa ngôn ngữ, nhằm làm rõ động lực nghiên cứu cho phương pháp đề xuất tại Chương 3.

== Tổng quan về các phương pháp Sinh phông chữ

Lĩnh vực sinh phông chữ (Font Generation) đã trải qua một sự chuyển dịch mạnh mẽ về mặt công nghệ trong thập kỷ qua. Các phương pháp hiện nay có thể được chia thành hai nhóm chính dựa trên mô hình lõi: Mạng đối nghịch sinh (GANs) và Mô hình khuếch tán (Diffusion Models).

=== Các phương pháp dựa trên GAN (GAN-based Approaches)

Trước sự bùng nổ của Diffusion Models vào năm 2023, Generative Adversarial Networks (GAN) là hướng tiếp cận chủ đạo (State-of-the-art) cho bài toán này. Các nghiên cứu GAN thường tập trung giải quyết vấn đề tách biệt nội dung (content) và phong cách (style).

==== DG-Font (Deformable Generative Network, CVPR 2021)
DG-Font tiếp cận bài toán theo hướng học không giám sát (unsupervised), tập trung giải quyết thách thức về sự sai lệch hình học giữa font nguồn và font đích. Thay vì cố gắng ép buộc mô hình học phong cách ngay lập tức, DG-Font giới thiệu mô-đun *Feature Deformation Skip Connection (FDSC)*.

Cơ chế này hoạt động bằng cách dự đoán các bản đồ dịch chuyển (displacement maps) và áp dụng tích chập biến dạng (deformable convolution) lên các đặc trưng cấp thấp. Điều này cho phép mô hình "uốn nắn" cấu trúc của ký tự nguồn sao cho khớp với dáng vẻ của ký tự đích.
Tuy nhiên, điểm yếu cố hữu của DG-Font nói riêng và GAN nói chung là sự mất ổn định trong quá trình huấn luyện (training instability). Khi gặp các ký tự có cấu trúc quá phức tạp hoặc khác biệt lớn về topo học (ví dụ từ chữ in sang chữ thư pháp), mô hình thường tạo ra các kết quả bị mờ hoặc đứt nét (broken strokes).

#figure(
      image("../images/DG/main_new.png", width: 85%),
      caption: [Kiến trúc mạng DG-Font. Mô-đun FDSC đóng vai trò nòng cốt trong việc học biến dạng hình học giữa các ký tự.]
    )

==== CF-Font (Content Fusion, CVPR 2023)
CF-Font đề xuất giải quyết vấn đề bằng cách "lai ghép" nội dung. Thay vì tin tưởng hoàn toàn vào một ảnh nguồn, CF-Font sử dụng mô-đun *Content Fusion Module (CFM)* để nội suy đặc trưng từ một tập hợp các font cơ sở (basis fonts). Phương pháp này giúp giảm thiểu việc mất mát thông tin cấu trúc, nhưng lại dễ gây ra hiện tượng "bóng ma" (ghosting artifacts) khi các font cơ sở không đủ đa dạng hoặc quá khác biệt so với font đích.

#figure(
      image("/images/CF/CF_vis.png", width: 60%),
      caption: [Minh hoạ cơ chế Content Fusion: Sự kết hợp tuyến tính các đặc trưng nội dung giúp xấp xỉ font mục tiêu tốt hơn.]
    )

==== EMD (Separating Style and Content for Generalized Style Transfer, CVPR 2018)

EMD giải quyết bài toán chuyển kiểu bằng cách tách rời hoàn toàn hai thành phần style và content. Hai encoder độc lập được huấn luyện để rút trích các đặc trưng style/content “thuần” từ những tập ảnh tham chiếu nhỏ, trong đó các ảnh được ghép theo chiều kênh để làm nổi bật tính chất chung của từng yếu tố. Hai đặc trưng này được kết hợp qua mô-đun Mixer dùng *bilinear model*, cho phép tái tổ hợp linh hoạt style và content, từ đó sinh ra ký tự mang style mới mà không cần huấn luyện lại mô hình.

Decoder đối xứng, kết hợp skip-connection từ Content Encoder, giúp khôi phục hình dạng ký tự chính xác ngay cả với các nội dung hoàn toàn mới. Nhờ kiến trúc phân tách, EMD chỉ cần rất ít ảnh tham chiếu (5–10 hình) để tái tạo trọn bộ font và có khả năng tổng quát hóa tốt hơn các phương pháp dựa trên GAN. Tuy nhiên, do không dùng adversarial loss, kết quả của EMD thường sạch và đúng cấu trúc nhưng có thể thiếu độ sắc nét hoặc chi tiết thị giác cao.

#figure(
      image("../images/FontDiffuser/EMD.pdf", width: 85%),
      caption: [Kiến trúc mạng EMD.]
    )

==== DFS (Few-Shot Text Style Transfer via Deep Feature Similarity, TIP 2020)

DFS tiếp cận bài toán chuyển kiểu chữ theo hướng few-shot, kết hợp đồng thời cả kiểu font (hình học) lẫn texture (màu sắc, hiệu ứng). Thay vì ép mô hình học trực tiếp từ tập tham chiếu nhỏ, DFS khai thác đặc trưng sâu từ hai mạng CNN độc lập: một cho content và một cho style. Các đặc trưng style của từng ký tự tham chiếu được trích xuất riêng rẽ, sau đó được *trọng số hóa theo mức độ tương đồng hình dạng* giữa từng ký tự tham chiếu và ký tự mục tiêu. Trọng số này được tính trong không gian đặc trưng thông qua normalized cross-correlation, tạo thành *Similarity Matrix* – thành phần trung tâm cho phép mô hình “ưu tiên” các ký tự tham chiếu giống nhất về cấu trúc.

Các đặc trưng style đã được điều chỉnh sau đó được gộp lại và nối với đặc trưng content, rồi đưa qua decoder đối xứng dạng U-Net để tái tạo ký tự đích trong phong cách mong muốn. Mô hình được huấn luyện end-to-end với LSGAN loss kết hợp loss tái tạo, cho phép sinh ảnh có độ chân thực cao hơn so với các phương pháp chỉ dùng CNN thuần túy.

DFS có khả năng tổng quát hóa tốt trong thiết lập few-shot, cho phép sinh trọn bộ ký tự chỉ từ 4–8 mẫu tham chiếu. Việc tách đặc trưng từng tham chiếu giúp mô hình linh hoạt về số lượng và thứ tự đầu vào, đồng thời thích ứng tốt với nhiều ngôn ngữ (Latin, Chinese). Tuy vậy, DFS vẫn phụ thuộc mạnh vào độ đa dạng ký tự tham chiếu: nếu chỉ cung cấp các ký tự ít nét hoặc thiếu cấu trúc then chốt, mô hình thường thất bại trong việc tái tạo các ký tự có hình dạng phức tạp (vòng cung, giao nét). Ngoài ra, DFS cần fine-tune theo từng style mới, nên khó áp dụng khi số lượng mẫu tham chiếu quá ít (ví dụ chỉ một ký tự).

=== Mô hình khuếch tán (Diffusion Models)

Gần đây, Mô hình khuếch tán (Diffusion Models) đã tạo nên một cuộc cách mạng trong lĩnh vực thị giác máy tính. Khác với GAN – vốn dựa trên việc lừa mô hình phân biệt, Diffusion Model mô phỏng quá trình nhiệt động lực học để biến đổi dần dần từ nhiễu sang dữ liệu có ý nghĩa.

Nguyên lí cơ bản gồm hai giai đoạn:
- *Quá trình Khuếch tán xuôi:* phá hủy dữ liệu một cách có kiểm soát bằng cách thêm nhiễu Gaussian nhiều bước.  
- *Quá trình Khuếch tán ngược:* học cách loại bỏ nhiễu từng bước để tái tạo lại dữ liệu gốc.  

Điều này tương tự như việc ta học cách "tô dần" một bức tranh từ nền trắng nhiễu cho đến khi ra ảnh rõ nét.

===== Quá trình Khuếch tán xuôi

Trong quá trình này, nhiễu được thêm dần vào dữ liệu qua một loạt các bước. Điều này tương tự như chuỗi Markov, trong đó mỗi bước làm giảm nhẹ dữ liệu bằng cách thêm nhiễu Gauss:

#figure(
  image("../images/forward_process.png"),
  caption: [Quá trình Khuếch tán xuôi]
)

Về mặt toán học, có thể được biểu diễn như sau:
$ q(x_t|x_(t-1))= scr(N)(x_t;sqrt(1-beta_t)x_(t-1),beta_t I) $

- $ x_0$: ảnh gốc (clean image).
- $x_t$: ảnh ở bước t sau khi thêm nhiễu.
- $beta_t$: hệ số nhiễu nhỏ (thường $beta_t in [10^(-4), 0.02]$).  
- $I$: ma trận đơn vị, đảm bảo nhiễu độc lập và đẳng hướng.

Do tính chất của Gaussian, ta có thể suy ra trực tiếp từ $x_0$ đến $x_t$:
$ x_t = sqrt(alpha_t)x_0 + sqrt(1-alpha_t)epsilon.alt, epsilon.alt ~ scr(N)(0,I) $

trong đó:
$ alpha_t = 1 - beta_t $
$ alpha_t = product_(s=1)^t alpha_s $

Điều này rất quan trọng vì giúp ta không cần sinh tuần tự từng bước mà vẫn có thể lấy mẫu trực tiếp ở bước t bất kì (quan trọng khi huấn luyện batch lớn).

===== Quá trình Khuếch tán ngược

// The reverse process aims to reconstruct the original data by denoising the noisy data in a series of steps reversing the forward diffusion.
// Quá trình ngược lại nhằm mục đích tái tạo dữ liệu gốc bằng cách khử nhiễu dữ liệu nhiễu trong một loạt các bước đảo ngược quá trình khuếch tán về phía trước
Quá trình này nhằm mục đích tái tạo lại dữ liệu gốc bằng cách khử nhiễu bằng một loạt các bước đảo ngược quá trình khuếch tán xuôi.

#figure(
  image("../images/backward_process.png"),
  caption: [Quá trình Khuếch tán ngược]
)

Về mặt toán học, có thể được biểu diễn như sau:
$ p_theta (x_(t-1)|x_t) = scr(N)(x_(t-1);mu_theta (x_t, t), sum_theta (x_t, t)) $

với $mu_theta$ được tính như sau:

// $$
// \mu_\theta(x_t, t) = \frac{1}{\sqrt{\alpha_t}} \Big(x_t - \frac{1 - \alpha_t}{\sqrt{1 - \bar{\alpha}_t}} \epsilon_\theta(x_t, t)\Big)
// $$

$ mu_theta (x_t, t) = 1/sqrt(alpha_t)(x_t - (1-alpha_t)/(sqrt(1 - alpha_t)) epsilon.alt_theta (x_t, t)) $

Ở đây, $epsilon.alt_theta (x_t, t)$ là nhiễu do mạng nơ-ron dự đoán, đóng vai trò trung tâm trong việc phục hồi ảnh gốc.  

Trong huấn luyện, mô hình được tối ưu để giảm sai số giữa $epsilon.alt_theta (x_t, t)$ và nhiễu thực $epsilon.alt$ mà ta đã thêm ở forward process.

===== Loss function
Hàm mất mát được sử dụng phổ biến nhất là *Mean Squared Error (MSE)*:

// $$
// \mathcal{L}_{simple} = \mathbb{E}_{t, x_0, \epsilon} \big[ \| \epsilon - \epsilon_\theta(x_t, t) \|^2 \big]
// $$

$ scr(L)_"simple" = EE_(t, x_0, epsilon.alt) [bar.v.double epsilon.alt - epsilon.alt_theta (x_t, t) bar.v.double ^2] $

Điều này tương đương với việc tối đa hóa khả năng tái tạo phân phối dữ liệu gốc (variational lower bound). Các nghiên cứu gần đây (v-prediction, hybrid loss) cho thấy việc dự đoán trực tiếp $v_t$ hoặc $x_0$ có thể cải thiện chất lượng ảnh sinh, nhưng MSE vẫn là chuẩn mực trong nhiều ứng dụng như FontDiffuser.

==== FontDiffuser (AAAI 2024)
FontDiffuser là công trình tiên phong áp dụng thành công Diffusion Model vào bài toán One-shot Font Generation. Pipeline của mô hình giải quyết ba vấn đề cốt lõi:
- *Bảo toàn cấu trúc:* Sử dụng khối *MCA (Multi-Scale Content Aggregation)* để tổng hợp thông tin cấu trúc từ toàn cục đến chi tiết.
- *Xử lý biến dạng:* Sử dụng khối *RSI (Reference-Structure Interaction)* thay thế cho các phương pháp biến dạng cũ, giúp tương thích tốt hơn giữa cấu trúc ảnh nguồn và phong cách ảnh đích.
- *Học phong cách:* Sử dụng mô-đun *SCR (Style Contrastive Refinement)* để tinh chỉnh biểu diễn phong cách.

Đây chính là mô hình cơ sở (baseline) mà khoá luận này lựa chọn để kế thừa và phát triển.

== Lý thuyết về Biểu diễn Phong cách (Style Representation)

Trong bài toán sinh phông chữ One-shot, đặc biệt là trong bối cảnh chuyển đổi đa ngôn ngữ (Cross-Lingual), việc trích xuất và biểu diễn chính xác "phong cách" (style) là yếu tố quyết định sự thành bại của mô hình.

=== Neural Style Transfer truyền thống
Các phương pháp sơ khai (như Gatys et al.) thường sử dụng Ma trận Gram (Gram Matrix) tính toán trên các bản đồ đặc trưng (feature maps) của mạng VGG pre-trained để định nghĩa phong cách.
Tuy nhiên, phương pháp này chủ yếu nắm bắt các đặc trưng về chất liệu (texture) và họa tiết cục bộ. Đối với ký tự, "phong cách" không chỉ là vân bề mặt mà còn bao gồm các yếu tố hình học cấp cao như: độ gãy khúc, kiểu chân chữ (serif/sans-serif), và cách kết thúc nét (stroke ending). Gram Matrix thường thất bại trong việc hướng dẫn mô hình áp dụng các đặc trưng này lên các cấu trúc hình học mới, dẫn đến kết quả bị biến dạng hoặc chỉ đơn thuần là phủ texture lên ảnh nội dung.

=== Học tương phản (Contrastive Learning)
Để khắc phục hạn chế trên, các nghiên cứu hiện đại (trong đó có FontDiffuser) chuyển sang hướng *Học biểu diễn tương phản (Contrastive Representation Learning)*. Tư tưởng cốt lõi là học một không gian embedding phong cách (style latent space) sao cho:
- Các mẫu có cùng phong cách (Positive samples) được kéo lại gần nhau.
- Các mẫu khác phong cách (Negative samples) bị đẩy ra xa nhau.

Hàm mất mát InfoNCE thường được sử dụng để tối ưu hóa không gian này:
$ scr(L)_"NCE" = - log (exp("sim"(z, z^+)\/tau) / (exp("sim"(z, z^+)\/tau) + sum_(k) exp("sim"(z, z_k^-)\/tau))) $

Trong FontDiffuser, mô-đun SCR áp dụng tư tưởng này để giám sát bộ mã hóa phong cách. Tuy nhiên, module này ban đầu được thiết kế cho cùng một ngôn ngữ (Hán $arrow.r$ Hán). Khi áp dụng sang bài toán Cross-Lingual, đặc biệt là dùng chữ Latin làm mẫu phong cách, các phương pháp chọn mẫu âm (negative selection) thông thường trở nên kém hiệu quả do khoảng cách miền (domain gap) quá lớn giữa hai hệ chữ.

== Thách thức trong bài toán Cross-Lingual: Từ Latin sang Hán tự

Khác với các hướng tiếp cận thông thường (Hán $arrow.r$ Hán hoặc Hán $arrow.r$ Latin), khoá luận này tập trung vào bài toán thách thức hơn: *Sử dụng ảnh phong cách Latin (Simple) để sinh ảnh nội dung Hán tự (Complex).*

=== Vấn đề Chênh lệch Mật độ Thông tin (Information Density Gap)
Đây là thách thức lớn nhất của hướng nghiên cứu này.
- *Ảnh phong cách (Latin):* Có cấu trúc đơn giản, ít nét, mật độ thông tin thấp. Ví dụ: chữ 'I' chỉ là một nét sổ, chữ 'O' là một vòng tròn.
- *Ảnh nội dung (Hán tự):* Có cấu trúc cực kỳ phức tạp, mật độ nét cao (trung bình 10-15 nét, cá biệt lên tới 30 nét), không gian bố cục chật hẹp.

Bài toán đặt ra là một dạng *"Ngoại suy phong cách" (Style Extrapolation)*: Mô hình phải học cách "tưởng tượng" xem một phong cách đơn giản (ví dụ: nét thanh đậm của chữ 'A') sẽ trông như thế nào khi áp dụng lên một cấu trúc chằng chịt như chữ '龍' (Long - Rồng). Nếu không xử lý tốt, mô hình rất dễ sinh ra các nét dính bết vào nhau (blob) hoặc làm mất đi các chi tiết phong cách khi cố gắng nhồi nhét vào cấu trúc phức tạp.

=== Khoảng cách Hình thái học (Morphological Gap)
Sự khác biệt về quy tắc viết (stroke order) và cấu tạo (topology) giữa hai hệ chữ tạo ra rào cản lớn cho việc chuyển giao phong cách:
1.  *Cấu trúc:* Latin là hệ chữ tuyến tính, độ rộng biến thiên. Hán tự là hệ chữ khối (block-based), kích thước cố định.
2.  *Đặc trưng cục bộ:* Các chi tiết phong cách đặc trưng của Latin (như serifs ở chân chữ, terminal ở đầu chữ) không có sự tương quan trực tiếp 1-1 với các bộ thủ trong tiếng Trung.

Do đó, việc áp dụng trực tiếp module SCR (Style Contrastive Refinement) nguyên bản là không đủ, vì nó không được huấn luyện để xử lý sự chênh lệch độ phức tạp này. Khoá luận này sẽ đề xuất cải tiến SCR nhằm giúp mô hình học được các đặc trưng phong cách "bất biến" (invariant style features) từ chữ Latin và áp dụng chúng một cách thông minh lên cấu trúc Hán tự phức tạp.

#pagebreak()