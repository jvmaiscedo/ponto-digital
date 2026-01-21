// --- CONFIGURAÇÕES DA PÁGINA ---
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
)
#set text(
  font: "Liberation Sans", // Fonte padrão bonita e open source
  size: 10pt,
  lang: "pt"
)

// Importa os dados do JSON (que o Elixir vai gerar depois)
#let data = json("data.json")

// --- CABEÇALHO ---
#align(center)[
  #text(16pt, weight: "bold")[ESPELHO DE PONTO] \
  #v(2mm)
  #text(12pt)[#data.company_name] \
  #text(10pt, fill: gray)[CNPJ: #data.company_cnpj]
]

#line(length: 100%, stroke: 0.5pt + gray)
#v(5mm)

// --- DADOS DO FUNCIONÁRIO ---
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

// --- TABELA ---
// O Typst gerencia quebras de página e repetição de cabeçalho automaticamente
#table(
  columns: (auto, 1fr, 1fr, 1fr, 1fr, 2fr),
  inset: 8pt,
  align: (center + horizon, center + horizon, center + horizon, center + horizon, right + horizon, left + horizon),
  fill: (col, row) => if row == 0 { luma(230) } else { none },
  
  // Cabeçalhos
  [*Data*], [*Entrada*], [*Almoço*], [*Saída*], [*Saldo*], [*Obs*],

  // Linhas (Extraídas do JSON)
  ..data.days.map(d => (
    d.date,
    d.entry,
    d.lunch,
    d.exit,
    // Condicional de cor para saldo negativo
    text(fill: if d.balance.starts-with("-") { red } else { black })[#d.balance],
    text(size: 8pt, style: "italic")[#d.obs]
  )).flatten()
)

// --- TOTAIS ---
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

// --- RODAPÉ DE ASSINATURAS ---
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