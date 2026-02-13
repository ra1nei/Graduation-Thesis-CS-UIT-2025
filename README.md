<div align="center">

# Graduation Thesis: Enhancing One-shot Cross-Script Font Style Transfer using Diffusion Model

</div>



## Abstract

This repository serves as the official archive for the Bachelor's Graduation Thesis titled **"Enhancing One-shot Cross-Script Font Style Transfer using Diffusion Model"**.

The research addresses the significant challenge of the "topological gap" between **Latin** and **Hanzi (Chinese)** script systems. By introducing a novel **CL-SCR (Cross-Lingual Style Contrastive Refinement)** module, this thesis proposes a method to align style features across distinct scripts, enabling high-fidelity style transfer where traditional monolingual models fail.

> **Achievement:** This thesis was successfully defended and achieved a final score of **9.3/10**.

## Resources & Materials

The main thesis materials are listed below:

| Material | Description |
| :--- | :--- |
| **Thesis Report** | Comprehensive documentation of the research methodology, experiments, and results. |
| **Defense Slides** | Presentation materials used during the thesis defense session. |


## Key Contributions

This thesis enhances the baseline *FontDiffuser (AAAI 2024)* architecture to support cross-lingual generation:

1.  **Problem Identification:** Analyzed the structural disparities preventing effective style transfer between unconnected script systems (e.g., Chinese Calligraphy $\rightarrow$ Latin Letters).
2.  **Methodology (CL-SCR):** Developed a cross-lingual projection mechanism that decouples content structure from style, projecting them into a shared latent space.
3.  **Performance:** Achieved state-of-the-art results in Zero-shot Cross-Lingual Font Generation, preserving both style consistency and content legibility.

<div align="center">
  <img src="https://raw.githubusercontent.com/ra1nei/Graduation-Thesis-CS-UIT-2025/refs/heads/main/README.png" width="85%" alt="Visual Results">
  <br>
  <em>Figure 1: Qualitative results of Cross-Lingual Style Transfer.</em>
</div>



## Acknowledgements

I would like to express my deepest gratitude to my supervisor, **M.S. Duong Viet Hang**, for her insightful guidance, patience, and continuous support throughout this research.

I also extend my thanks to the faculty members and the thesis defense committee of the **Faculty of Computer Science** for their valuable feedback and evaluation.
