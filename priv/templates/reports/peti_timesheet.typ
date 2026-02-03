#set page(
  paper: "a4",
  margin: (x: 1.5cm, y: 1cm, bottom: 0.8cm),
  background: [
    #place(center + horizon, image("uesb.jpg", width: 40%))
    #place(center + horizon, rect(width: 100%, height: 100%, fill: white.transparentize(10%)))
  ]
)

#set text(
  font: "Liberation Sans", 
  size: 9pt, 
  lang: "pt"
)

#let data = json("data.json")

// --- 1. Cabeçalho ---
#align(left)[
  #image("peti.png", width: 80%) 
]

#v(1mm)

#align(left)[
  #text(size: 7.5pt, fill: luma(80))[
    Universidade Estadual do Sudoeste da Bahia – UESB \
    Recredenciada pelo Decreto Estadual N° 16.825, de 04.07.2016
  ]
]

#v(3mm)

#align(center)[
  #text(weight: "bold", size: 10pt)[PROGRAMA DE EDUCAÇÃO TUTORIAL INSTITUCIONAL (PETI)] \
  #text(size: 10pt)[(Folha de Frequência Discente Remunerado #data.period_year)]
]

#v(4mm)

// --- 2. Campos de Dados ---
#grid(
  columns: (auto, 1fr, auto, auto),
  gutter: 5pt,
  align: horizon, 
  
  text(weight: "bold")[DISCENTE:], 
  
  align(bottom)[
    #box(
      width: 100%,                
      stroke: (bottom: 0.5pt + black), 
      inset: (bottom: 2pt)        
    )[
      #data.employee.name
    ]
  ],
  
  [#text(weight: "bold")[MÊS:] #data.period_month / #data.period_year]
)
#v(4pt)

#grid(
  columns: (auto, 1fr, auto, 1fr, auto, 0.5fr),
  gutter: 5pt,
  align: horizon,
  
  text(weight: "bold")[Grupo PETI:], align(bottom, line(length: 100%, stroke: 0.5pt)),
  text(weight: "bold")[Professor(a):], align(bottom, line(length: 100%, stroke: 0.5pt)),
  text(weight: "bold")[DEPT.], align(bottom, line(length: 100%, stroke: 0.5pt))
)

#v(4pt)

#grid(
  columns: (auto, 1fr, auto, 1fr, auto, 1fr, auto, 1fr),
  gutter: 5pt,
  align: horizon,
  
  text(weight: "bold")[CPF:], align(bottom, line(length: 100%, stroke: 0.5pt)), 
  text(weight: "bold")[Banco:], align(bottom, line(length: 100%, stroke: 0.5pt)),
  text(weight: "bold")[Agência:], align(bottom, line(length: 100%, stroke: 0.5pt)),
  text(weight: "bold")[Conta:], align(bottom, line(length: 100%, stroke: 0.5pt))
)

#v(4mm)

// --- 3. Tabela Principal ---
#table(
  columns: (18%, 42%, 15%, 25%),
  inset: 5pt, 
  align: (center + horizon, left + top, center + horizon, center + bottom),
  stroke: 0.5pt + black,
  
  [*PERÍODO*], [*RESUMO DAS ATIVIDADES SEMANAIS*], [*C.H.*], [*ASS. DO(A) DISCENTE*],

  ..data.weeks.map(w => (
    align(center)[
      *#w.label* \
      #v(1mm)
      #text(size: 8pt)[#w.period]
    ],
    
    // CÉLULA DE RESUMO (Ajuste Final)
    align(left + top)[
       // Altura de 1.85cm: Garante que o corte aconteça ANTES de tocar a borda (inset 5pt ajuda também)
       // clip: true garante que nada vaze
       #block(height: 1.85cm, clip: true, breakable: false)[
         #text(size: 8pt)[ // Mantido 8pt (não diminui mais)
           #if w.summary != none and w.summary.len() > 0 [
             // Lista compacta
             #list(marker: [•], indent: 0pt, body-indent: 3pt, tight: true, ..w.summary)
           ]
         ]
       ]
    ],

    [*#w.total_hours*],

    [
      #v(1cm)
      #line(length: 100%, stroke: 0.5pt)
    ]
  )).flatten()
)

#v(1fr) 

// --- 4. Assinatura e Rodapé ---

#block(breakable: false, width: 100%)[
  #align(center)[
    #line(length: 60%, stroke: 0.5pt)
    #v(1mm)
    #text(size: 9pt)[*Assinatura do(a) Professor(a) Tutor(a)*]
  ]
]

#v(5mm)

// Rodapé
#line(length: 100%, stroke: 0.5pt)
#v(1mm)

#grid(
  columns: (1fr, 1fr),
  align: (left, right),
  text(size: 7pt, fill: luma(80))[Campus de Vitória da Conquista],
  text(size: 7pt, fill: luma(80))[(77) 3424-8604 | peti\@uesb.edu.br]
)

#v(1mm)
#line(length: 100%, stroke: 0.2pt)
#v(1mm)

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 5pt,
  align: left,
  text(size: 6pt, fill: luma(80))[
    *Campus de Itapetinga* \
    Praça da Primavera, 40 \
    Bairro Primavera \
    CEP 45.700-000 \
    PABX: (77) 3261-8600
  ],
  text(size: 6pt, fill: luma(80))[
    *Campus de Jequié* \
    Rua José Moreira Sobrinho, s/n \
    Bairro Jequiezinho \
    CEP 45.200-000 \
    PABX: (73) 3528-9600
  ],
  text(size: 6pt, fill: luma(80))[
    *Campus de Vitória da Conquista* \
    Estrada do Bem Querer, km 4 \
    Bairro Universitário \
    CEP 45031-300 \
    PABX: (77) 3424-8600
  ]
)