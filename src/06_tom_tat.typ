#{
  show heading: none
  heading(numbering: none)[Tóm tắt]
}
#align(center, text(16pt, strong("TÓM TẮT")))
#v(0.2cm)

*Tóm tắt*: Bài toán sinh phông chữ tự động là một nhánh quan trọng trong thị giác máy tính, nhằm tạo ra các ký tự mới với phong cách (style) đồng nhất từ một số lượng mẫu tối thiểu. FontDiffuser là một phương pháp tiên tiến dựa trên mô hình khuếch tán (Diffusion Model), cho phép sinh ảnh ký tự chất lượng cao và duy trì tính nhất quán về phong cách tốt hơn so với các mô hình GAN truyền thống. 

Trong nghiên cứu này, em kế thừa pipeline huấn luyện hai giai đoạn của FontDiffuser (trong đó giai đoạn 2 sử dụng Style Contrastive Refinement – SCR) và *đề xuất mở rộng SCR sang bài toán cross-lingual*. Cụ thể, em thiết kế *cross-lingual SCR loss* nhằm học biểu diễn phong cách bất biến theo ngôn ngữ, đồng thời bổ sung cơ chế điều chỉnh trọng số giữa *intra-loss* và *cross-loss* để tối ưu chất lượng sinh font trong bối cảnh dữ liệu đa ngôn ngữ. 

Hệ thống được bổ sung cơ chế checkpoint giúp tiếp tục huấn luyện từ trạng thái trước đó, hỗ trợ tập dữ liệu lớn và rút ngắn thời gian huấn luyện. Kết quả thực nghiệm cho thấy phương pháp đề xuất cải thiện đáng kể độ trung thành phong cách (style consistency) và chất lượng trực quan của ký tự sinh ra, đồng thời tăng khả năng tổng quát hoá khi áp dụng phong cách từ hệ chữ này sang hệ chữ khác.

#v(0.3cm)

*_Từ khoá:_* _FontDiffuser_, _Tinh chỉnh Tương phản Phong cách_, _SCR Đa ngôn ngữ_, _Mô hình Khuếch tán_, _Sinh phông chữ_

#pagebreak()
