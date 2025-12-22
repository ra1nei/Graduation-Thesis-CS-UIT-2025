#import "/template.typ" : *
#import "@preview/algo:0.3.4": algo, i, d, comment, code

#[
  #set heading(numbering: "Chương 1.1")
  = Phương pháp đề xuất <chuong3>
]

Trong chương trước, khoá luận đã phân tích các hạn chế của phương pháp GAN@Goodfellow2014GAN và tiềm năng của Mô hình khuếch tán (Diffusion Models)@SohlDickstein2015ICML trong bài toán sinh phông chữ. Dựa trên cơ sở đó, chương này trình bày chi tiết phương pháp nghiên cứu được đề xuất.

Cụ thể, khoá luận kế thừa kiến trúc tiên tiến *FontDiffuser*@Yang2024FontDiffuser làm mô hình cơ sở (baseline) và đề xuất một cải tiến quan trọng tại giai đoạn tinh chỉnh phong cách (Phase 2) mang tên *Cross-Lingual Style Contrastive Refinement (CL-SCR)*. Mục tiêu của cải tiến này là giải quyết vấn đề về sự không nhất quán phong cách khi chuyển đổi giữa các hệ ngôn ngữ có cấu trúc khác biệt (như từ chữ Latin sang Hán tự).

Cấu trúc chương bao gồm: trình bày kiến trúc tổng thể của FontDiffuser@Yang2024FontDiffuser, phân tích cơ chế hoạt động của mô-đun SCR gốc, và cuối cùng là chi tiết về giải pháp CL-SCR được đề xuất cho bài toán đa ngôn ngữ.

== Kiến trúc nền tảng FontDiffuser

FontDiffuser được thiết kế dưới dạng một mô hình khuếch tán có điều kiện (Conditional Diffusion Model - CDM), mô hình hoá bài toán sinh phông chữ dưới dạng quy trình "khử nhiễu" (noise-to-denoise).

#figure(
  image("../images/FontDiffuser/framework.pdf"),
  caption: [Mô hình tổng thể của FontDiffuser gồm 2 giai đoạn: #linebreak() Tái tạo cấu trúc (Trái) và Tinh chỉnh phong cách (Phải).]
)

Mô hình nhận hai đầu vào chính:
- *Ảnh nội dung (Source Image) $x_c$*: Cung cấp thông tin về cấu trúc nét, bố cục của ký tự gốc (ví dụ: một chữ cái Arial cơ bản).
#figure(
  image("../images/example_image/丈.png", width: 20%),
  caption: [Ví dụ về ảnh nội dung.]
)

- *Ảnh phong cách (Reference Image) $x_s$*: Cung cấp thông tin về kiểu dáng, độ đậm nhạt, serif, và các đặc trưng thẩm mỹ (ví dụ: một chữ cái thư pháp).
#figure(
  image("../images/example_image/A-OTF-ShinMGoMin-Shadow-2_english+M+.png", width: 20%),
  caption: [Ví dụ về ảnh phong cách.]
)

Đầu ra của mô hình là ảnh $x_0$ – một ký tự mới mang nội dung của $x_c$ nhưng khoác lên mình phong cách của $x_s$.
#figure(
  image("../images/example_image/A-OTF-ShinMGoMin-Shadow-2_chinese+丈.png", width: 20%),
  caption: [Ví dụ về ảnh đầu ra.]
)

Quy trình huấn luyện được chia thành hai giai đoạn (phases) tuần tự nhằm đảm bảo chất lượng sinh ảnh tối ưu:

=== Giai đoạn 1 - Tái tạo cấu trúc (Reconstruction Phase)
Mục tiêu của giai đoạn này là huấn luyện mô hình khuếch tán học cách khôi phục lại hình ảnh ký tự mục tiêu từ nhiễu, dựa trên điều kiện $x_c$ và $x_s$. Các thành phần cốt lõi bao gồm *Bộ mã hoá nội dung ($E_c$) và phong cách ($E_s$)* - dùng để *trích xuất đặc trưng ngữ nghĩa*.

==== Multi-scale Content Aggregation (MCA) 
Đây là cơ chế tổng hợp đặc trưng đa tỉ lệ được thiết kế để giải quyết hạn chế của các phương pháp chỉ dựa vào một mức đặc trưng duy nhất. Khi sinh các ký tự phức tạp, một tầng đặc trưng đơn lẻ thường không thể đồng thời nắm bắt được cả bố cục tổng thể lẫn những chi tiết tinh vi như nét mảnh, bộ phận nhỏ hoặc các dấu thanh. MCA khắc phục điều này bằng cách trích xuất nhiều mức đặc trưng nội dung từ các tầng khác nhau của bộ mã hoá, sau đó đưa chúng vào các khối UNet tương ứng.

Cụ thể, quy trình hoạt động như sau:
1. Ảnh tham chiếu $x_c$ trước hết được nhúng bởi bộ mã hoá nội dung $E_c$ để thu được các đặc trưng đa tỷ lệ $F_c = \{f_c^1, f_c^2, f_c^3\}$ từ các tầng khác nhau.
2. Mỗi đặc trưng nội dung $f_c^i$ được đưa vào UNet thông qua ba khối MCA tương ứng. Tại đây, $f_c^i$ được ghép nối (concatenated) với đặc trưng của khối UNet trước đó là $r_i$, tạo ra đặc trưng giàu thông tin $I_c$.
3. Để tăng cường khả năng chọn lọc kênh thích ứng, áp dụng cơ chế chú ý kênh (channel attention) lên $I_c$. Cơ chế này sử dụng một lớp gộp trung bình (average pooling), hai lớp tích chập $1 times 1$ và một hàm kích hoạt để tạo ra vector nhận biết kênh toàn cục $W_c$.
4. Vector $W_c$ sau đó được dùng để trọng số hoá $I_c$ thông qua phép nhân theo kênh (channel-wise multiplication).
5. Sau khi đi qua một kết nối phần dư (residual connection), một lớp tích chập $1 times $ được sử dụng để giảm số lượng kênh, thu được đầu ra $I_{co}$.
6. Cuối cùng, một mô-đun cross-attention được áp dụng để chèn style embedding $e_s$, trong đó $e_s$ đóng vai trò là Key và Value, còn $I_{co}$ đóng vai trò là Query.
  
Nhờ MCA, mô hình có thể tái hiện chính xác cả những thành phần nhỏ và các nét đặc trưng tinh tế—một yếu tố đặc biệt quan trọng đối với những hệ chữ có độ phức tạp cao, bao gồm các ký tự chứa nhiều bộ thủ hoặc các dấu thanh đòi hỏi độ chính xác cao.

#figure(
  image("../images/FontDiffuser/MCA.pdf"),
  caption: [Khối MCA (Multi-scale Content Aggregation).]
)

#figure(
  image("../images/FontDiffuser/multi-scale_content_feature.pdf"),
  caption: [Đặc trưng Content ở các khối khác nhau.]
)

==== Reference-Structure Interaction (RSI)
Giữa ảnh nguồn và ảnh đích thường tồn tại những khác biệt đáng kể về mặt cấu trúc (ví dụ: kích thước phông chữ) cũng như sự lệch lạc về vị trí không gian (spatial misalignment) giữa đặc trưng của UNet và đặc trưng tham chiếu. Để giải quyết vấn đề này, nhóm tác giả đã đề xuất khối Tương tác Cấu trúc - Tham chiếu (RSI). Khối này sử dụng mạng tích chập biến hình (Deformable Convolutional Networks - DCN) để thực hiện biến đổi cấu trúc ngay trên kết nối tắt (skip connection) của UNet.

Điểm khác biệt so với các phương pháp trước đây là thay vì sử dụng CNN truyền thống để tính toán độ lệch (offset) $ delta_"offset"$ — vốn hạn chế trong việc nắm bắt thông tin toàn cục — nhóm tác giả đã tích hợp cơ chế Cross-Attention để kích hoạt các tương tác tầm xa (long-distance interactions).

Quy trình cụ thể diễn ra như sau:
#tab_eq[
  1. Ảnh tham chiếu $x_c$ trước hết được nhúng bởi bộ mã hoá nội dung $E_c$ để thu các bản đồ cấu trúc (structure maps) $F_s = {f_s^1, f_s^2}$.

  2. Tại mỗi tầng, RSI tiếp nhận các đặc trưng từ UNet ($r_i$) và bản đồ cấu trúc tương ứng ($f_s^i$). Cả hai được làm phẳng (flatten) thành chuỗi vector $S_r$ và $S_s$.

  3. Cơ chế Cross-Attention được áp dụng để tính toán vùng quan tâm (region of interest) thông qua phép chiếu tuyến tính $phi.alt$:
  #tab_eq(indent: 3em)[
    *Query (Q)*: Được tạo ra từ đặc trưng tham chiếu $S_s (phi.alt_q (S_s))$.

    *Key (K) và Value (V)*: Được tạo ra từ đặc trưng UNet $S_r (phi.alt_k (S_r), phi.alt_v (S_r))$.  
  ]

  4. Đặc trưng chú ý $F_"attn"$ được tính toán thông qua hàm Softmax, sau đó được đưa qua mạng truyền thẳng (Feed-Forward Network - FFN) để sinh ra độ lệch cấu trúc $delta_"offset"$.

  5. Cuối cùng, DCN sử dụng độ lệch này để "uốn nắn" đặc trưng UNet, tạo ra đầu ra $I_R$ đã được că chỉnh.
  $ I_R = "DCN"(r_i, delta_"offset") $
]


Thông qua cơ chế này, RSI có khả năng trích xuất trực tiếp thông tin cấu trúc từ ảnh tham chiếu và điều chỉnh linh hoạt đặc trưng của ảnh nguồn, đảm bảo sự tương thích về phong cách mà không làm gãy vỡ các nét chi tiết.

=== Giai đoạn 2 - Tinh chỉnh phong cách (Style Refinement Phase)
Mặc dù Giai đoạn 1 có thể tạo ra ký tự rõ nét, nhưng phong cách thường chưa được tách biệt hoàn toàn. Giai đoạn 2 cố định các trọng số của UNet và tập trung huấn luyện mô-đun *Style Contrastive Refinement (SCR)*. Mô-đun này đóng vai trò như một người hướng dẫn, sử dụng cơ chế học tương phản (Contrastive Learning) để ép buộc mô hình sinh ra ảnh có style vector gần với ảnh tham chiếu nhất có thể.

== Mô-đun Style Contrastive Refinement (SCR Module) <phantich_scr>

Trong bài toán sinh phông chữ (font generation), mục tiêu cốt lõi của việc sinh phông chữ là đạt được hiệu ứng bắt chước phong cách (style imitation) chính xác, độc lập với sự biến thiên về phong cách giữa ảnh nguồn và ảnh tham chiếu. Trong các mô hình sinh ảnh truyền thống, sự vướng víu (disentanglement) giữa đặc trưng phong cách và nội dung thường không hoàn hảo, dẫn đến kết quả phong cách không nhất quán. Để giải quyết vấn đề này, nhóm tác giả đề xuất một chiến lược mới: xây dựng mô-đun *Style Contrastive Refinement (SCR)*.

Mô-đun Style Contrastive Refinement (SCR) được đề xuất như một chiến lược mới để giải quyết vấn đề này. SCR hoạt động như một cơ chế học biểu diễn (representation learning mô-đun) và một bộ giám sát đặc trưng (feature supervisor). Nó không tham gia trực tiếp vào quá trình sinh ảnh pixel-wise của mô hình khuếch tán (diffusion model), mà có nhiệm vụ cung cấp tín hiệu điều hướng, đảm bảo phong cách của ảnh sinh ra ($x_0$) phải nhất quán với ảnh đích ($x_p$) ở cả cấp độ toàn cục và cục bộ.

=== Kiến trúc Khai thác Phong cách
Kiến trúc của SCR, như được minh họa trong thiết kế hệ thống, bao gồm hai thành phần chính:

#figure(
  image("../images/FontDiffuser/Style Contrastive Refinement.png"),
  caption: [Minh hoạ mô-đun SCR.]
)

1. *Bộ trích xuất Đặc trưng (Style Extractor)*:
#tab_eq[
  #h(1.5em) Sử dụng một mạng *VGG* (lấy cảm hứng từ Zhang et al. 2022@Sun2018PyramidGAN) để nhúng ảnh phông chữ, khai thác các đặc tính phong cách và cấu trúc.

  Để bao phủ đầy đủ cả phong cách cục bộ (như nét bút, serifs) và toàn cục (như độ đậm, độ nghiêng), bộ trích xuất chọn ra $N$ tầng feature maps, ký hiệu là $F_v = {f_v^0, f_v^1, ..., f_v^N}$.
]

2. *Bộ chiếu Đặc trưng (Style Projector)*: 
  - Các feature maps $F_v$ được đưa vào bộ chiếu. Tại đây, áp dụng đồng thời *average pooling* và *maximum pooling* để trích xuất các đặc trưng kênh toàn cục khác nhau.
  - Kết quả từ hai phép pooling được nối (concatenate) theo chiều kênh, tạo thành đặc trưng tổng hợp $F_g$.
  - Cuối cùng, $F_g$ được đưa qua các phép chiếu tuyến tính (linear projections) để thu được các *vector phong cách* $V = {v^0, v^1, ..., v^N}$. Các vector này đóng vai trò là đầu vào cho hàm mất mát tương phản.

=== Cơ chế Học Tương phản và Hàm Mất mát
SCR sử dụng chiến lược học tương phản (Contrastive Learning), vận dụng hàm mất mát $L_"sc"$ để điều hướng mô hình khuếch tán.

==== Chiến lược Thiết lập Mẫu
Để đảm bảo tính liên quan về nội dung nhưng phân biệt rõ ràng về phong cách, SCR lựa chọn mẫu cẩn thận:
#tab_eq[
  *Mẫu sinh ra (Generated Sample - $x_0$)*: Ảnh được tạo ra bởi mô hình khuếch tán.

  *Mẫu dương (Positive Sample - $x_p$)*: Là ảnh đích (target image) mang phong cách mong muốn. Để tăng cường *tính bền vững (robustness)* của quá trình bắt chước phong cách, một chiến lược tăng cường dữ liệu (augmentation strategy) được áp dụng trên $x_p$, bao gồm *cắt ngẫu nhiên (random cropping)* và *thay đổi kích thước ngẫu nhiên (random resizing)*.

  *Mẫu âm (Negative Samples - $x_n$)*: Là $K$ mẫu ảnh có *cùng nội dung* ký tự với $x_p$ và $x_0$ nhưng mang *phong cách khác biệt*.
]


// DEBUG: Chèn hình ví dụ ở đây

==== Định nghĩa hàm mất mát
Hàm mất mát $L_"sc"$ (còn được gọi là $L_"SCR"$ trong công thức tổng thể) là một dạng của hàm *InfoNCE@Oord2018InfoNCE* được tính tổng trên $N$ tầng đặc trưng:

$ L_"sc" = -sum_(l=0)^(N-1) log exp(v_0^l dot v_p^l "/" tau) / (exp(v_0^l dot v_p^l "/" tau) + sum_(i=1)^K exp(v_0^l dot v_(n_i)^l "/" tau) $ <L_sc_equa>

Trong đó:
#tab_eq[
  *$L_"sc"$*: Giá trị hàm mất mát tương phản phong cách.

  *$N$*: Tổng số tầng đặc trưng được sử dụng để trích xuất và so sánh.

  *$l$*: Chỉ số đại diện cho tầng đặc trưng đang xét (từ $0$ đến $N-1$).

  *$v_0^l$*: Vector đặc trưng lớp $l$ của ảnh sinh (ảnh kết quả cần tối ưu).

  *$v_p^l$*: Vector đặc trưng lớp $l$ của ảnh dương/ảnh mẫu (ảnh chứa phong cách mục tiêu).
  
  *$v_(n_i)^l$*: Vector đặc trưng lớp $l$ của ảnh âm thứ $i$ (các ảnh khác phong cách cần loại bỏ).

  *$K$*: Số lượng mẫu ảnh âm được sử dụng để so sánh trong công thức.

  *$v dot v'$*: Phép nhân vô hướng, biểu thị độ tương đồng Cosine giữa hai vector (đo mức độ giống nhau về phong cách).

  *$tau$*: Tham số nhiệt độ (được thiết lập là $0.07$), dùng để điều chỉnh độ nhạy của hàm mất mát.
]

#untab_para[
  Thông qua việc tối thiểu hoá hàm mất mát này, mô hình được định hướng để kéo vector phong cách của ảnh sinh lại gần vector của ảnh đích, đồng thời đẩy xa khỏi các vector của các phong cách không mong muốn.
]

== Kết hợp vào Mục tiêu Huấn luyện
Để đạt được sự cân bằng giữa việc tái tạo nội dung chính xác và bắt chước phong cách tinh tế, quy trình huấn luyện của FontDiffuser áp dụng chiến lược *hai giai đoạn*: *từ thô đến tinh (coarse-to-fine two-phase strategy)*.

1. *Giai đoạn 1 - Tái tạo Cấu trúc (Phase 1 - Coarse Stage)*: 
Trong giai đoạn đầu, mục tiêu là tối ưu hoá FontDiffuser để mô hình đạt được năng lực nền tảng trong việc tái tạo cấu trúc phông chữ (font reconstruction). Tại bước này, mô-đun SCR *chưa được kích hoạt*.
Hàm mất mát tổng thể cho giai đoạn 1 ($L_"total"^1$) là sự kết hợp của ba thành phần:

$ L_"total"^1 = L_"MSE" + lambda_"cp"^1 L_"cp" + lambda_"off"^1 L_"offset" $

Chi tiết các thành phần:
#tab_eq[
  *_Hàm mất mát Khuếch tán Tiêu chuẩn_ ($L_"MSE"$)*: Đây là hàm mất mát cơ bản của mô hình khuếch tán, chịu trách nhiệm tính toán sai số giữa nhiễu dự đoán $epsilon_theta$ và nhiễu thực tế $epsilon$ tại bước thời gian $t$, với điều kiện đầu vào là ảnh nội dung $x_c$ và ảnh phong cách $x_s$:
  $ L_"MSE" = ||epsilon - epsilon_theta(x_t, t, x_c, x_s)||^2 $
  
  #h(1.5em) *_Hàm mất mát Nhận thức Nội dung_ ($L_"cp"$ - Content Perceptual Loss)*: Thành phần này được sử dụng để trừng phạt sự lệch lạc về nội dung (content misalignment) giữa ảnh sinh ra $x_0$ và ảnh đích $x_"target"$. Khoá luận sử dụng các đặc trưng được mã hoá bởi mạng VGG@SimonyanZ14aVGG ($"VGG"_l(dot)$) trên $L$ tầng được chọn:
  $ L_"cp" = sum_(l=1)^L ||"VGG"_l (x_0) - "VGG"_l (x_"target")|| $
  
  #h(1.5em) *_Hàm mất mát Độ lệch_($L_"offset"$ - Offset Loss)*: Được thiết kế riêng cho mô-đun RSI (Reference-Structure Interaction), hàm này ràng buộc độ lớn của các vector dịch chuyển $delta_"offset"$ nhằm ngăn chặn các biến dạng cấu trúc quá mức, trong đó mean là phép tính trung bình:
  $ L_"offset" = "mean"(||delta_"offset"||) $
]

#untab_para[
  Các siêu tham số trọng số cho giai đoạn 1 được thiết lập là: $lambda_"cp"^1 = 0.01$ và $lambda_"off"^1 = 0.5$.
]

2. *Giai đoạn 2 - Tinh chỉnh Phong cách (Phase 2 - Fine Stage)*:
Sau khi mô hình đã nắm bắt được cấu trúc, giai đoạn 2 sẽ kích hoạt mô-đun *SCR (Style Contrastive Refinement)*. Mục đích là tích hợp hàm mất mát tương phản phong cách ($L_"sc"$) để cung cấp tín hiệu hướng dẫn (guidance), giúp mô hình khuếch tán tinh chỉnh các chi tiết phong cách ở cả cấp độ toàn cục và cục bộ.

Hàm mất mát tổng thể cho giai đoạn 2 ($L_"total"^2$) được mở rộng như sau:
$ L_"total"^2 = L_"MSE" + lambda_"cp"^2 L_"cp" + lambda_"off"^2 L_"offset" + lambda_"sc"^2 L_"sc" $

Trong giai đoạn này, các trọng số được giữ nguyên cho các thành phần trước và bổ sung trọng số cho thành phần mới:
#tab_eq[
  *$lambda_"cp"^2 = 0.01$* (trọng số nội dung).

  *$lambda_"off"^2 = 0.5$* (trọng số độ lệch RSI).

  *$lambda_"sc"^2 = 0.01$* (trọng số tương phản phong cách).
]

#untab_para[
  Việc bổ sung $L_"sc"$ (như đã định nghĩa ở Phương trình @L_sc_equa trong phần phân tích SCR (@phantich_scr)) đóng vai trò then chốt trong việc đảm bảo ảnh đầu ra không chỉ đúng về cấu trúc (nhờ $L_"cp", L_"offset"$) mà còn đạt độ chân thực cao về phong cách nghệ thuật.
]

== Cải tiến đề xuất: Cross-Lingual Style Contrastive Refinement (CL-SCR)

=== Hạn chế của SCR trong bối cảnh đa ngôn ngữ
Mô-đun SCR tiêu chuẩn (Standard SCR) hoạt động dựa trên giả định rằng ảnh nguồn và ảnh tham chiếu chia sẻ cùng một không gian hình thái (cùng một ngôn ngữ). Tuy nhiên, khi mở rộng sang bài toán *Cross-Lingual Font Generation* (Huấn luyện trên dữ liệu tiếng Latin đơn giản $D_"source"$, ứng dụng sang chữ cái Hán $D_"target"$ phức tạp và ngược lại), SCR bộc lộ điểm yếu về *thiên kiến cấu trúc (structural bias)*.

Cụ thể, bộ trích xuất đặc trưng StyleExtractor (sử dụng các tầng VGG@SimonyanZ14aVGG pre-trained) có xu hướng "học vẹt" các đặc điểm cấu trúc dày đặc của Hán tự thay vì trích xuất phong cách trừu tượng. Khi gặp các ký tự Latin với cấu trúc thưa, sự chênh lệch miền (domain gap) khiến vector phong cách $v_"gen"$ và $v_"target"$ không còn tương đồng trong không gian tiềm ẩn.

=== Thiết kế mô-đun CL-SCR
Để giải quyết vấn đề này, khoá luận đề xuất mô-đun *Cross-Lingual SCR (CL-SCR)*. Dựa trên mã nguồn đã xây dựng, CL-SCR không thay đổi kiến trúc cốt lõi của StyleExtractor hay Projector, mà thay đổi *chiến lược lấy mẫu* và *cơ chế tính hàm mất mát đa luồng*.

==== Chiến lược lấy mẫu mở rộng
Thay vì chỉ sử dụng cặp mẫu dương/âm đơn thuần (Intra-lingual), CL-SCR thiết lập đầu vào cho hàm forward của mô hình bao gồm hai luồng dữ liệu song song:

#tab_eq[
  *_Luồng Nội miền (Intra-Lingual Flow)_*:
  #tab_eq(indent: 3em)[
    *Anchor ($x_"gen"$)*: Ảnh sinh ra từ mô hình Diffusion.

    *Intra-Positive ($x_"pos"^"intra"$)*: Ảnh cùng nội dung ký tự, cùng phong cách (Ground Truth). Giúp mô hình giữ vững cấu trúc cơ bản.

    *Intra-Negative ($x_"neg"^"intra"$)*: Ảnh cùng nội dung, khác phong cách.
  ]
  
  *_Luồng Xuyên miền (Cross-Lingual Flow - Điểm cải tiến chính)_*:
  #tab_eq(indent: 3em)[
    *Cross-Positive ($x_"pos"^"cross"$)*: Các ảnh thuộc ngôn ngữ đích mang cùng Style ID với ảnh tham chiếu. Mục tiêu là ép buộc bộ Projector phải ánh xạ các đặc trưng từ hai ngôn ngữ khác nhau về cùng một cụm vector nếu chúng có cùng phong cách.

    *Cross-Negative ($x_"neg"^"cross"$)*: Các ảnh thuộc ngôn ngữ đích có cấu trúc nét tương đồng nhưng khác phong cách.
  ]
]

==== Cơ chế tính toán Loss hỗn hợp
Hàm mất mát CL-SCR được định nghĩa là tổ hợp tuyến tính giữa mất mát nội miền và mất mát xuyên miền:

$ L_"CL-SCR" = alpha_"intra" dot L_"intra" + beta_"cross" dot L_"cross" $

Trong đó, dựa trên thực nghiệm, các siêu tham số trọng số được thiết lập là $alpha_"intra" = 0.3$ và $beta_"cross" = 0.7$ nhằm ưu tiên khả năng chuyển giao phong cách sang ngôn ngữ đích trong khi vẫn giữ được sự ổn định từ dữ liệu cùng ngôn ngữ.

Cả $L_"intra"$ và $L_"cross"$ đều được tính toán dựa trên hàm mất mát InfoNCE, được *trung bình hoá* qua $L$ tầng đặc trưng (từ các khối $"ReLU"^1_1$ đến $"ReLU"^5_1$ của mạng VGG-19). Công thức chi tiết cho thành phần Intra-Lingual Loss ($L_"intra"$) và Cross-Lingual Loss ($L_"cross"$) được tính theo trình tự như sau:

$ L_"intra" = -1/L sum_(l=1)^L log exp(v_"gen"^l dot v_"pos,intra"^l "/" tau)/(exp(v_"gen"^l dot v_("pos"_l,"intra")^l "/" tau) + sum_(k=1)^K exp(v_"gen"^l dot v_("neg"_k, "intra")^l "/" tau)) "          " $

$ L_"cross" = -1/L sum_(l=1)^L log exp(v_"gen"^l dot v_"pos,cross"^l "/" tau)/(exp(v_"gen"^l dot v_("pos"_l,"cross")^l "/" tau) + sum_(k=1)^K exp(v_"gen"^l dot v_("neg"_k, "cross")^l "/" tau)) "          " $

Với $v = "Projector(Extractor(x))"$ là vector phong cách sau khi đi qua mạng chiếu.

==== Quy trình huấn luyện Pha 2 cải tiến
Trong giai đoạn tinh chỉnh (Phase 2), hàm mất mát tổng thể được cập nhật để tích hợp CL-SCR. Việc sử dụng song song cả intra và cross loss giúp mô hình vừa duy trì tính ổn định (nhờ intra) vừa học được tính bất biến của phong cách qua các ngôn ngữ (nhờ cross).

Hàm mục tiêu cuối cùng là:

$ L_"Total"^(2) = L_"MSE" + lambda_"content" L_"content" + lambda_"offset" L_"offset" + lambda_"style" L_"CL-SCR" $

Trong đó:
#tab_eq[
  *$L_"MSE"$*: đảm bảo ảnh sinh ra không bị biến dạng quá nhiều so với ảnh gốc.

  *$L_"content"$ (Content Perceptual Loss)*: giữ gìn cấu trúc nét chữ.

  *$L_"offset"$*: kiểm soát độ dịch chuyển của mô-đun RSI.

  *$L_"CL-SCR"$*: đóng vai trò trọng tâm trong việc chuyển giao phong cách đa ngôn ngữ.
]

#untab_para[
  Việc tích hợp CL-SCR kỳ vọng sẽ giúp mô hình "bắt" được các đặc trưng phong cách trừu tượng (như độ xước cọ, độ thanh mảnh) tốt hơn và áp dụng chính xác lên các ký tự Hán phức tạp và ngược lại.
]

#pagebreak()
== Đề xuất thuật toán tính CL-SCR
Dựa trên cơ chế lấy mẫu đa luồng và hàm mất mát InfoNCE, thuật toán tính toán giá trị loss cho mô-đun CL-SCR được trình bày chi tiết dưới đây.

#outline_algo(
  [
    #algo(
      header: [
        #table(
          columns: (auto, 1fr),
          inset: 7pt,
          row-gutter: (0pt, 3pt),
          stroke: none,
          [*Input*],
          [$S "                 "$ Vector đặc trưng của ảnh sinh (Sample/Anchor)],
          [],
          [$P_"intra", N_"intra" "     "$ Tập mẫu Dương/Âm thuộc luồng Nội miền],
          [],
          [$P_"cross", N_"cross" "     "$ Tập mẫu Dương/Âm thuộc luồng Xuyên miền],
          [],
          [$alpha, beta "               "$ Trọng số cho luồng nội miền và xuyên miền],
          [],
          [$L "                 "$ Số lượng tầng đặc trưng (sử dụng $"ReLU"^x_1$)],
          [],
          [mode $"             "$ Chế độ huấn luyện ${"intra", "cross", "both"}$],
          table.hline(stroke: 0.5pt),
          [*Output*],
          [$L_"total" "          "$ Giá trị loss cuối cùng],
          table.hline(stroke: 0.5pt),
        )
      ],
      strong-keywords: false,
      indent-guides: 1pt + gray,
      breakable: true,
      comment-prefix: [#sym.triangle.stroked.r ],
    )[
      *procedure* CAL_CL_SCR_LOSS($S, P_"intra", N_"intra", P_"cross", N_"cross", alpha, beta, tau$):#i \
      $L_"total" arrow.l 0.0$  #comment[Loss tổng] \
      $"count" arrow.l 0$ #comment[Biến đếm số nhánh tham gia tính loss] \
      
      // 1. Tính Loss Nội miền (Intra-domain)
      *if* mode $in {"intra", "both"}$ *and* $P_"intra" != emptyset$ *then* #i\
        $L_"intra" arrow.l 0$ \
        *for* $l = 1 arrow L$ *do* #comment[Duyệt qua các tầng $"ReLU"^1_1$ đến $"ReLU"^5_1$] #i \
          $L_"intra" arrow.l L_"intra" + "InfoNCE"(S^l, P_"intra"^l, N_"intra"^l, tau) $ #d \
        *end for* \
        $L_"intra" arrow.l L_"intra" "/" L$ #comment[Trung bình cộng các tầng] \
        
        *if* mode $== "both"$ *then* #i \
           $L_"total" arrow.l L_"total" + alpha dot L_"intra"$ #comment[Áp dụng trọng số $alpha$] #d \
        *else* #i \
           $L_"total" arrow.l L_"total" + L_"intra"$ #d \
        *end if* \
        $"count" arrow.l "count" + 1$ #d \
      *end if* \

      // 2. Tính Loss Xuyên miền (Cross-domain)
      *if* mode $in {"cross", "both"}$ *and* $P_"cross" != emptyset$ *then* #i\
        $L_"cross" arrow.l 0$ \
        *for* $l = 1 arrow L$ *do* #i \
          $L_"cross" arrow.l L_"cross" + "InfoNCE"(S^l, P_"cross"^l, N_"cross"^l, tau) $ #d \
        *end for* \
        $L_"cross" arrow.l L_"cross" "/" L$ \

        *if* mode $== "both"$ *then* #i \
           $L_"total" arrow.l L_"total" + beta dot L_"cross"$ #d \
        *else* #i \
           $L_"total" arrow.l L_"total" + L_"cross"$ #d \
        *end if* \
        $"count" arrow.l "count" + 1$ #d \
      *end if* \

      // 3. Chuẩn hoá theo số lượng nhánh (Khớp với scr.py)
      *if* $"count" > 0$ *then* #i \
         $L_"total" arrow.l L_"total" "/" "count"$ #d \
      *end if* \

      *return* $L_"total"$ #d \
      *end procedure*
    ]
  ],
  [Thuật toán tính hàm mất mát CL-SCR],
  <algo>,
)

#pagebreak()