#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
  background: [
    #place(center + horizon, image("uesb.jpg", width: 40%))
    #place(center + horizon, rect(width: 100%, height: 100%, fill: white.transparentize(10%)))
  ]
)

#set text(
  font: "Liberation Sans", 
  size: 10pt,
  lang: "pt"
)

#let data = json("data.json")

#place(top + left, image("lindalva.jpeg", width: 3.5cm))

#align(center)[
  #text(14pt, weight: "bold", fill: luma(80))[#data.company_name] \
  #v(2mm)
  #text(18pt, weight: "black")[ESPELHO DE PONTO] \
  #v(1mm)
  #text(10pt, style: "italic")[Controle de Frequência]
]

#v(1.5cm)
#line(length: 100%, stroke: 1pt + black)
#v(5mm)

#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  [
    #text(weight: "bold")[Funcionário:] #data.employee.name \
    #v(2mm)
    #text(weight: "bold")[Cargo:] #data.employee.position
  ],
  align(right)[
    #text(weight: "bold")[Período:] #data.period \
    #v(2mm)
    #text(weight: "bold")[Emissão:] #data.emitted_at
  ]
)

#v(1cm)

#table(
  columns: (auto, 1fr, 1fr, 1fr, 1fr, 2fr),
  inset: 8pt,
  align: (center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, left + horizon),
  fill: (col, row) => if row == 0 { luma(230) } else { none },
  
  [*Data*], [*Entrada*], [*Almoço*], [*Saída*], [*Saldo*], [*Obs*],

  ..data.days.map(d => (
    d.date,
    d.entry,
    d.lunch,
    d.exit,
    d.balance,
    text(size: 8pt, style: "italic")[#d.obs]
  )).flatten()
)

#v(5mm)
#align(right)[
  #block(
    fill: luma(240),
    inset: 10pt,
    radius: 4pt,
    [
      *Saldo Total:* #h(5mm) 
      #text(12pt, weight: "bold")[#data.total_balance]
    ]
  )
]

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
        #text(8pt)[Assinatura do Funcionário]
      ],
      align(center)[
        #line(length: 80%, stroke: 0.5pt)
        Pontodigital Tecnologia \
        #text(8pt)[Assinatura do Empregador]
      ]
    )
    #v(5mm)
    #align(center)[
      #text(8pt, fill: gray)[Documento gerado eletronicamente via Sistema Pontodigital.]
    ]
  ]
)