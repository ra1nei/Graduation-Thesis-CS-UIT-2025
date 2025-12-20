#import "template.typ": *
#set math.equation(numbering: "(1)")

#show: project.with(
  title: "Tăng cường khả năng chuyển kiểu chữ đa ngôn ngữ trong bài toán one-shot bằng mô hình khuếch tán",
  authors: ((name: "TRẦN ĐÌNH KHÁNH ĐĂNG"),),
)

#counter(page).update(1)
#set page(numbering: "1")
#set heading(numbering: "1.1.", supplement: "Chương")

#include "src/07_chuong_1.typ"
#include "src/08_chuong_2.typ"
#include "src/09_chuong_3.typ"
#include "src/10_chuong_4.typ"
#include "src/11_ket_luan.typ"
#include "src/12_cong_bo_lien_quan.typ"
#bibliography("ref.bib", style: "elsevier-vancouver", full: false)
#include "src/13_phu_luc.typ"