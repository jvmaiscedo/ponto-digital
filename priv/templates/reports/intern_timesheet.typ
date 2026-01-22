
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
)
#set text(
  font: "Liberation Sans",
  size: 10pt,
  lang: "pt"
)


#let data = json("data.json")

#align(center)[
  #text(16pt, weight: "bold")[ESPELHO DE PONTO] \
  #v(2mm)
  #text(12pt)[#data.company_name] \
]

#line(length: 100%, stroke: 0.5pt + gray)
#v(5mm)


#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  [
    *Funcionário:* #data.employee.name \
    *Cargo:* #data.employee.position
  ],
  align(right)[
    *Período:* #data.period \
    *Emissão:* #data.emitted_at
  ]
)

#v(1cm)


#table(
  columns: (auto, 1fr, 1fr, 1fr, 2fr, 2fr),
  inset: 8pt,
  align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, left + horizon),
  fill: (col, row) => if row == 0 { luma(230) } else { none },
  
  [*Data*], [*Entrada*], [*Almoço*], [*Saída*],[*Atividade*], [*Obs*],

  ..data.days.map(d => (
    d.date,
    d.entry,
    d.lunch,
    d.exit,
    d.daily_log,
    text(size: 8pt, style: "italic")[#d.obs]
  )).flatten()
)


#place(
  bottom,
  dx: 0cm,
  dy: 0cm,
  [
    #grid(
      columns: (1fr, 1fr),
      gutter: 2cm,
      align(center)[
        #line(length: 80%, stroke: 0.5pt)
        #data.employee.name \
        #text(8pt)[Assinatura do Estagiário]
      ],
      align(center)[
        #line(length: 80%, stroke: 0.5pt)
        CIPEC \
        #text(8pt)[Assinatura do Professor Orientador]
      ]
    )
    #v(5mm)
    #align(center)[
      #text(8pt, fill: gray)[Documento gerado eletronicamente via Sistema Pontodigital.]
    ]
  ]
)