#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Cơ sở lý thuyết <chuong2>
]

Trong chương này, khoá luận trình bày hệ thống cơ sở lý thuyết nền tảng về các mô hình sinh (Generative Models) và tổng quan tình hình nghiên cứu trong lĩnh vực sinh phông chữ tự động. Cấu trúc chương đi từ các phương pháp truyền thống dựa trên GAN@Goodfellow2014GAN, đến sự trỗi dậy của Mô hình khuếch tán (Diffusion Models)@SohlDickstein2015ICML. Đồng thời, phần cuối chương sẽ tập trung phân tích sâu về các kỹ thuật biểu diễn phong cách (Style Representation) và những thách thức đặc thù trong bài toán chuyển đổi đa ngôn ngữ, nhằm làm rõ động lực nghiên cứu cho phương pháp đề xuất tại Chương 3.

== Một số phương pháp tiếp cận cho bài toán Sinh phông chữ (Font Generation)

Lĩnh vực sinh phông chữ (Font Generation) đã trải qua một sự chuyển dịch mạnh mẽ về mặt công nghệ trong thập kỷ qua. Các phương pháp hiện nay có thể được chia thành hai nhóm chính dựa trên mô hình lõi: Mạng đối nghịch sinh (GANs)@Goodfellow2014GAN và Mô hình khuếch tán (Diffusion Models)@SohlDickstein2015ICML.

=== Các phương pháp dựa trên GAN (Generative Adversarial Networks)

Trước sự bùng nổ của Diffusion Models@SohlDickstein2015ICML vào năm 2023, Generative Adversarial Networks (GAN)@Goodfellow2014GAN là hướng tiếp cận chủ đạo (State-of-the-art) cho bài toán này. Các nghiên cứu GAN thường tập trung giải quyết vấn đề tách biệt nội dung (content) và phong cách (style).

==== DG-Font (Deformable Generative Network, CVPR 2021)
DG-Font@Xie2021DGFont tiếp cận bài toán sinh phông chữ theo hướng *không giám sát (unsupervised)*, tập trung giải quyết thách thức về sự sai lệch hình học lớn giữa phông chữ nguồn và phông chữ đích mà các phương pháp chuyển đổi phong cách dựa trên texture thông thường thường thất bại. Thay vì sử dụng dữ liệu cặp (paired data) tốn kém, DG-Font đề xuất một kiến trúc mới cho phép học ánh xạ phong cách trực tiếp từ các tập dữ liệu không gán nhãn.

Đóng góp cốt lõi của mô hình là mô-đun *Feature Deformation Skip Connection (FDSC)*. Cơ chế này hoạt động bằng cách dự đoán các bản đồ dịch chuyển (displacement maps) từ đặc trưng nội dung và phong cách, sau đó áp dụng *tích chập biến dạng (deformable convolution)* lên các đặc trưng cấp thấp. Điều này cho phép mô hình "uốn nắn" cấu trúc không gian của ký tự nguồn sao cho khớp với dáng vẻ của ký tự đích trước khi đưa vào bộ trộn (Mixer) để sinh ảnh cuối cùng. Mặc dù đạt hiệu quả cao trong việc bảo toàn cấu trúc, DG-Font vẫn tồn tại nhược điểm cố hữu của dòng GAN là sự mất ổn định khi huấn luyện; đối với các ký tự có sự biến đổi topo học quá lớn (ví dụ từ nét thanh sang nét đậm phá cách), ảnh sinh ra dễ bị hiện tượng đứt nét (broken strokes) hoặc mờ nhoè.

#figure(
    image("../images/DG-Font/overview.png", width: 100%),
    caption: [Kiến trúc mạng DG-Font. Mô-đun FDSC đóng vai trò nòng cốt trong việc học biến dạng hình học giữa các ký tự.]
  )

==== CF-Font (Content Fusion, CVPR 2023)
CF-Font@Wang2023CFFont tiếp cận bài toán sinh phông chữ few-shot theo hướng *"lai ghép" nội dung (content fusion)*, khắc phục hạn chế của các phương pháp truyền thống vốn chỉ dựa vào một font nguồn (source font) duy nhất. Nhận định rằng sự chênh lệch cấu trúc (topology) giữa font nguồn và font đích là nguyên nhân chính gây ra các lỗi biến dạng, CF-Font đề xuất sử dụng một tập hợp các *font cơ sở (basis fonts)* tiêu chuẩn để làm "nguyên liệu" tham chiếu.

Đóng góp cốt lõi của nghiên cứu là mô-đun *Content Fusion Module (CFM)*. Cơ chế này hoạt động bằng cách dự đoán bộ trọng số nhiệt (fusion weights) để *tổ hợp tuyến tính* các đặc trưng nội dung từ các font cơ sở. Thay vì phải "uốn nắn" khó khăn từ một hình dạng cố định, mô hình có thể linh hoạt pha trộn các đặc điểm hình học từ nhiều nguồn khác nhau để tạo ra một "khung xương" nội dung tiệm cận nhất với font mục tiêu. Chiến lược này giúp giảm thiểu đáng kể việc mất mát thông tin cấu trúc, tuy nhiên cũng đánh đổi bằng chi phí tính toán cao hơn do phải xử lý đa luồng đầu vào. Ngoài ra, nếu tập font cơ sở không đủ bao quát không gian topo, ảnh sinh ra có thể xuất hiện các vết mờ hoặc bóng ma (ghosting artifacts) tại các vùng giao thoa nét.

#figure(
  image("../images/CF-Font/overview.pdf", width: 100%),
  caption: [Minh hoạ cơ chế Content Fusion: Các đặc trưng từ tập font cơ sở (Source) được tổ hợp tuyến tính dựa trên bộ trọng số dự đoán (Weights) để xấp xỉ cấu trúc hình học của font mục tiêu.]
)

==== DFS (Few-Shot Text Style Transfer via Deep Feature Similarity, TIP 2020)
DFS@Zhu2020FewShotTextStyle đề xuất một cách tiếp cận mới cho bài toán chuyển đổi phong cách few-shot bằng cách khai thác mối tương quan cấu trúc giữa các ký tự. Khác với các phương pháp trước đó thường nén toàn bộ thông tin phong cách vào một vector duy nhất, DFS trích xuất đặc trưng từ từng ảnh tham chiếu riêng biệt thông qua mạng CNN. Đóng góp quan trọng nhất của mô hình là cơ chế *Deep Feature Similarity*, trong đó một *Ma trận Tương đồng (Similarity Matrix - SM)* được tính toán dựa trên *độ tương quan (cross-correlation)* giữa đặc trưng nội dung của ký tự tham chiếu và ký tự mục tiêu
Các đặc trưng style đã được điều chỉnh sau đó được gộp lại và nối với đặc trưng content, rồi đưa qua decoder đối xứng dạng U-Net để tái tạo ký tự đích trong phong cách mong muốn. Mô hình được huấn luyện end-to-end với LSGAN@Mao2017LSGAN loss kết hợp loss tái tạo, cho phép sinh ảnh có độ chân thực cao hơn so với các phương pháp chỉ dùng CNN thuần túy.

Cơ chế này hoạt động như một bộ lọc chú ý thông minh: nó cho phép mô hình tự động *gán trọng số lớn hơn cho các ký tự tham chiếu có cấu trúc hình học tương đồng* với ký tự cần sinh (ví dụ: sử dụng nét cong của chữ 'O' để hỗ trợ sinh chữ 'Q' hoặc 'C'). Sau đó, các đặc trưng phong cách được trọng số hoá này sẽ được trộn (mix) với đặc trưng nội dung để giải mã thành ảnh kết quả. Mặc dù đạt được độ chính xác cao về chi tiết phong cách nhờ việc "chọn lọc" thông tin, DFS vẫn tồn tại nhược điểm là yêu cầu quá trình *tinh chỉnh (fine-tuning)* cho từng phong cách mới (leave-one-out strategy) để đạt kết quả tối ưu, làm hạn chế khả năng ứng dụng thời gian thực so với các mô hình suy diễn trực tiếp (feed-forward).

#figure( 
  image("../images/DFS/overview.png", width: 100%), 
  caption: [Kiến trúc mạng DFS với thành phần cốt lõi là Ma trận Tương đồng (SM) giúp điều hướng dòng chảy thông tin phong cách.] 
)

==== FTransGAN (Few-shot Font Style Transfer between Different Languages, WACV 2021)
FTransGAN@Li2021FTransGAN là một trong những mô hình tiên phong giải quyết bài toán *chuyển đổi phong cách phông chữ đa ngôn ngữ (cross-lingual)* theo hướng few-shot learning. Khác với các phương pháp trước đó thường chỉ tập trung vào chuyển đổi trong cùng một ngôn ngữ, FTransGAN đề xuất một kiến trúc end-to-end cho phép trích xuất thông tin phong cách từ một ngôn ngữ (ví dụ: tiếng Anh) và áp dụng lên nội dung của ngôn ngữ khác (ví dụ: tiếng Trung).

Để giải quyết sự chênh lệch lớn về cấu trúc giữa các hệ chữ viết, FTransGAN thiết kế bộ mã hoá phong cách (Style Encoder) đặc biệt với *cơ chế chú ý đa tầng (multi-level attention)*. Kiến trúc này bao gồm hai mô-đun chính: *Context-aware Attention Network* giúp nắm bắt các đặc trưng cục bộ (như nét bút, hoạ tiết trang trí) và *Layer Attention Network* giúp tổng hợp các đặc trưng toàn cục để quyết định mức độ ưu tiên giữa các tầng đặc trưng khác nhau. Nhờ đó, mô hình có khả năng tạo ra các phông chữ chất lượng cao mà *không cần quá trình tinh chỉnh (fine-tuning)* phức tạp cho từng style mới. Tuy nhiên, FTransGAN vẫn còn hạn chế khi xử lý các phông chữ có tính nghệ thuật quá cao hoặc cấu trúc biến dạng mạnh, đồng thời yêu cầu *số lượng ảnh phong cách đầu vào cố định* trong quá trình huấn luyện.

#figure( 
  image("../images/FTransGAN/overview.png", width: 100%), 
  caption: [Tổng quan kiến trúc FTransGAN.] 
)

=== Mô hình khuếch tán (Diffusion Models)

Gần đây, Mô hình khuếch tán@SohlDickstein2015ICML (Diffusion Models) đã tạo nên một cuộc cách mạng trong lĩnh vực thị giác máy tính. Khác với GAN@Goodfellow2014GAN – vốn dựa trên việc lừa mô hình phân biệt, Diffusion Model mô phỏng quá trình nhiệt động lực học để biến đổi dần dần từ nhiễu sang dữ liệu có ý nghĩa. Trong phạm vi khoá luận này, khoá luận tập trung vào Mô hình Khuếch tán Khử nhiễu Xác suất (Denoising Diffusion Probabilistic Models - DDPM)@Ho2020DDPM, biến thể phổ biến nhất và là nền tảng của phương pháp FontDiffuser.

#untab_para[Nguyên lý cơ bản gồm hai giai đoạn:]
#tab_eq[
  *_Quá trình Khuếch tán xuôi_*: phá huỷ dữ liệu một cách có kiểm soát bằng cách thêm nhiễu Gaussian nhiều bước.  

  *_Quá trình Khuếch tán ngược_*: học cách loại bỏ nhiễu từng bước để tái tạo lại dữ liệu gốc.
  ]

#untab_para[
  Điều này tương tự như việc ta học cách "tô dần" một bức tranh từ nền trắng nhiễu cho đến khi ra ảnh rõ nét.
  ]

==== Quá trình Khuếch tán xuôi (Forward Diffusion Process)

Trong quá trình này, nhiễu được thêm dần vào dữ liệu qua một loạt các bước. Điều này tương tự như chuỗi Markov, trong đó mỗi bước làm giảm nhẹ dữ liệu bằng cách thêm nhiễu Gauss:

#figure(
  image("../images/diffusion_forward_process.png"),
  caption: [Quá trình Khuếch tán xuôi.]
)

Về mặt toán học, có thể được biểu diễn như sau:
$ q(x_t|x_(t-1))= scr(N)(x_t;sqrt(1-beta_t)x_(t-1),beta_t I) $

Trong đó:
#tab_eq[
  *$x_0$*: ảnh gốc (clean image).
  
  *$x_t$*: ảnh ở bước t sau khi thêm nhiễu.

  *$beta_t$*: hệ số nhiễu nhỏ (thường $beta_t in [10^(-4), 0.02]$).  

  *$I$*: ma trận đơn vị, đảm bảo nhiễu độc lập và đẳng hướng.
]

Do tính chất của Gaussian, ta có thể suy ra trực tiếp từ $x_0$ đến $x_t$:
$ x_t = sqrt(dash(alpha)_t) x_0 + sqrt(1 - dash(alpha)_t)epsilon.alt, "   " epsilon.alt ~ N(0,I) $

trong đó:
$ alpha_t = 1 - beta_t $
$ dash(alpha)_t = product_(s=1)^t alpha_s $

Điều này rất quan trọng vì giúp ta không cần sinh tuần tự từng bước mà vẫn có thể lấy mẫu trực tiếp ở bước t bất kì (quan trọng khi huấn luyện batch lớn).

==== Quá trình Khuếch tán ngược (Reverse Diffusion Process)

Quá trình này nhằm mục đích tái tạo lại dữ liệu gốc bằng cách khử nhiễu bằng một loạt các bước đảo ngược quá trình khuếch tán xuôi.

#figure(
  image("../images/diffusion_backward_process.png"),
  caption: [Quá trình Khuếch tán ngược.]
)

Về mặt toán học, có thể được biểu diễn như sau:
$ p_theta (x_(t-1)|x_t) = N(x_(t-1);mu_theta (x_t, t), sum_theta (x_t, t)) $

với $mu_theta$ được tính như sau:

$ mu_theta (x_t, t) = 1/sqrt(alpha_t)(x_t - (beta_t)/(sqrt(1 - dash(alpha)_t)) epsilon.alt_theta (x_t, t)) $

Ở đây, $epsilon.alt_theta (x_t, t)$ là nhiễu do mạng nơ-ron dự đoán, đóng vai trò trung tâm trong việc phục hồi ảnh gốc.  

Trong huấn luyện, mô hình được tối ưu để giảm sai số giữa $epsilon.alt_theta (x_t, t)$ và nhiễu thực $epsilon.alt$ mà ta đã thêm ở forward process.

==== Hàm mất mát (Loss function)
Hàm mất mát được sử dụng phổ biến nhất là *Mean Squared Error (MSE)*:

$ L_"simple" = EE_(t, x_0, epsilon.alt) [bar.v.double epsilon.alt - epsilon.alt_theta (x_t, t) bar.v.double ^2] $

Điều này tương đương với việc tối đa hoá khả năng tái tạo phân phối dữ liệu gốc (variational lower bound). Các nghiên cứu gần đây (v-prediction, hybrid loss) cho thấy việc dự đoán trực tiếp $v_t$ hoặc $x_0$ có thể cải thiện chất lượng ảnh sinh, nhưng MSE vẫn là chuẩn mực trong nhiều ứng dụng như FontDiffuser.

==== FontDiffuser (AAAI 2024)
FontDiffuser@Yang2024FontDiffuser là công trình tiên phong áp dụng thành công Diffusion Model vào bài toán One-shot Font Generation. Pipeline của mô hình giải quyết ba vấn đề cốt lõi:

#tab_eq[
  *_Bảo toàn cấu trúc_*: Sử dụng khối *MCA (Multi-Scale Content Aggregation)* để tổng hợp thông tin cấu trúc từ toàn cục đến chi tiết.

  *_Xử lý biến dạng_*: Sử dụng khối *RSI (Reference-Structure Interaction)* thay thế cho các phương pháp biến dạng cũ, giúp tương thích tốt hơn giữa cấu trúc ảnh nguồn và phong cách ảnh đích.

  *_Học phong cách_*: Sử dụng mô-đun *SCR (Style Contrastive Refinement)* để tinh chỉnh biểu diễn phong cách.
]

#untab_para[
  Đây chính là mô hình cơ sở (baseline) mà khoá luận này lựa chọn để kế thừa và phát triển.
]

== Một số phương pháp tiếp cận cho bài toán Biểu diễn Phong cách (Style Representation)

Trong bài toán sinh phông chữ One-shot, đặc biệt là trong bối cảnh chuyển đổi đa ngôn ngữ (Cross-Lingual), việc trích xuất và biểu diễn chính xác "phong cách" (style) là yếu tố quyết định sự thành bại của mô hình.

=== Neural Style Transfer truyền thống
Các phương pháp sơ khai (như Gatys et al.@Gatys2015NeuralStyle) thường sử dụng Ma trận Gram (Gram Matrix) tính toán trên các bản đồ đặc trưng (feature maps) của mạng VGG pre-trained để định nghĩa phong cách.
Tuy nhiên, phương pháp này chủ yếu nắm bắt các đặc trưng về chất liệu (texture) và hoạ tiết cục bộ. Đối với ký tự, "phong cách" không chỉ là vân bề mặt mà còn bao gồm các yếu tố hình học cấp cao như: độ gãy khúc, kiểu chân chữ (serif/sans-serif), và cách kết thúc nét (stroke ending). Gram Matrix thường thất bại trong việc hướng dẫn mô hình áp dụng các đặc trưng này lên các cấu trúc hình học mới, dẫn đến kết quả bị biến dạng hoặc chỉ đơn thuần là phủ texture lên ảnh nội dung.

=== Học tương phản (Contrastive Learning)
Để khắc phục hạn chế trên, các nghiên cứu hiện đại (trong đó có FontDiffuser@Yang2024FontDiffuser) chuyển sang hướng *Học biểu diễn tương phản (Contrastive Representation Learning)*. Tư tưởng cốt lõi là học một không gian embedding phong cách (style latent space) sao cho *các mẫu có _cùng phong cách_ (Positive samples)* được *_kéo lại gần_ nhau* và *các mẫu _khác phong cách_ (Negative samples)* bị *_đẩy ra xa_ nhau*.

Hàm mất mát InfoNCE@Oord2018InfoNCE thường được sử dụng để tối ưu hoá không gian này:
$ L_"NCE" = - log (exp("sim"(z, z^+)\/tau) / (exp("sim"(z, z^+)\/tau) + sum_(k) exp("sim"(z, z_k^-)\/tau))) $

Trong đó:
#tab_eq[
  *$z$*: Vector đặc trưng (feature representation) hoặc biểu diễn tiềm ẩn của mẫu dữ liệu đang xét (thường được gọi là mẫu neo - anchor).

  *$z^+$*: Biểu diễn đặc trưng của mẫu dương (positive sample) – đây là mẫu tương đồng hoặc thuộc cùng một lớp với $z$ mà mô hình cần học để tối đa hóa độ tương đồng.

  *$z^-_k$*: Biểu diễn đặc trưng của mẫu âm (negative sample) thứ $k$ trong tập dữ liệu – đây là các mẫu khác lớp hoặc không tương đồng với $z$ mà mô hình cần phân biệt và đẩy xa trong không gian đặc trưng.

  *$"sim"(dot, dot)$*: Hàm đo độ tương đồng giữa hai vector (similarity function), trong ngữ cảnh này thường là độ tương đồng Cosine (Cosine Similarity), tính toán góc giữa hai vector trong không gian đặc trưng.
  
  *$tau$*: Tham số nhiệt độ (temperature parameter), là một siêu tham số (hyperparameter) dương giúp điều chỉnh độ nhạy của hàm mất mát. Giá trị $tau$ nhỏ giúp mô hình tập trung hơn vào các mẫu âm khó phân biệt (hard negatives), trong khi $tau$ lớn giúp quá trình huấn luyện mượt mà hơn.
  
  *$sum_k$*: Phép tổng thực hiện trên tất cả các mẫu âm (negative samples) có trong batch hoặc hàng đợi (queue) hiện tại.
]

#untab_para[
  Trong FontDiffuser, mô-đun SCR áp dụng tư tưởng này để giám sát bộ mã hoá phong cách. Tuy nhiên, mô-đun này ban đầu được thiết kế cho cùng một ngôn ngữ (Hán $->$ Hán). Khi mở rộng sang bài toán Cross-Lingual *(chuyển đổi qua lại giữa Latin và Hán)*, sự khác biệt quá lớn về cấu trúc giữa hai hệ chữ tạo ra một khoảng cách miền (domain gap) sâu sắc, khiến các chiến lược chọn mẫu âm (negative selection) thông thường trở nên kém hiệu quả.
]

== Thách thức trong bài toán Cross-Lingual: Chuyển đổi Hai chiều giữa Latin và Hán tự

Khác với các hướng tiếp cận truyền thống thường chỉ tập trung vào một chiều chuyển đổi đơn lẻ, khoá luận giải quyết bài toán tổng quát và thách thức hơn là chuyển đổi phong cách hai chiều (Bidirectional Style Transfer) giữa hệ chữ Latin và Hán tự. Sự khác biệt nền tảng giữa hai hệ chữ này đặt ra những rào cản kỹ thuật đặc thù cho từng hướng chuyển đổi, chủ yếu xoay quanh sự bất đối xứng về thông tin và hình thái học.

=== Vấn đề Chênh lệch Mật độ Thông tin (Information Density Asymmetry)
Một thách thức cốt lõi trong bài toán chuyển giao phong cách giữa chữ Latin và Hán tự bắt nguồn từ _sự bất cân xứng nghiêm trọng về mật độ thông tin hình học_. Theo quan điểm thiết kế chữ Hán@tam_hanzi_blog, mỗi Hán tự được tổ chức như một *khối vuông khép kín*, nơi các nét bút không chỉ mang ý nghĩa hình thức mà còn có vai trò _phân bố và lấp đầy không gian thị giác_. Ngược lại, chữ Latin được xây dựng trên tư duy tuyến tính, với cấu trúc mở và số lượng nét tối thiểu, chỉ đủ để gợi hình dạng ký tự.

Sự khác biệt này dẫn đến hai bài toán đối nghịch trong quá trình chuyển đổi song hướng. Ở chiều *Latin → Hán tự* (`e2c`), mô hình phải đối mặt với bài toán ngoại suy (extrapolation): từ các ký tự Latin có mật độ thông tin cực thấp (ví dụ như `I` hoặc `O`), hệ thống phải suy diễn và mở rộng phong cách để phù hợp với các Hán tự có cấu trúc dày đặc và nhiều tầng nét bút (ví dụ `龍`). Trong trường hợp thiếu cơ chế suy luận phong cách hiệu quả, mô hình không thể “tưởng tượng” cách phân bổ phong cách vào không gian khối vuông, dẫn đến các lỗi phổ biến như nét bị dính bết, phân bố không đều hoặc mất chi tiết cấu trúc.

Ngược lại, ở chiều *Hán tự → Latin* (`c2e`), vấn đề chuyển thành bài toán _trừu tượng hoá_ (abstraction). Ảnh nguồn Hán tự chứa lượng thông tin thị giác dư thừa so với khả năng biểu đạt của chữ Latin. Do đó, thách thức không nằm ở việc sinh thêm chi tiết, mà ở việc *loại bỏ có chọn lọc* các yếu tố cấu trúc gắn với nội dung (strokes, bố cục khối) để chỉ giữ lại các đặc trưng phong cách cốt lõi như độ đậm nét, nhịp điệu bút pháp hay xu hướng hình học. Nếu quá trình này thất bại, hiện tượng _rò rỉ nội dung_ (content leakage) sẽ xảy ra, khiến chữ Latin sinh ra mang hình dáng méo mó và vô tình tái hiện các yếu tố cấu trúc đặc thù của Hán tự.

=== Khoảng cách Hình thái học (Morphological Gap)
Bên cạnh sự chênh lệch về mật độ thông tin, _khoảng cách hình thái học_ giữa hai hệ chữ còn tạo ra một rào cản căn bản đối với việc chuyển giao phong cách trực tiếp. Chữ Latin được thiết kế dựa trên dòng chảy ngang, với độ rộng ký tự biến thiên và cấu trúc mở, trong khi Hán tự tuân theo nguyên tắc *khối vuông cố định*, nơi mọi nét bút đều phải tương tác và cân bằng trong một không gian giới hạn.

Quan trọng hơn, các đơn vị hình thái cơ bản của hai hệ chữ không có sự tương ứng trực tiếp. Những đặc trưng cục bộ trong chữ Latin như chân chữ (serif), điểm kết thúc (terminal) hay độ cong của nét không thể ánh xạ một-một sang các khái niệm như nét bút hay bộ thủ trong Hán tự, vốn mang tính cấu trúc và ngữ nghĩa cao. Như đã được nhấn mạnh trong thiết kế chữ Hán, hình thái của mỗi nét không chỉ mang phong cách mà còn gắn chặt với vai trò của nó trong tổng thể khối chữ.

Chính vì khoảng cách hình thái sâu sắc này, việc áp dụng trực tiếp các mô-đun học phong cách truyền thống—vốn giả định sự tương đồng hình học giữa nguồn và đích—thường tỏ ra kém hiệu quả trong bối cảnh đa hệ chữ. Điều này tạo động lực cho khoá luận đề xuất *Cross-Lingual Style Contrastive Refinement (CL-SCR)*, một cơ chế học phong cách dựa trên việc tách rời và khai thác các đặc trưng _bất biến theo hình thái_ (morphology-invariant features), cho phép chuyển giao phong cách một cách linh hoạt và ổn định giữa hai miền chữ viết có bản chất cấu trúc đối lập.

#figure(
  image("../images/visualization_morphological_gap.png", width: 100%),
    caption: [So sánh cấu trúc hình thái giữa chữ Latin và Hán tự. Chữ Latin được tổ chức theo bố cục tuyến tính dựa trên baseline, với các tham số hình học như x-height và cap height, đồng thời có độ rộng ký tự biến thiên. Ngược lại, Hán tự tuân theo cấu trúc khối vuông cố định (body frame), trong đó các nét bút được phân bố để cân bằng và lấp đầy không gian nội khối. Sự khác biệt căn bản về hệ quy chiếu hình học này tạo nên khoảng cách hình thái học giữa hai hệ chữ.]
)

#pagebreak()