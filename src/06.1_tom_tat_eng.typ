#{
  show heading: none
  heading(numbering: none)[Tóm tắt]
}
#align(center, text(16pt, strong("ABSTRACT")))
#v(0.2cm)

*Abstract*: Automatic font generation is an important research direction in computer vision, aiming to synthesize new characters with consistent stylistic properties from a minimal number of reference samples. FontDiffuser is a state-of-the-art approach based on diffusion models, capable of generating high-quality character images while preserving stylistic consistency more effectively than traditional GAN-based methods.

In this study, we inherit the two-stage training pipeline of FontDiffuser, in which the second stage employs Style Contrastive Refinement (SCR), and *propose an extension of SCR to the cross-lingual font generation setting*. Specifically, we design a *cross-lingual SCR loss* to learn language-invariant style representations, enabling effective style transfer across different writing systems. In addition, we introduce a weighting mechanism to balance the *intra-loss* and *cross-loss*, thereby optimizing font generation quality under multilingual data conditions.

Furthermore, a checkpointing mechanism is incorporated into the system to allow training to resume from previous states, improving scalability to large datasets and reducing overall training time. Experimental results demonstrate that the proposed method significantly enhances style fidelity and visual quality of the generated characters, while also improving generalization performance when transferring styles across different scripts.

#v(0.3cm)

*_Keywords:_* _FontDiffuser_, _Style Contrastive Refinement_, _Cross-lingual SCR_, _Diffusion Model_, _Font Generation_

#pagebreak()
