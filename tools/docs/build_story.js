// Builds docs/Historia_O_Coracao_de_Eter.docx — story bible (draft).
// Usage: node build_story.js <output.docx>
const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, LevelFormat, BorderStyle, PageBreak, TableOfContents, Footer, Header,
  PageNumber, VerticalAlign,
} = require('docx');

const OUT = process.argv[2];
const W = 9638;
const ACCENT = '5A3A1A'; // bronze/steam
const GOLD = 'B8860B';

const runs = (text, opts = {}) => String(text).split(/(\*\*[^*]+\*\*)/g).filter(Boolean).map(p => p.startsWith('**')
  ? new TextRun({ text: p.slice(2, -2), bold: true, ...opts })
  : new TextRun({ text: p, ...opts }));
const P = (text, run, keepNext = false) => new Paragraph({ keepNext, children: runs(text, run), spacing: { after: 120 } });
const Q = text => new Paragraph({ children: runs(text, { italics: true, color: '555555' }), indent: { left: 400 }, spacing: { after: 160 } });
// Static table of contents: LibreOffice does not refresh TOC fields on open, so we list H1s ourselves.
const tocEntries = [];
const H1 = t => { tocEntries.push(t); return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)], pageBreakBefore: true }); };
const H2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const H3 = t => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(t)] });
const B = t => new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: runs(t), spacing: { after: 60 } });
const gap = () => new Paragraph({ children: [], spacing: { after: 120 } });

const border = { style: BorderStyle.SINGLE, size: 4, color: 'C9B8A0' };
const borders = { top: border, bottom: border, left: border, right: border };
// Tables are kept on one page (all are short in this document).
function table(headers, rows, widths) {
  const sum = widths.reduce((a, b) => a + b, 0);
  widths = widths.map(w => Math.round(w * W / sum));
  widths[widths.length - 1] += W - widths.reduce((a, b) => a + b, 0);
  const cell = (text, i, header, keepNext) => new TableCell({
    width: { size: widths[i], type: WidthType.DXA }, borders, verticalAlign: VerticalAlign.CENTER,
    shading: header ? { type: ShadingType.CLEAR, color: 'auto', fill: ACCENT } : undefined,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: [new Paragraph({ keepNext, children: runs(text, header ? { bold: true, color: 'FFFFFF', size: 19 } : { size: 19 }) })],
  });
  return new Table({
    width: { size: W, type: WidthType.DXA }, columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: headers.map((h, i) => cell(h, i, true, true)) }),
      ...rows.map((r, ri) => new TableRow({ cantSplit: true, children: r.map((c, i) => cell(c, i, false, ri < rows.length - 1)) })),
    ],
  });
}

// Character sheet: fields -> 2-column table
const character = (name, subtitle, fields) => [
  H2(name),
  P(subtitle, { italics: true, color: '666666' }, true),
  table(['Campo', 'Descrição'], fields, [26, 74]),
  gap(),
];

const children = [];

// ---------- Cover ----------
children.push(
  new Paragraph({ children: [], spacing: { before: 2400 } }),
  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: 'O CORAÇÃO DE ÉTER', bold: true, size: 60, color: ACCENT, font: 'Georgia' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: '(título provisório)', italics: true, size: 24, color: '666666' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: GOLD, space: 8 } }, spacing: { after: 400 }, children: [new TextRun({ text: 'Bíblia da História — Rascunho para revisão', size: 30, color: '333333' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1600 }, children: [new TextRun({ text: 'Mundo, personagens, antagonistas e estrutura em atos', size: 22, color: '555555' })] }),
  table(['Campo', 'Valor'], [
    ['Versão', '0.2 — pontos H-01 a H-06 decididos'],
    ['Data', '24/09/2026'],
    ['Decisões de base', 'D-01 tom equilibrado · fantasia clássica + steampunk · D-06 um mundo só'],
    ['Documento de controle', 'docs/Planejamento_Projeto_RPG.docx'],
  ], [35, 65]),
  new Paragraph({ children: [new PageBreak()] }),
  new Paragraph({ children: [new TextRun({ text: 'Sumário', bold: true, size: 32, color: ACCENT })], spacing: { after: 200 } }),
);
const tocIndex = children.length;

// ---------- 1. Resumo ----------
children.push(
  H1('1. A história em uma página'),
  Q('"As máquinas não são mudas, Kael. Elas só estão cansadas de gritar."'),
  P('O continente de **Velmora** vive a Era do Vapor. O **Império de Ferrovar** ergueu cidades de latão, trens e dirigíveis movidos a **Éter**, um fluido luminoso bombeado das profundezas. Mas cada gota extraída enfraquece a magia: florestas perdem a cor, rios de mana secam e os antigos reinos mágicos definham.'),
  P('Em **Vila Caldeira**, uma cidade-oficina na fronteira do Império, o aprendiz de mecânico **Kael** encontra no ferro-velho um autômato de uma civilização esquecida. Ao despertar, a máquina diz uma única palavra: o nome dele. Kael descobre que consegue **ouvir as máquinas**, e que o Éter dentro delas está sofrendo.'),
  P('Caçados pelo Império, Kael e o autômato **Eco** atravessam Velmora reunindo aliados improváveis para impedir a **Grande Bomba**, a maior refinaria já construída. Mas, no coração da capital, descobrem a verdade: o Império é só um instrumento. O Éter não é natural — foi **criado**, milênios atrás, por **Vaeloth, o Artífice**, que fragmentou a alma do próprio mundo para alimentar sua civilização. Agora, ele usa o Império para reunir cada gota de volta no **Coração de Éter** e renascer.'),
  P('Quando o Coração desperta, o mundo se parte. O grupo precisa se reencontrar num Velmora devastado, descobrir a origem de Eco e decidir o preço do futuro: um mundo sem máquinas, um mundo sem magia — ou um terceiro caminho.'),
  H2('1.1 Temas'),
  B('**Progresso x natureza** — sem vilanizar a tecnologia: o problema é usar sem ouvir.'),
  B('**Escutar** — Kael ouve máquinas; cada personagem aprende a ouvir alguém que ignorava.'),
  B('**O preço do futuro** — quem paga pelo conforto de quem?'),
  B('**Identidade** — Eco descobre se tem alma; Brann e Isolde decidem quem são além do Império.'),
  B('**Coração dividido** — o triângulo Kael–Lyra–Isolde espelha o conflito do mundo: magia ou progresso.'),
  H2('1.2 Curva de tom'),
  table(['Momento', 'Tom'], [
    ['Prólogo e Ato 1', 'Aventura leve, humor do grupo, descoberta do mundo'],
    ['Fim do Ato 1', 'Primeira perda real; a guerra fica pessoal'],
    ['Ato 2', 'Intriga, revelações, clímax dramático (o mundo se parte)'],
    ['Ato 3', 'Reconstrução, esperança conquistada, sacrifício'],
    ['Final', 'Agridoce, com espaço para um final melhor (conteúdo opcional)'],
  ], [30, 70]),
);

// ---------- 2. Mundo ----------
children.push(
  H1('2. O mundo de Velmora'),
  H2('2.1 O Éter'),
  B('Fluido azul-dourado e luminoso, extraído de **veios** subterrâneos por bombas e refinarias.'),
  B('Move caldeiras, trens, dirigíveis, armas e autômatos. É a base da economia imperial.'),
  B('**Verdade oculta:** o Éter é a alma do mundo fragmentada. A magia é o que acontece quando ele circula livre; o vapor é o que acontece quando ele é queimado.'),
  B('**Regra de jogo:** regiões muito exploradas têm magia fraca (inimigos mágicos mais frágeis, mais inimigos mecânicos); regiões intactas têm magia forte.'),
  H2('2.2 Facções'),
  table(['Facção', 'Descrição', 'Estética'], [
    ['Império de Ferrovar', 'Potência industrial em expansão. Promete acabar com a fome com energia infinita. Capital: Brasaforte.', 'Latão, ferro fundido, chaminés, uniformes azul-marinho, dirigíveis'],
    ['Reino de Sylvaran', 'Reino élfico-druídico na floresta. Sua magia está morrendo com a exploração.', 'Madeira viva, cristais, folhas outonais'],
    ['Ordem de Lumen', 'Teocracia neutra que guarda textos antigos. Esconde o que sabe sobre o Artífice.', 'Mármore branco, vitrais, relógios de sol'],
    ['Porto Névoa', 'Cidade-livre de contrabandistas e aeronautas, fora da lei imperial.', 'Docas suspensas, balões remendados, lampiões'],
    ['Os Antigos (Aethelianos)', 'Civilização desaparecida que usava o Éter antes do Império. Deixou ruínas e autômatos.', 'Pedra clara, circuitos dourados, geometria perfeita'],
  ], [22, 48, 30]),
  gap(),
  H2('2.3 Locais principais'),
  table(['Local', 'Tipo', 'Papel na história'], [
    ['Vila Caldeira', 'Cidade inicial', 'Cidade-oficina na fronteira; casa de Kael; prólogo'],
    ['Ferro-Velho do Sul', 'Dungeon tutorial', 'Onde Eco é encontrado'],
    ['Floresta de Sylvaran', 'Região + dungeon', 'Lyra entra no grupo; magia morrendo'],
    ['Refinaria de Cinzamar', 'Dungeon', 'Brann deserta; primeira sabotagem'],
    ['Porto Névoa', 'Cidade', 'Mira e o dirigível; hub de missões secundárias'],
    ['Catedral de Lumen', 'Cidade + dungeon', 'Selene; textos proibidos sobre o Artífice'],
    ['A Grande Bomba', 'Dungeon', 'Clímax do Ato 1'],
    ['Brasaforte', 'Capital', 'Ato 2: infiltração, Isolde, revelações'],
    ['O Coração de Éter', 'Dungeon final', 'Máquina colossal sob a capital; renasce no Ato 3'],
    ['Aethel, a Cidade Submersa', 'Dungeon', 'Ato 3: origem de Eco e dos Antigos'],
  ], [28, 20, 52]),
);

// ---------- 3. Grupo ----------
children.push(
  H1('3. O grupo'),
  P('Sete personagens jogáveis, cada um com papel próprio na história e no combate híbrido (fila de turnos CTB + comandos com timing).'),
  table(['Personagem', 'Papel na história', 'Papel em combate', 'Entra no grupo'], [
    ['Kael', 'Protagonista; ouve as máquinas', 'Versátil físico; desmonta inimigos mecânicos', 'Prólogo'],
    ['Eco', 'Autômato antigo; o mistério central', 'Tanque / suporte modular', 'Prólogo'],
    ['Lyra', 'Druida de Sylvaran', 'Magia elemental ofensiva', 'Ato 1'],
    ['Brann', 'Soldado imperial desertor', 'Força bruta; golpes carregados', 'Ato 1'],
    ['Mira', 'Aeronauta contrabandista', 'Velocidade, roubo, bugigangas', 'Ato 1'],
    ['Selene', 'Clériga da Ordem de Lumen', 'Cura e proteção', 'Ato 1'],
    ['Isolde', 'Princesa e engenheira-chefe do Império', 'Torretas e controle de campo', 'Ato 2'],
  ], [16, 32, 32, 20]),
  gap(),
);
children.push(...character('Kael Brunor — o protagonista', '17 anos · aprendiz de mecânico · Vila Caldeira', [
  ['Aparência', 'Cabelo azul-escuro espetado, cachecol vermelho, armadura leve de couro sobre túnica azul, óculos de proteção de latão na testa, luvas de oficina (base: codex_test_01.png)'],
  ['Personalidade', 'Curioso, teimoso, bem-humorado; conserta tudo menos os próprios problemas'],
  ['Motivação', 'Proteger Eco e descobrir por que ouve as máquinas'],
  ['Arco', 'De "eu só conserto coisas" para alguém que decide o destino do Éter'],
  ['Segredo', 'Descende dos engenheiros aethelianos que selaram o Artífice; por isso ouve o Éter'],
  ['Arma', 'Lâmina-engrenagem (espada com mecanismo de pistão)'],
  ['Combate', 'Dano físico equilibrado. **Ressonância:** analisa e desativa partes de inimigos mecânicos'],
  ['Timing', 'Sobrecarga: apertar no pico do pistão para golpe extra'],
  ['Golpe especial', 'Engrenagem Final — sequência de cortes com vapor'],
]));
children.push(...character('Eco — o autômato', 'Idade desconhecida · autômato aetheliano · mistério central', [
  ['Aparência', 'Corpo de pedra clara e latão envelhecido, circuitos dourados que brilham ao falar, um único olho azul; musgo nas juntas'],
  ['Personalidade', 'Literal, gentil, curioso sobre emoções humanas; humor involuntário'],
  ['Motivação', 'Cumprir uma "diretiva" que não lembra — ligada a Kael'],
  ['Arco', 'Descobre que tem uma alma feita de Éter; escolhe o que ser em vez de obedecer'],
  ['Segredo', 'Foi construído por Vaeloth como chave do Coração, mas os engenheiros o reprogramaram para proteger o sangue de Kael'],
  ['Combate', 'Tanque e suporte. **Módulos:** troca de função entre batalhas (escudo, reparo, canhão)'],
  ['Timing', 'Bloqueio perfeito: apertar no impacto protege o grupo inteiro'],
  ['Golpe especial', 'Protocolo Aegis — barreira que anula um turno inimigo'],
]));
children.push(...character('Lyra Faelwen', '22 anos · druida de Sylvaran', [
  ['Aparência', 'Cabelo ruivo trançado com folhas secas, manto verde-musgo, cajado de raiz com um cristal quase apagado'],
  ['Personalidade', 'Orgulhosa, sarcástica, ferozmente leal'],
  ['Motivação', 'Salvar a floresta; odeia o Império e, no início, desconfia de Eco'],
  ['Arco', 'Do ódio a toda máquina para entender que o problema é como são usadas'],
  ['Combate', 'Magia elemental forte, mas mais fraca em regiões drenadas'],
  ['Timing', 'Canalização: segurar e soltar no ponto certo amplia a magia'],
  ['Golpe especial', 'Floração — magia que muda com o elemento dominante da região'],
]));
children.push(...character('Brann Hollowsteel', '34 anos · ex-sargento imperial', [
  ['Aparência', 'Grande, barba grisalha, uniforme imperial rasgado, braço direito com manopla a vapor'],
  ['Personalidade', 'Calado, pragmático, protetor; humor seco'],
  ['Motivação', 'Culpa: comandou a tropa que expulsou uma vila para construir Cinzamar'],
  ['Arco', 'Da culpa à reparação; enfrenta o General Voss, seu antigo mentor'],
  ['Combate', 'Força bruta e golpes de área; lento na fila de turnos'],
  ['Timing', 'Pressão de vapor: segurar para carregar, soltar antes de estourar'],
  ['Golpe especial', 'Martelo de Caldeira'],
]));
children.push(...character('Mira Vento-Solto', '19 anos · contrabandista e aeronauta de Porto Névoa', [
  ['Aparência', 'Cabelo curto preto, óculos de aviadora, jaqueta de couro cheia de bolsos, pistola de gancho'],
  ['Personalidade', 'Rápida, falante, oportunista, coração mole escondido'],
  ['Motivação', 'Pagar a dívida do dirigível Andorinha; depois, proteger a "família" que encontrou'],
  ['Arco', 'De "cada um por si" para arriscar tudo pelo grupo'],
  ['Papel especial', 'Dona do dirigível Andorinha — o veículo e a base do grupo'],
  ['Combate', 'Age mais vezes na fila; rouba itens; bombas e bugigangas'],
  ['Timing', 'Combo: sequência de botões para golpes extras'],
  ['Golpe especial', 'Rajada de Andorinha'],
]));
children.push(...character('Irmã Selene', '26 anos · clériga da Ordem de Lumen', [
  ['Aparência', 'Hábito branco e dourado, cabelo prateado curto, livro preso por correntes, sino de luz'],
  ['Personalidade', 'Serena, gentil, com um humor surpreendentemente ácido'],
  ['Motivação', 'Enviada pela Ordem para vigiar Eco — em segredo'],
  ['Arco', 'Escolhe entre obedecer a Ordem e revelar ao grupo o que ela esconde sobre o Artífice'],
  ['Combate', 'Cura, proteção, remoção de status, reviver'],
  ['Timing', 'Prece: apertar no ritmo do sino potencializa curas'],
  ['Golpe especial', 'Aurora — cura e revive o grupo'],
]));
children.push(...character('Isolde Ferrovar', '20 anos · princesa e engenheira-chefe do Império', [
  ['Aparência', 'Cabelo loiro preso, jaleco de engenheira sobre vestido azul-imperial, monóculo técnico, ferramentas no cinto'],
  ['Personalidade', 'Brilhante, idealista, orgulhosa; acredita no progresso'],
  ['Motivação', 'Projetou partes do Coração acreditando que era energia limpa'],
  ['Arco', 'Descobre que foi usada; enfrenta o pai e o chanceler; decide consertar o que construiu'],
  ['Combate', 'Instala torretas e drones que agem sozinhos na fila; controle de campo'],
  ['Timing', 'Calibragem: parar o ponteiro na zona certa'],
  ['Golpe especial', 'Fábrica de Guerra — várias torretas de uma vez'],
]));

// ---------- 3.x Coadjuvante: Gerd ----------
children.push(...character('Mestre Gerd Brunor — coadjuvante', '61 anos · mestre mecânico de Vila Caldeira · tutor de Kael', [
  ['Aparência', 'Baixo e robusto, careca com costeletas brancas, avental de couro chamuscado, braço esquerdo mecânico antigo, cachimbo apagado'],
  ['Personalidade', 'Rabugento, sábio, carinhoso de um jeito desajeitado; fala com as máquinas como se fossem pessoas'],
  ['Papel', 'Criou Kael como neto. Ex-engenheiro imperial que fugiu ao perceber para que servia o Éter'],
  ['Segredo', 'Sabe da linhagem aetheliana de Kael e escondeu Eco no ferro-velho há anos'],
  ['Prólogo', '"Morre" na explosão da oficina, segurando os soldados para Kael e Eco fugirem'],
  ['Verdade', 'Sobreviveu; Voss o levou para Brasaforte e o obrigou a completar o Coração — por isso o Império conseguiu terminá-lo'],
  ['Ato 2', 'Pista: Isolde fala de "um velho prisioneiro que conversa com as engrenagens"; o grupo não o encontra'],
  ['Ato 3', 'Reaparece no mundo partido; melhora o dirigível Andorinha, guia o grupo até Aethel e sabe como abrir o Coração. Personagem convidado em algumas batalhas'],
  ['Combate (convidado)', 'Bombas de oficina, reparo de aliados mecânicos (Eco, torretas de Isolde)'],
]));

// ---------- 3.y Romance ----------
children.push(
  H2('Triângulo amoroso: Kael, Lyra e Isolde'),
  P('O romance espelha o tema central: **Lyra** representa a magia e a natureza; **Isolde**, a tecnologia e o progresso. A escolha do jogador não é "certa" ou "errada" — ela muda o epílogo e o tom do final.'),
  table(['Elemento', 'Como funciona'], [
    ['Afinidade', 'Valor oculto com Lyra e com Isolde (e com o resto do grupo). Sobe e desce com escolhas de diálogo e ações'],
    ['Momentos-chave', '4–5 cenas com escolhas marcantes (ex.: noite no convés da Andorinha no Ato 2, a escolha de quem salvar primeiro no colapso do Coração)'],
    ['Tensão entre as duas', 'Lyra e Isolde começam como opostas (natureza x máquina) e aprendem a se respeitar; rivalidade, não ódio'],
    ['Antes do Ato 2', 'Isolde só entra no Ato 2, então no Ato 1 a afinidade com Lyra já existe e Isolde precisa "alcançar"'],
    ['Sem romance', 'Opção válida: manter as duas como amigas leva a um epílogo focado no grupo'],
  ], [25, 75]),
  gap(),
);

// ---------- 4. Antagonistas ----------
children.push(
  H1('4. Antagonistas'),
  table(['Personagem', 'Papel', 'Descrição'], [
    ['Imperador Aldric Ferrovar III', 'Vilão aparente (Atos 1–2)', 'Pai de Isolde. Quer acabar com a pobreza a qualquer custo. Não é mau — é convencido. Morre pelas mãos de Morvain no clímax do Ato 2, depois de perceber o erro.'],
    ['General Oskar Voss', 'Chefe recorrente', 'Mão de ferro do Império, com armadura a vapor. Antigo mentor de Brann. Pode ser poupado no Ato 3 (afeta o final).'],
    ['Chanceler Morvain', 'Vilão oculto', 'Conselheiro do Imperador. Na verdade é um receptáculo de Vaeloth, guiando o Império para encher o Coração.'],
    ['Vaeloth, o Artífice', 'Antagonista real', 'Engenheiro supremo dos Antigos. Fragmentou a alma do mundo para criar o Éter; o corpo dele morreu, mas a consciência se espalhou no fluido. Quer se reunir no Coração e renascer como deus-máquina.'],
  ], [26, 20, 54]),
  gap(),
  H2('4.1 A motivação de Vaeloth'),
  P('Vaeloth acredita que a vida orgânica é caótica e sofredora, e que um mundo perfeito deve ser uma máquina com uma só mente: a dele. Ele não se vê como vilão, e sim como o engenheiro que vai "consertar" o mundo. Seu discurso ecoa o de Isolde no início do jogo, o que torna o confronto pessoal para ela.'),
);

// ---------- 5. Estrutura ----------
const beat = (title, items) => [H2(title), ...items.map(i => B(i))];
children.push(
  H1('5. Estrutura em atos'),
  ...beat('Prólogo — "A Máquina que Sabia meu Nome" (1–2 h)', [
    'Vida em Vila Caldeira: tutorial de exploração e diálogo; oficina do mestre Gerd.',
    'Ferro-Velho do Sul: tutorial de combate; Kael encontra e desperta Eco, que diz seu nome.',
    'Soldados imperiais chegam atrás do "artefato"; a vila é ameaçada; primeira luta contra Voss (derrota forçada).',
    'Gerd segura os soldados e a oficina explode — o jogador acredita que ele morreu. **Tom:** leve até o fim, que tem o primeiro impacto.',
  ]),
  ...beat('Ato 1 — "Os Ecos da Terra" (5–7 h)', [
    'Floresta de Sylvaran: magia morrendo; Lyra acusa Eco; os dois salvam juntos o Grande Carvalho → Lyra entra.',
    'Refinaria de Cinzamar: infiltração; Brann ajuda o grupo a escapar e deserta.',
    'Porto Névoa: Mira e o dirigível Andorinha (voo liberado); missões secundárias.',
    'Catedral de Lumen: Selene entra "para guiar o grupo"; primeiros indícios sobre os Antigos.',
    'A Grande Bomba: ataque para destruí-la; a magia volta em parte à região.',
    '**Fim do Ato 1:** Voss captura Eco; Selene é revelada como espiã da Ordem e o grupo se divide.',
  ]),
  ...beat('Ato 2 — "O Império de Latão" (6–9 h)', [
    'Grupo reunido de novo (Selene pede perdão e revela o que a Ordem sabe sobre o Artífice).',
    'Infiltração em Brasaforte; aliança com Isolde, que descobre para que serve o Coração.',
    'Pista sobre Gerd: Isolde menciona um velho prisioneiro que "conversa com as engrenagens".',
    'Noite no convés da Andorinha: primeiro momento-chave do triângulo amoroso.',
    'Resgate de Eco; Eco começa a recuperar memórias e lembra de Vaeloth.',
    'Revelação: Morvain é Vaeloth; o Imperador tenta impedi-lo e é morto.',
    '**Clímax:** o Coração desperta; as refinarias sugam o Éter restante; o mundo se parte (continentes rachados, céu dourado). Grupo separado.',
  ]),
  ...beat('Ato 3 — "O Mundo Partido" (3–5 h + opcional)', [
    'Kael acorda sozinho um ano depois; reúne o grupo (ordem livre, cada resgate é uma missão).',
    '**Reviravolta:** Gerd está vivo — escapou de Brasaforte no colapso. Reencontro emocional; ele melhora a Andorinha e revela como abrir o Coração.',
    'Missões pessoais opcionais de cada personagem (afetam o final).',
    'Aethel, a Cidade Submersa: verdade sobre Eco e a linhagem de Kael.',
    'Invasão do Coração de Éter; batalha contra Voss (poupar ou não), Morvain e Vaeloth.',
  ]),
  ...beat('Final — "O Preço do Futuro"', [
    'Para derrotar Vaeloth, o Éter precisa voltar a circular livre — o que desliga a maioria das máquinas.',
    '**Final padrão (agridoce):** Eco usa sua alma de Éter para libertar o Coração e se desliga; a magia volta, a era do vapor termina.',
    '**Final completo (missões pessoais + Voss poupado):** Kael "ouve" Eco dentro do Éter livre e o traz de volta; o grupo encontra o terceiro caminho — máquinas que usam o Éter sem consumi-lo.',
    'O epílogo de cada final muda conforme o triângulo amoroso (ver matriz abaixo).',
    'Pós-jogo: New Game+ e chefes secretos (a definir).',
  ]),
  H2('Matriz de finais'),
  P('Dois finais principais, cada um com um epílogo definido pelo triângulo amoroso — 6 combinações.'),
  table(['Epílogo', 'Final agridoce (Eco se desliga)', 'Final completo (Eco volta)'], [
    ['Lyra', 'Kael e Lyra replantam Sylvaran; a floresta renasce, mas sem Eco', 'Kael, Lyra e Eco cuidam da floresta; máquinas e raízes crescem juntas'],
    ['Isolde', 'Kael e Isolde reconstroem Brasaforte sem Éter, em luto por Eco', 'Kael, Isolde e Eco criam as máquinas que usam o Éter sem consumi-lo'],
    ['Sem romance', 'O grupo se despede e cada um segue seu caminho', 'O grupo reunido funda uma oficina; Gerd e Eco discutem sobre engrenagens'],
  ], [18, 41, 41]),
  gap(),
);

// ---------- 6. Técnicas combinadas ----------
children.push(
  H1('6. Técnicas combinadas (exemplos)'),
  P('As Dual/Triple Techs reforçam as relações entre os personagens.'),
  table(['Técnica', 'Personagens', 'Efeito'], [
    ['Faísca Viva', 'Kael + Lyra', 'Espada imbuída com o elemento da magia de Lyra'],
    ['Muralha de Ferro', 'Eco + Brann', 'Brann arremessa Eco como escudo-projétil; defesa ao grupo'],
    ['Mergulho da Andorinha', 'Mira + Kael', 'Ataque aéreo com o gancho; ignora defesa'],
    ['Luz de Oficina', 'Selene + Isolde', 'Torreta que cura aliados a cada turno'],
    ['Rugido da Terra', 'Lyra + Brann + Eco', 'Terremoto de área com vapor e raízes'],
    ['Engrenagem do Mundo', 'Kael + Eco + Isolde', 'Ataque mais forte de base mecânica'],
  ], [28, 30, 42]),
);

// ---------- 7. Pendências ----------
children.push(
  H1('7. Decisões da história'),
  table(['#', 'Pergunta', 'Decisão'], [
    ['H-01', 'Nomes (Velmora, Ferrovar, Kael, Eco…)', 'Aprovados'],
    ['H-02', 'Número de personagens jogáveis', '7 (Isolde entra no Ato 2)'],
    ['H-03', 'O mundo se parte no Ato 2?', 'Sim — reaproveita mapas em versão "devastada"'],
    ['H-04', 'Quantos finais?', '2 principais (agridoce e completo), cada um com epílogo definido pelo romance'],
    ['H-05', 'Mestre Gerd morre no prólogo?', 'Morte simulada; ele volta no Ato 3 para ajudar o grupo'],
    ['H-06', 'Romance entre personagens?', 'Triângulo Kael–Lyra–Isolde com afinidade; muda o epílogo'],
  ], [10, 40, 50]),
);

children.splice(tocIndex, 0, ...tocEntries.map(t => new Paragraph({ children: [new TextRun({ text: t, size: 24 })], spacing: { after: 140 } })));

// ---------- document ----------
const doc = new Document({
  creator: 'Claude',
  title: 'O Coração de Éter — Bíblia da História',
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 34, bold: true, color: ACCENT, font: 'Georgia' },
        paragraph: { spacing: { before: 240, after: 200 }, outlineLevel: 0, border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: GOLD, space: 4 } } } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, color: ACCENT }, paragraph: { spacing: { before: 280, after: 80 }, outlineLevel: 1, keepNext: true, keepLines: true } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 22, bold: true, color: '444444' }, paragraph: { spacing: { before: 160, after: 80 }, outlineLevel: 2, keepNext: true, keepLines: true } },
    ],
  },
  numbering: { config: [{ reference: 'bullets', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } }] }] },
  features: { updateFields: true },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'O Coração de Éter — Bíblia da História', size: 16, color: '888888' })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['Página ', PageNumber.CURRENT, ' de ', PageNumber.TOTAL_PAGES], size: 16, color: '888888' })] })] }) },
    children,
  }],
});

Packer.toBuffer(doc).then(buf => { fs.writeFileSync(OUT, buf); console.log('written', OUT, buf.length); });
