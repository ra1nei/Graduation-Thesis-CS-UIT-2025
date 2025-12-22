#import "/template.typ" : *

#[
  #set heading(numbering: "Chương 1.1")
  = Kết luận và Hướng phát triển <ketluan>
]

== Kết quả đạt được

Khoá luận đã hoàn thành mục tiêu xây dựng một khung giải pháp toàn diện cho bài toán sinh phông chữ đa ngôn ngữ (Cross-lingual Font Generation), tập trung vào cặp ngôn ngữ có sự chênh lệch hình thái lớn là Latin và Hán tự. Đóng góp quan trọng nhất về mặt lý thuyết là việc đề xuất và tích hợp thành công mô-đun *Cross-Lingual Style Contrastive Refinement (CL-SCR)* vào kiến trúc khuếch tán nền tảng. Khác với các phương pháp tiếp cận trước đây thường gặp khó khăn trong việc tách biệt phong cách khỏi nội dung khi miền dữ liệu thay đổi, CL-SCR đã chứng minh khả năng học được các *biểu diễn phong cách bất biến (invariant style representations)*. Cơ chế này cho phép mô hình vượt qua rào cản về *"Bất cân xứng mật độ thông tin"*, giải quyết hiệu quả cả hai bài toán: ngoại suy phong cách từ cấu trúc Latin đơn giản sang Hán tự phức tạp (*e2c*) và trừu tượng hoá phong cách từ Hán tự rậm rạp sang Latin (*c2e*) mà không làm vỡ cấu trúc ký tự.

Về mặt thực nghiệm, kết quả định lượng trên tập dữ liệu chuẩn đã khẳng định sự vượt trội của phương pháp đề xuất so với các mô hình State-of-the-Art thuộc dòng GAN (như *DG-Font*, *CF-Font*) và cả mô hình FontDiffuser nguyên bản. Cụ thể, chỉ số *FID* và *LPIPS* được cải thiện đáng kể trên các tập dữ liệu chưa từng thấy (*UFSC*), chứng tỏ khả năng tổng quát hoá mạnh mẽ của mô hình. Bên cạnh đó, kết quả khảo sát người dùng cũng cho thấy sản phẩm sinh ra từ phương pháp đề xuất đạt độ thẩm mỹ cao, với nét chữ sắc sảo và tự nhiên, khắc phục được các lỗi phổ biến như *mờ nhòe (blurring)* hay *biến dạng (artifacts)* thường thấy ở các mô hình đối chứng. Thành công của khoá luận không chỉ dừng lại ở việc cải thiện các chỉ số đo lường mà còn mở ra hướng đi mới cho việc ứng dụng Generative AI vào lĩnh vực thiết kế đồ họa và tự động hoá quy trình sáng tạo phông chữ đa ngữ.

== Các định hướng phát triển

Mặc dù đã đạt được những kết quả khả quan, nghiên cứu vẫn tồn tại một số hạn chế nhất định, mở ra các hướng phát triển tiềm năng trong tương lai. 

Thứ nhất, mở rộng phạm vi ngôn ngữ. Hiện tại mô hình mới chỉ tập trung vào cặp Latin-Hán. Hướng nghiên cứu tiếp theo sẽ thử nghiệm khả năng chuyển đổi trên các hệ chữ viết đa dạng hơn như *Tiếng Việt (Chữ Nôm/Quốc ngữ hoá)*, *Tiếng Nhật (Kanji/Kana)* hay *Tiếng Ả Rập*. Điều này đòi hỏi mô hình phải thích ứng với các đặc trưng hình thái học mới như dấu thanh điệu (diacritics) hoặc tính liên kết nét (cursiveness) đặc thù.

Thứ hai, tối ưu hoá tài nguyên huấn luyện. Mô hình Diffusion hiện tại đòi hỏi chi phí tính toán lớn. Để khắc phục, khoá luận đề xuất áp dụng các kỹ thuật *tinh chỉnh hiệu quả tham số (Parameter-Efficient Fine-Tuning - PEFT)* như *LoRA*@Hu2022LoRA hoặc *Adapter*@Houlsby2019PETL. Việc này sẽ cho phép huấn luyện mô hình trên các GPU phổ thông mà không làm suy giảm đáng kể chất lượng sinh ảnh.

Cuối cùng, về khả năng xử lý phong cách cực đoan, mô hình đôi khi gặp khó khăn với các phông chữ thư pháp biến dạng cao. Giải pháp tiềm năng là tích hợp các cơ chế *chú ý biến dạng (Deformable Attention)* mạnh mẽ hơn hoặc kết hợp với *biểu diễn vector (Vector Graphics)* để nắm bắt tốt hơn các đường cong phức tạp thay vì chỉ dựa vào ảnh raster thuần tuý.

#pagebreak()