const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, LevelFormat, BorderStyle, PageBreak, TableOfContents, Footer, Header,
  PageNumber, VerticalAlign,
} = require('docx');

const OUT = process.argv[2];
const W = 9638; // A4 content width with 2 cm margins
const ACCENT = '1F3A5F';
const LIGHT = 'E8EEF5';
const GOLD = 'B8860B';

// ---------- helpers ----------
const runs = (text, opts = {}) => {
  // support **bold** inline
  const parts = String(text).split(/(\*\*[^*]+\*\*)/g).filter(Boolean);
  return parts.map(p => p.startsWith('**')
    ? new TextRun({ text: p.slice(2, -2), bold: true, ...opts })
    : new TextRun({ text: p, ...opts }));
};
const P = (text, opts = {}) => new Paragraph({ children: runs(text, opts.run), spacing: { after: 120 }, ...opts.para });
// Static table of contents: LibreOffice does not refresh TOC fields on open, so we list H1s ourselves.
const tocEntries = [];
const H1 = t => { tocEntries.push(t); return new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)], pageBreakBefore: true }); };
const H2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });
const H3 = t => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(t)] });
const B = (t, level = 0) => new Paragraph({ numbering: { reference: 'bullets', level }, children: runs(t), spacing: { after: 60 } });
const N = (t, ref = 'num') => new Paragraph({ numbering: { reference: ref, level: 0 }, children: runs(t), spacing: { after: 60 } });

const border = { style: BorderStyle.SINGLE, size: 4, color: 'B7C3D0' };
const borders = { top: border, bottom: border, left: border, right: border };

// Tables up to KEEP_ROWS rows are kept on one page; longer ones split with a repeated header.
const KEEP_ROWS = 22;
function table(headers, rows, widths) {
  const sum = widths.reduce((a, b) => a + b, 0);
  widths = widths.map(w => Math.round(w * W / sum));
  widths[widths.length - 1] += W - widths.reduce((a, b) => a + b, 0);
  const keep = rows.length <= KEEP_ROWS;
  const cell = (text, i, header, keepNext) => new TableCell({
    width: { size: widths[i], type: WidthType.DXA },
    borders,
    verticalAlign: VerticalAlign.CENTER,
    shading: header ? { type: ShadingType.CLEAR, color: 'auto', fill: ACCENT } : undefined,
    margins: { top: 60, bottom: 60, left: 100, right: 100 },
    children: [new Paragraph({ keepNext, children: runs(text, header ? { bold: true, color: 'FFFFFF', size: 19 } : { size: 19 }) })],
  });
  return new Table({
    width: { size: W, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, cantSplit: true, children: headers.map((h, i) => cell(h, i, true, true)) }),
      ...rows.map((r, ri) => new TableRow({
        cantSplit: true,
        children: r.map((c, i) => cell(c, i, false, keep && ri < rows.length - 1)),
      })),
    ],
  });
}
const gap = () => new Paragraph({ children: [], spacing: { after: 120 } });

// Phase task table: ID | Tarefa | Responsável | Status | Notas
const phaseTable = (prefix, tasks) => table(
  ['ID', 'Tarefa', 'Responsável', 'Status', 'Notas'],
  tasks.map((t, i) => [`${prefix}.${String(i + 1).padStart(2, '0')}`, t[0], t[1], t[3] || '☐ Pendente', t[2] || '']),
  [8, 44, 14, 13, 21],
);

const phase = (num, title, objetivo, entregavel, tasks, criterios) => [
  H2(`Fase ${num} — ${title}`),
  P(`**Objetivo:** ${objetivo}`, { para: { keepNext: true } }),
  P(`**Entregável:** ${entregavel}`, { para: { keepNext: true } }),
  phaseTable(`F${num}`, tasks),
  gap(),
  P('**Critérios de conclusão (Definition of Done):**', { para: { keepNext: true } }),
  ...criterios.map(c => B(c)),
];

// ---------- content ----------
const created = '24/09/2026';
const today = '24/09/2026';
const DONE = '☑ Concluída';
const WIP = '◐ Em andamento';
const children = [];

// Cover
children.push(
  new Paragraph({ children: [], spacing: { before: 2400 } }),
  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: 'O CORAÇÃO DE ÉTER', bold: true, size: 60, color: ACCENT, font: 'Georgia' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: '(título provisório)', italics: true, size: 24, color: '666666' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: GOLD, space: 8 } }, spacing: { after: 400 }, children: [new TextRun({ text: 'Documento de Planejamento e Controle de Fases', size: 32, color: '333333' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 120 }, children: [new TextRun({ text: 'RPG por turnos inspirado em Final Fantasy VII, Final Fantasy X e Chrono Trigger', size: 22 })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1600 }, children: [new TextRun({ text: 'Engine: Godot 4.7.2 (stable)  ·  Linguagem: GDScript', size: 22, color: '555555' })] }),
);
children.push(table(
  ['Campo', 'Valor'],
  [
    ['Versão do documento', '2.0 — Fase 2 implementada (aguardando aprovação)'],
    ['Data de criação', created],
    ['Última atualização', today],
    ['Pasta do projeto', 'D:\\Projeto RPG'],
    ['Repositório', 'github.com/RudyAlmeida/projeto-rpg'],
    ['Engine', 'D:\\Godot\\Godot_v4.7.2-stable_win64.exe'],
    ['Fase atual', 'Fase 2 — Sistemas centrais'],
    ['Status geral', 'Fases 0 e 1 concluídas (24–25/09/2026)'],
  ],
  [35, 65],
));

// TOC (filled in after all sections are built)
children.push(
  new Paragraph({ children: [new PageBreak()] }),
  new Paragraph({ children: [new TextRun({ text: 'Sumário', bold: true, size: 32, color: ACCENT })], spacing: { after: 200 } }),
);
const tocIndex = children.length;

// 1. Como usar
children.push(
  H1('1. Como usar este documento'),
  P('Este é o documento-mestre do projeto. Ele reúne a visão do jogo, as decisões técnicas e o controle de cada fase de produção. Deve ser atualizado ao final de cada sessão de trabalho.'),
  H2('1.1 Legenda de status'),
  table(['Símbolo', 'Significado'], [
    ['☐ Pendente', 'Tarefa ainda não iniciada'],
    ['◐ Em andamento', 'Tarefa iniciada, não concluída'],
    ['☑ Concluída', 'Tarefa finalizada e validada'],
    ['⛔ Bloqueada', 'Depende de decisão ou de outra tarefa'],
    ['✖ Cancelada', 'Removida do escopo (registrar motivo no log)'],
  ], [30, 70]),
  gap(),
  H2('1.2 Regras de atualização'),
  B('Toda decisão importante vai para a seção **13. Registro de decisões**.'),
  B('Mudanças no documento vão para a seção **14. Histórico de versões**.'),
  B('Uma fase só é marcada como concluída quando **todos** os critérios de conclusão forem atendidos.'),
  B('Tarefas novas recebem o próximo ID livre da fase (ex.: F2.19).'),
);

// 2. Visão geral
children.push(
  H1('2. Visão geral do jogo'),
  H2('2.1 Conceito (high concept)'),
  P('Um JRPG por turnos com narrativa cinematográfica, grupo de personagens carismáticos e sistemas de progressão profundos, unindo a atmosfera e o drama de Final Fantasy VII, a clareza estratégica do combate de Final Fantasy X e o ritmo, as técnicas combinadas e a estrutura de múltiplos finais de Chrono Trigger.'),
  P('**Mundo:** fantasia clássica mesclada com steampunk — reinos, magia e ruínas antigas convivendo com engrenagens, vapor, dirigíveis e máquinas.'),
  P('**Tom:** mistura equilibrada — começa leve e aventureiro e ganha peso dramático a cada ato.'),
  P('**Título provisório:** O Coração de Éter.'),
  P('**Premissa:** um império a vapor extrai o Éter — a energia vital do mundo — para mover suas máquinas, e a magia está morrendo. Um aprendiz de mecânico de uma cidade-oficina na fronteira do Império descobre que consegue ouvir as máquinas quando um autômato antigo desperta e diz o seu nome. No Ato 2, o grupo descobre que o verdadeiro inimigo não é o Império, e sim quem criou o Éter.'),
  H2('2.2 Pilares de design'),
  N('**Combate estratégico e acessível** — cada turno tem uma escolha interessante; nada de "apertar ataque" sem pensar.', 'pilares'),
  N('**Personagens que importam** — cada membro do grupo tem arco próprio, habilidades únicas e papel mecânico distinto.', 'pilares'),
  N('**Mundo que convida à exploração** — segredos, missões secundárias, chefes opcionais e recompensas por curiosidade.', 'pilares'),
  N('**Progressão visível e satisfatória** — o jogador sente o crescimento do grupo a cada hora de jogo.', 'pilares'),
  N('**Escopo realista** — um jogo completo e polido vale mais que um jogo enorme inacabado.', 'pilares'),
  H2('2.3 O que herdamos de cada referência'),
  table(['Referência', 'Elementos a aproveitar'], [
    ['Final Fantasy VII', 'Sistema de Materia (habilidades equipáveis em slots), Limit Breaks, mistura de cidade industrial e fantasia, minigames, trilha dramática, mapa-múndi com veículos.'],
    ['Final Fantasy X', 'Combate CTB (Conditional Turn-Based) com linha do tempo de turnos visível, troca de personagens durante a batalha, Sphere Grid (árvore de progressão), Overdrives, narrativa linear forte.'],
    ['Chrono Trigger', 'Inimigos visíveis no mapa (sem encontros aleatórios), batalha no próprio cenário, Dual/Triple Techs, viagem no tempo entre eras, New Game+, múltiplos finais, ritmo ágil.'],
  ], [22, 78]),
  gap(),
  H2('2.4 Ficha técnica (proposta)'),
  table(['Item', 'Proposta', 'Status'], [
    ['Gênero', 'JRPG por turnos', 'Proposta'],
    ['Estilo visual', 'Pixel art 16-bit (estilo SNES)', 'Decidido (D-02)'],
    ['Perspectiva', '2D top-down 3/4', 'Decidido (D-02)'],
    ['Combate', 'Híbrido: turnos CTB + comandos com timing', 'Decidido (D-03)'],
    ['Batalhas', 'No próprio mapa, inimigos visíveis', 'Decidido (D-04)'],
    ['Plataforma', 'PC (Windows) — outras depois', 'Proposta'],
    ['Resolução base', '640×360, escala inteira (1280×720, 1920×1080…)', 'Decidido (D-07)'],
    ['Duração alvo', '15–25 horas (história principal)', 'A decidir'],
    ['Idiomas', 'Português (BR) + Inglês', 'Proposta'],
    ['Controles', 'Teclado e gamepad', 'Proposta'],
    ['Classificação', 'Livre / 12 anos', 'A decidir'],
  ], [25, 55, 20]),
);

// 3. Equipe
children.push(
  H1('3. Equipe, papéis e ferramentas'),
  H2('3.1 Papéis'),
  table(['Quem', 'Responsabilidades'], [
    ['Você (Diretor criativo)', 'Visão do jogo, história, aprovação de arte e design, testes de jogabilidade, decisões finais, prioridades.'],
    ['Claude (Programação)', 'Arquitetura, todo o código GDScript, cenas Godot, ferramentas internas, dados do jogo, integração de assets, documentação técnica, correção de bugs.'],
    ['Codex (Arte)', 'Geração de imagens: conceitos, sprites, tilesets, retratos, ícones, UI, fundos, efeitos. Chamado pelo Claude via Codex CLI (tools/gen_image.ps1) a partir do guia de estilo.'],
    ['IA de áudio (a escolher)', 'Música e efeitos sonoros gerados por IA — ver seção 9.'],
  ], [28, 72]),
  gap(),
  H2('3.2 Ferramentas'),
  table(['Ferramenta', 'Uso', 'Local / Observação'], [
    ['Godot 4.7.2', 'Engine do jogo', 'D:\\Godot\\Godot_v4.7.2-stable_win64.exe'],
    ['Godot (console)', 'Execução headless, testes e exportação por linha de comando', 'D:\\Godot\\Godot_v4.7.2-stable_win64_console.exe'],
    ['GDScript', 'Linguagem principal (tipagem estática)', '—'],
    ['Claude Code', 'Desenvolvimento e automação', 'Pasta D:\\Projeto RPG'],
    ['Codex CLI 0.156.1', 'Geração de imagens (gpt-5.5 + image_gen embutido)', 'tools\\codex-cli, via tools\\gen_image.ps1'],
    ['Codex MCP (ponte nova)', 'Geração de imagens pelo Codex App Server', 'servidor "codex" (adapter.cjs); testado com o Eco'],
    ['Suno MCP (AceDataCloud)', 'Música e efeitos por IA', 'servidor "suno-music"; token validado'],
    ['Git + GitHub', 'Controle de versão', 'github.com/RudyAlmeida/projeto-rpg (branch main)'],
    ['GUT 9.7.1', 'Testes automatizados', 'game/addons/gut; rodar com tools\\run_tests.ps1'],
    ['tools/art/pixelize.mjs', 'Converte imagem do Codex em sprite (fundo, grade, paleta)', 'Node + @napi-rs/canvas'],
    ['Aseprite / Krita (opcional)', 'Ajustes manuais em sprites', 'Opcional; paleta velmora32.hex'],
  ], [22, 43, 35]),
);

// 4. Sistemas
const sys = (nome, desc, items) => [H3(nome), P(desc), ...items.map(i => B(i))];
children.push(
  H1('4. Sistemas de jogo (escopo completo)'),
  P('Lista de tudo que o jogo completo precisa. Cada sistema é detalhado em documento de design próprio antes de ser implementado.'),
  H2('4.1 Combate'),
  ...sys('Modelo de turnos (D-03: híbrido)', 'Linha do tempo CTB (estilo FFX) com ordem de turnos visível e ações que alteram a ordem, somada a comandos com timing: apertar o botão no momento certo durante ataques e técnicas aumenta o efeito, e durante ataques inimigos reduz o dano (estilo Sea of Stars / Super Mario RPG).', [
    'O jogo pausa na escolha do comando; o timing só vale durante a execução da ação.',
    'Opção de acessibilidade: timing automático.',
    'Grupo ativo de 3 personagens, troca com reservas durante a batalha.',
    'Comandos: Atacar, Técnicas, Magia, Itens, Defender, Trocar, Fugir.',
  ]),
  ...sys('Mecânicas', 'Profundidade estratégica.', [
    'Fraquezas e resistências elementais (Fogo, Gelo, Raio, Água, Terra, Vento, Luz, Sombra).',
    'Status: Veneno, Sono, Silêncio, Cegueira, Paralisia, Confusão, Petrificação, Haste, Slow, Proteção, Regen etc.',
    'Técnicas combinadas (Dual/Triple Techs) entre personagens.',
    'Golpe especial com barra de carga (Limit Break / Overdrive).',
    'Posicionamento no cenário para técnicas de área (linha, círculo, cone).',
    'Chefes com fases, padrões e mecânicas próprias.',
    'IA de inimigos baseada em regras (prioridades, condições de HP, alvos).',
  ]),
  ...sys('Transição para batalha', 'Estilo Chrono Trigger.', [
    'Inimigos visíveis no mapa; contato inicia batalha.',
    'Vantagem/emboscada conforme quem inicia o contato.',
    '**D-04:** batalha no próprio cenário, sem troca de tela; o grupo e os inimigos se posicionam no local do encontro.',
    'Mapas precisam ter áreas de combate com espaço suficiente para as posições de batalha.',
  ]),
  H2('4.2 Personagens e progressão'),
  B('Atributos: HP, MP, Força, Magia, Defesa, Espírito, Velocidade, Sorte, Precisão, Evasão.'),
  B('**D-05 (híbrido):** níveis por experiência + árvore de habilidades própria de cada personagem (identidade) + gemas equipáveis que sobem de nível com o uso (personalização).'),
  B('Equipamento: arma, armadura, acessório, com slots para gemas.'),
  B('6 a 8 personagens jogáveis com classes e papéis distintos.'),
  H2('4.3 Exploração'),
  B('Movimento em 8 direções, colisão, interação com NPCs e objetos.'),
  B('Cidades, dungeons, mapa-múndi com veículos (barco a vapor, dirigível).'),
  B('Puzzles ambientais simples (alavancas, blocos, portas).'),
  B('Baús, itens escondidos, pontos de salvamento.'),
  B('Transições de área, portas, teleporte, ciclo dia/noite (opcional).'),
  B('**D-06:** sem viagem no tempo — um único mundo com regiões bem distintas.'),
  H2('4.4 Narrativa e diálogos'),
  B('Caixa de diálogo com retrato, nome, efeito de digitação e escolhas.'),
  B('Sistema de cutscenes (movimento de personagens, câmera, falas, pausas, efeitos).'),
  B('Flags de história e variáveis globais; missões principais e secundárias; diário de missões.'),
  B('**Sistema de afinidade:** valores ocultos por personagem, alterados por escolhas de diálogo e ações; controla o triângulo Kael–Lyra–Isolde.'),
  B('**Finais:** 2 principais (agridoce / completo) × 3 epílogos de romance (Lyra / Isolde / sem romance).'),
  H2('4.5 Economia e itens'),
  B('Itens consumíveis, equipamentos, itens-chave, materiais.'),
  B('Lojas (compra/venda), estalagens, ferreiro/crafting (opcional).'),
  B('Tabelas de drop e roubo.'),
  H2('4.6 Interface (UI)'),
  B('Tela de título, novo jogo, continuar, opções, créditos.'),
  B('Menu principal: Itens, Habilidades, Equipamento, Status, Formação, Progressão, Configurações, Salvar.'),
  B('HUD de batalha: HP/MP, linha do tempo de turnos, menus de comando, números de dano, alvos.'),
  B('Bestiário, lista de missões, mapa.'),
  H2('4.7 Sistemas de suporte'),
  B('Salvar/carregar (vários slots, autosave, versão do save).'),
  B('Opções: volume, velocidade de texto, velocidade de batalha, remapeamento de controles, idioma, tela cheia.'),
  B('Localização (arquivos de tradução do Godot).'),
  B('Minigames e conteúdo opcional (colosseu, chefes secretos, New Game+).'),
  B('Conquistas (opcional).'),
);

// 5. Arquitetura
children.push(
  H1('5. Arquitetura técnica'),
  H2('5.1 Princípios'),
  B('**Orientado a dados:** personagens, inimigos, itens, habilidades e diálogos definidos como Resources (.tres) ou JSON, não no código.'),
  B('**Cenas pequenas e reutilizáveis;** comunicação por sinais; baixo acoplamento.'),
  B('**GDScript com tipagem estática** em todo o código.'),
  B('**Autoloads (singletons) apenas para serviços globais.**'),
  B('**Testes automatizados** para regras de combate, fórmulas e save.'),
  H2('5.2 Estrutura de pastas proposta'),
  table(['Pasta', 'Conteúdo'], [
    ['res://assets/', 'Arte, áudio, fontes (subpastas: sprites, tilesets, portraits, ui, vfx, audio)'],
    ['res://data/', 'Resources de dados: characters, enemies, items, skills, encounters, dialogues'],
    ['res://scenes/', 'Cenas: world, battle, ui, characters, maps'],
    ['res://scripts/', 'Scripts de lógica: core, battle, world, ui, systems'],
    ['res://autoload/', 'Singletons globais'],
    ['res://tests/', 'Testes automatizados'],
    ['res://tools/', 'Ferramentas de editor e scripts de importação'],
    ['/docs (fora do res)', 'Documentos de design e este controle'],
  ], [28, 72]),
  gap(),
  H2('5.3 Autoloads previstos'),
  table(['Autoload', 'Responsabilidade'], [
    ['GameState', 'Estado global: grupo, inventário, dinheiro, flags, tempo de jogo'],
    ['SceneManager', 'Troca de cenas, transições (fade), carregamento'],
    ['SaveManager', 'Salvar/carregar, slots, versionamento'],
    ['AudioManager', 'Música, crossfade, SFX, volumes'],
    ['EventBus', 'Sinais globais desacoplados'],
    ['DataRegistry', 'Acesso indexado aos Resources de dados'],
    ['DialogueManager', 'Execução de diálogos e cutscenes'],
  ], [28, 72]),
  gap(),
  H2('5.4 Convenções de código'),
  B('Arquivos e pastas em snake_case; classes em PascalCase (class_name); constantes em UPPER_CASE.'),
  B('Código e identificadores em inglês; textos do jogo via sistema de tradução.'),
  B('Um script por responsabilidade; funções curtas; sinais nomeados no passado (hp_changed, battle_ended).'),
);

// 6. Arte
children.push(
  H1('6. Direção de arte e pipeline de imagens (Codex)'),
  H2('6.1 Estilo visual — D-02: pixel art 16-bit'),
  P('Estilo SNES (Chrono Trigger, FF6, Sea of Stars), com temática de fantasia clássica + steampunk: pedra, madeira e magia ao lado de latão, cobre, engrenagens e vapor. Validado com a imagem de teste codex_test_01.png.'),
  table(['Especificação', 'Valor'], [
    ['Resolução base', '640×360, escala inteira, filtro Nearest'],
    ['Tiles', '16×16 px'],
    ['Personagens (mapa/batalha)', '~32×56 px em célula 64×64 (ver Guia de Estilo)'],
    ['Retratos de diálogo', 'a definir no guia de estilo (ex.: 64×64)'],
    ['Paleta', 'limitada e fixa, definida no guia de estilo'],
    ['Contorno / luz', 'contorno escuro, luz vinda de cima à esquerda'],
  ], [35, 65]),
  gap(),
  H2('6.2 Lista de assets necessários'),
  table(['Categoria', 'Itens', 'Estimativa'], [
    ['Arte conceitual', 'Personagens, regiões, cidades, inimigos, chefes', '40–60'],
    ['Sprites de personagens', 'Andar 4/8 dir., idle, batalha (ataque, magia, dano, KO, vitória)', '6–8 personagens'],
    ['Sprites de NPCs', 'Variações de habitantes, lojistas, guardas', '30–50'],
    ['Sprites de inimigos', 'Inimigos comuns + chefes', '60–100'],
    ['Retratos', 'Expressões para diálogo (neutro, feliz, triste, bravo, surpreso)', '~5 por personagem principal'],
    ['Tilesets', 'Campo, floresta, caverna, cidade, castelo, tecnológico, neve, deserto…', '10–15 biomas'],
    ['Fundos de batalha', 'Um por região/dungeon', '15–25'],
    ['UI', 'Molduras, botões, cursores, barras, fontes, ícones de itens/habilidades', '150+ ícones'],
    ['Efeitos (VFX)', 'Magias, golpes, status, técnicas combinadas', '40+'],
    ['Telas especiais', 'Título, logo, mapa-múndi, créditos, finais', '10+'],
  ], [22, 58, 20]),
  gap(),
  H2('6.3 Pipeline de geração'),
  N('Gerar com **tools/gen_image.ps1** (Codex CLI 0.156.1, gpt-5.5, image_gen embutido), que salva direto em game/.', 'pipe'),
  N('Criar e aprovar o **Guia de Estilo** (paleta, proporções, resolução, iluminação, prompt-base).', 'pipe'),
  N('Gerar **folha de referência** (model sheet) de cada personagem e aprovar.', 'pipe'),
  N('Gerar assets a partir do prompt-base + referência aprovada, para manter consistência.', 'pipe'),
  N('Pós-processamento: recorte, fundo transparente, redução de paleta, redimensionamento, montagem de spritesheets.', 'pipe'),
  N('Importar no Godot com configurações corretas (filtro Nearest para pixel art).', 'pipe'),
  N('Revisão do Diretor → aprovado / refazer. Registrar em "Controle de assets".', 'pipe'),
  H2('6.4 Convenções de nomes de arquivos'),
  B('Formato: categoria_nome_variação_frame.png — ex.: chr_hero_walk_down_01.png, enm_slime_idle_01.png, ico_potion.png.'),
  B('Prefixos: chr (personagem), npc, enm (inimigo), bos (chefe), por (retrato), til (tileset), bg (fundo), ui, ico, vfx, cpt (conceito).'),
  B('Prompts usados ficam salvos em assets/_prompts/ junto com o nome do arquivo gerado, para reprodutibilidade.'),
  H2('6.5 Riscos conhecidos da arte gerada'),
  B('Inconsistência entre imagens do mesmo personagem → usar referência e prompt-base fixos.'),
  B('Animação quadro a quadro difícil de gerar → considerar animação por partes (cutout/Skeleton2D) ou poucos frames + tweens.'),
  B('Pixel art "falso" (pixels irregulares) → pós-processar com redução de resolução e paleta fixa.'),
);

// 7. Narrativa
children.push(
  H1('7. Narrativa e mundo'),
  P('Seção a ser preenchida na Fase 0 junto com o Diretor criativo.'),
  table(['Elemento', 'Descrição', 'Status'], [
    ['Título do jogo', 'O Coração de Éter (provisório)', WIP],
    ['Premissa (1 parágrafo)', 'Império a vapor drena o Éter e a magia morre; aprendiz de mecânico que ouve máquinas é chamado pelo nome por um autômato antigo', DONE],
    ['Tema central', 'Progresso x natureza; o preço do progresso e o sacrifício', WIP],
    ['Tom', 'Mistura equilibrada: começa leve e aventureiro, fica mais sério e dramático a cada ato', DONE],
    ['Mundo / cenário', 'Fantasia clássica + steampunk', DONE],
    ['Regiões', 'Um único mundo (sem viagem no tempo — D-06)', WIP],
    ['Protagonista', 'Aprendiz de mecânico de uma cidade-oficina na fronteira do Império; ouve as máquinas', WIP],
    ['Grupo (6–8 personagens)', 'Kael, Eco, Lyra, Brann, Mira, Selene, Isolde + Gerd como convidado (ver bíblia da história)', DONE],
    ['Antagonista principal', 'Aparente: o Império. Real: o criador do Éter (revelado no Ato 2)', WIP],
    ['Estrutura em atos', 'Prólogo + 3 atos; o mundo se parte no fim do Ato 2', DONE],
    ['Final(is)', '2 finais (agridoce / completo) × 3 epílogos de romance', DONE],
  ], [30, 50, 20]),
  gap(),
  H2('7.1 Ficha de personagem (modelo)'),
  table(['Campo', 'Preencher'], [
    ['Nome / idade', ''], ['Papel na história', ''], ['Personalidade', ''], ['Motivação e arco', ''],
    ['Papel em combate', ''], ['Arma', ''], ['Elemento / afinidade', ''], ['Golpe especial', ''], ['Aparência (para prompt)', ''],
  ], [35, 65]),
  gap(),
  H2('7.2 Estrutura sugerida (3 atos)'),
  table(['Ato', 'Conteúdo', 'Duração alvo'], [
    ['Prólogo', 'Introdução, tutorial, incidente que inicia a jornada', '1–2 h'],
    ['Ato 1', 'Formação do grupo, primeiras regiões, revelação do antagonista', '5–7 h'],
    ['Ato 2', 'Mundo se abre, veículos, reviravolta maior', '6–9 h'],
    ['Ato 3', 'Conteúdo opcional, preparação final, confronto', '3–5 h'],
    ['Pós-jogo', 'Chefes secretos, New Game+, finais alternativos', 'opcional'],
  ], [18, 62, 20]),
);

// 8. Conteúdo
children.push(
  H1('8. Metas de conteúdo'),
  P('Números de referência para o jogo completo; revisar ao fim da Fase 0.'),
  table(['Conteúdo', 'Meta (completo)', 'Meta (vertical slice)'], [
    ['Personagens jogáveis', '6–8', '3'],
    ['Cidades / vilas', '8–10', '1'],
    ['Dungeons', '12–15', '1'],
    ['Regiões do mapa-múndi', '5–6', '—'],
    ['Inimigos comuns', '60–80', '6–8'],
    ['Chefes', '15–20', '1'],
    ['Habilidades / magias', '80–120', '12–15'],
    ['Itens e equipamentos', '150–200', '20'],
    ['Missões secundárias', '20–30', '1–2'],
    ['Faixas de música', '30–40', '4–5'],
  ], [40, 30, 30]),
);

// 9. Áudio
children.push(
  H1('9. Áudio'),
  P('**D-08:** música e efeitos sonoros gerados por IA. O Codex não gera áudio, então é preciso escolher a ferramenta.'),
  B('Escolher a ferramenta de IA de áudio e confirmar que os termos permitem **uso comercial** e distribuição do jogo.'),
  B('Estilo musical alvo: orquestra + chiptune/SNES, com temas de personagem e leitmotifs.'),
  B('Formato no Godot: OGG Vorbis para música (com pontos de loop), WAV para efeitos curtos.'),
  B('Guardar os prompts de áudio em assets/_prompts/, como nas imagens.'),
  B('Músicas necessárias: título, campo, cidade(s), dungeon(s), batalha, chefe, chefe final, vitória, game over, temas de personagem, cenas emotivas.'),
  B('SFX: menu (cursor, confirmar, cancelar), passos, portas, baús, golpes, magias, status, level up.'),
  B('Todas as licenças registradas em docs/licencas.md.'),
);

// 10. Fases
children.push(
  H1('10. Fases do projeto — controle'),
  table(['Fase', 'Nome', 'Resultado', 'Status'], [
    ['0', 'Pré-produção', 'Decisões, documentos de design, guia de estilo, projeto Godot criado', '☑ Concluída'],
    ['1', 'Protótipo técnico', 'Andar em um mapa, falar com NPC, entrar em batalha, vencer', '☑ Concluída'],
    ['2', 'Sistemas centrais', 'Todos os sistemas principais funcionando com conteúdo de teste', '◐ Em andamento'],
    ['3', 'Vertical slice', '30–60 min jogáveis com qualidade final', '☐ Pendente'],
    ['4', 'Produção de conteúdo', 'Jogo completo do início ao fim (Alpha)', '☐ Pendente'],
    ['5', 'Polimento e balanceamento', 'Beta: conteúdo fechado, balanceado e polido', '☐ Pendente'],
    ['6', 'QA e lançamento', 'Build final (Release 1.0) e publicação', '☐ Pendente'],
  ], [8, 24, 48, 20]),
  gap(),
);
children.push(...phase(0, 'Pré-produção',
  'Tomar as decisões fundamentais e preparar a base técnica e criativa.',
  'Este documento completo, guia de estilo aprovado, projeto Godot configurado e versionado.',
  [
    ['Criar documento de planejamento (este arquivo)', 'Claude', 'v0.2', DONE],
    ['Definir título, premissa e tom', 'Diretor', 'D-01: O Coração de Éter', DONE],
    ['Definir estilo visual', 'Diretor + Claude', 'D-02: pixel art 16-bit', DONE],
    ['Definir modelo de combate', 'Diretor + Claude', 'D-03: híbrido', DONE],
    ['Definir transição e arena de batalha', 'Diretor + Claude', 'D-04: no próprio mapa', DONE],
    ['Definir sistema de progressão', 'Diretor + Claude', 'D-05: híbrido', DONE],
    ['Decidir sobre viagem no tempo', 'Diretor', 'D-06: não', DONE],
    ['Definir resolução e escala', 'Claude', 'D-07: 640×360', DONE],
    ['Definir fonte de áudio', 'Diretor', 'D-08: IA; falta escolher a ferramenta', DONE],
    ['Inicializar Git e publicar no GitHub', 'Claude', 'Commit 756f831', DONE],
    ['Criar projeto Godot 4.7.2 e estrutura de pastas', 'Claude', 'game/', DONE],
    ['Configurar input map (teclado + gamepad)', 'Claude', '12 ações via game/tools/setup_input_map.gd', DONE],
    ['Escolher framework de testes (GUT / gdUnit4)', 'Claude', 'GUT 9.7.1; tools/run_tests.ps1', DONE],
    ['Testar geração de imagem via Codex', 'Claude', 'codex_test_01.png via Codex CLI (MCP incompatível)', DONE],
    ['Escolher ferramenta de IA de áudio', 'Diretor + Claude', 'Suno via MCP da AceDataCloud; conta paga dá direito comercial (confirmado pelo Diretor)', DONE],
    ['Criar Guia de Estilo + prompt-base', 'Claude + Diretor', 'Guia de Estilo v1.0 aprovado', DONE],
    ['Esboçar história em atos e o grupo principal', 'Diretor + Claude', 'Bíblia da história v0.2 aprovada (H-01 a H-06)', DONE],
    ['Escrever GDD do sistema de combate', 'Claude', 'GDD v1.0 aprovado: docs/GDD_Combate.docx', DONE],
  ],
  ['Todas as decisões D-01 a D-08 registradas.', 'Projeto abre no Godot sem erros e está versionado.', 'Guia de estilo aprovado com ao menos 3 imagens de referência.'],
));
children.push(...phase(1, 'Protótipo técnico',
  'Provar o ciclo básico do jogo o mais cedo possível, com arte provisória.',
  'Build jogável: explorar um mapa, conversar, iniciar batalha, vencer/perder, voltar ao mapa.',
  [
    ['Personagem controlável com animação de andar', 'Claude', '8 direções, corrida, ciclo de caminhada de 4 quadros × 3 direções (Codex com referência)', DONE],
    ['TileMap de teste com colisão', 'Claude', 'AsciiMap + tiles provisórios na paleta Velmora', DONE],
    ['Câmera seguindo o jogador com limites', 'Claude', 'Suavizada, presa às bordas do mapa', DONE],
    ['Interação com NPC + caixa de diálogo simples', 'Claude', 'Mestre Gerd no mapa; caixa com retrato, nome e texto letra por letra; fonte Pixelify Sans (OFL)', DONE],
    ['SceneManager com transições (fade)', 'Claude', 'Portas (Warp), pontos de chegada, interior de casa; AudioManager mantém a música entre salas', DONE],
    ['Inimigo visível no mapa que inicia batalha', 'Claude', 'FieldEnemy com patrulha; batalha no próprio mapa (D-04)', DONE],
    ['Batalha mínima: 3 heróis x 2 inimigos, atacar/defender', 'Claude', 'Kael, Lyra, Brann × 2 Slimes de Óleo; Atacar, Defender, Fogo', DONE],
    ['Ordem de turnos CTB (versão inicial)', 'Claude', 'Fila na tela com os próximos turnos', DONE],
    ['Primeiro comando com timing', 'Claude', 'Anel que fecha no impacto: ataque e defesa (Perfeito/Bom)', DONE],
    ['Vitória / derrota / retorno ao mapa', 'Claude', 'Vitória com XP e moedas; derrota repete a batalha', DONE],
    ['Primeiro sprite gerado pelo Codex integrado', 'Claude', 'Kael, Gerd, Brann, Slime no jogo', DONE],
    ['Playtest do protótipo', 'Diretor', 'Aprovado pelo Diretor em 25/09/2026', DONE],
  ],
  ['Ciclo completo jogável sem travamentos.', 'Diretor aprovou a sensação de controle e de combate.'],
));
children.push(...phase(2, 'Sistemas centrais',
  'Implementar todos os sistemas principais com dados de teste. Ordem: A) base persistente (estado, níveis, salvar); B) combate completo; C) progressão (inventário, equipamento, gemas, árvores); D) mundo e interface (menu, lojas, diálogo, cutscenes, missões, opções).',
  'Build com todos os sistemas funcionando de ponta a ponta.',
  [
    ['Modelos de dados (Resources): personagem, inimigo, item, habilidade', 'Claude', 'CombatantData, SkillData, ItemData, DualTechData, AIRule; gerador game/tools/build_data.gd; DataRegistry', DONE],
    ['Atributos, níveis e experiência', 'Claude', 'PartyMember: crescimento por nível, curva de XP, XP dividido (KO 50%)', DONE],
    ['Combate completo: habilidades, magias, itens, alvos', 'Claude', 'Menu Atacar/Técnicas/Itens/Defender/Trocar/Fugir; alvo único, todos, aliado caído; fuga; iniciativa/emboscada; música de batalha e vitória', DONE],
    ['Elementos, fraquezas e status', 'Claude', '14 status do GDD, imunidades, resistência por Espírito, fator Éter regional', DONE],
    ['Golpe especial (Limit / Overdrive)', 'Claude', 'Barra de Éter persistente; especial de Kael, Lyra, Brann e Eco', DONE],
    ['Técnicas combinadas (Dual/Triple)', 'Claude', 'Faísca Viva, Muralha de Ferro, Rugido da Terra (tripla); um timing por participante', DONE],
    ['IA de inimigos', 'Claude', 'Regras por prioridade/condição/alvo, avisos de golpe forte (Sentinela)', DONE],
    ['Troca de personagens em batalha', 'Claude', 'Reserva entra no turno (estilo FFX), uma troca por turno; Eco como 4º membro', DONE],
    ['Árvores de habilidade por personagem', 'Claude', '6 nós por herói; Pontos de Habilidade (2 por nível); tela no menu', DONE],
    ['Gemas equipáveis com nível', 'Claude', '6 gemas únicas com AP e 3 níveis; encaixes nas peças; tela no menu', DONE],
    ['Inventário e equipamento', 'Claude', 'Arma/armadura/acessório com comparação de atributos; 12 peças', DONE],
    ['Lojas e estalagens', 'Claude', 'Loja comprar/vender (metade do preço); estalagem com descanso', DONE],
    ['Menu principal completo', 'Claude', 'Itens, Equipar, Gemas, Árvore, Status, Formação, Missões, Opções, Salvar', DONE],
    ['Diálogo com retratos, escolhas e flags', 'Claude', 'Escolhas com flags e afinidade; ramos por estado da história', DONE],
    ['Sistema de cutscenes', 'Claude', 'Passos em dados (falar, andar, virar, fade, flags, missão, item, música)', DONE],
    ['Missões e diário', 'Claude', 'QuestData, objetivos por eventos, recompensas, diário no menu', DONE],
    ['Sistema de afinidade (romance e finais)', 'Claude', 'Afinidade Lyra/Isolde por escolhas (epílogos ficam para a produção de conteúdo)', DONE],
    ['Salvar / carregar', 'Claude', 'SaveManager: JSON versionado em user://saves; GameState (grupo, dinheiro, inventário, flags, tempo)', DONE],
    ['AudioManager', 'Claude', 'Pilha de músicas (batalha/mapa), volume', DONE],
    ['Tela de opções e localização', 'Claude', 'Volume, texto, timing (fácil/normal/difícil/auto), tela cheia, idioma; menus em inglês via CSV', DONE],
    ['Testes automatizados de combate e save', 'Claude', '155 testes GUT', DONE],
  ],
  ['Todos os sistemas usáveis em uma cena de teste.', 'Testes automatizados passando.', 'Save/load preserva todo o estado.'],
));
children.push(...phase(3, 'Vertical slice',
  'Produzir um trecho curto do jogo com qualidade final para validar estilo, ritmo e diversão.',
  '30–60 minutos jogáveis: prólogo, 1 cidade, 1 dungeon, 1 chefe.',
  [
    ['Roteiro do prólogo', 'Diretor + Claude', ''],
    ['Arte final dos 3 personagens iniciais', 'Claude (Codex)', ''],
    ['Tilesets da cidade e da dungeon', 'Claude (Codex)', ''],
    ['6–8 inimigos + 1 chefe', 'Claude (Codex + código)', ''],
    ['UI final (molduras, ícones, fonte)', 'Claude (Codex)', ''],
    ['Efeitos visuais de batalha', 'Claude', ''],
    ['Músicas e SFX do trecho', 'Claude (IA de áudio)', ''],
    ['Cutscenes do prólogo', 'Claude', ''],
    ['Balanceamento do trecho', 'Claude + Diretor', ''],
    ['Playtest externo (2–3 pessoas)', 'Diretor', ''],
  ],
  ['Diretor considera o trecho representativo do jogo final.', 'Feedback de playtest registrado e ações definidas.', 'Escopo do jogo completo revisado com base no tempo gasto.'],
));
children.push(...phase(4, 'Produção de conteúdo',
  'Construir o jogo completo, ato por ato.',
  'Alpha: jogo jogável do início ao fim (pode haver arte/áudio provisórios).',
  [
    ['Ato 1: mapas, eventos, inimigos, chefes', 'Claude + Codex', ''],
    ['Ato 2: mapas, eventos, inimigos, chefes', 'Claude + Codex', ''],
    ['Ato 3: mapas, eventos, inimigos, chefes', 'Claude + Codex', ''],
    ['Mapa-múndi e veículos', 'Claude', ''],
    ['Personagens restantes do grupo', 'Claude + Codex', ''],
    ['Missões secundárias', 'Claude + Diretor', ''],
    ['Conteúdo opcional (chefes secretos, colosseu)', 'Claude', ''],
    ['Final(is) e créditos', 'Claude + Diretor', ''],
    ['Minigames', 'Claude', 'Opcional'],
  ],
  ['É possível jogar do início aos créditos.', 'Nenhum bloqueio de progresso conhecido.'],
));
children.push(...phase(5, 'Polimento e balanceamento',
  'Deixar o jogo divertido, justo e bonito.',
  'Beta: conteúdo e arte finais, balanceado.',
  [
    ['Planilha de balanceamento (curva de XP, dano, economia)', 'Claude', ''],
    ['Substituir toda arte provisória', 'Claude (Codex)', ''],
    ['Juice: tremores de câmera, partículas, feedback de acerto', 'Claude', ''],
    ['Acessibilidade: velocidade de texto, legendas, remapeamento', 'Claude', ''],
    ['Revisão de textos e tradução para inglês', 'Diretor + Claude', ''],
    ['Otimização de desempenho', 'Claude', ''],
    ['Rodada de playtest completa', 'Diretor + testers', ''],
  ],
  ['Jogo completo sem arte provisória.', 'Nenhum bug crítico ou grave aberto.'],
));
children.push(...phase(6, 'QA e lançamento',
  'Publicar uma versão estável.',
  'Release 1.0 publicada.',
  [
    ['Rodada final de testes e correções', 'Todos', ''],
    ['Configurar exportação para Windows', 'Claude', ''],
    ['Ícone, splash screen, créditos e licenças', 'Claude', ''],
    ['Página da loja (itch.io / Steam), trailer e capturas', 'Diretor + Claude', ''],
    ['Build release e publicação', 'Diretor', ''],
    ['Plano de patches pós-lançamento', 'Claude', ''],
  ],
  ['Build publicada e instalável.', 'Todas as licenças de terceiros documentadas.'],
));

// 11. Controle de assets
children.push(
  H1('11. Controle de assets'),
  P('Registro de cada imagem gerada. Adicionar linhas conforme a produção avança.'),
  table(['ID', 'Arquivo', 'Tipo', 'Fase', 'Status', 'Obs.'], [
    ['A-001', 'assets/_tests/codex_test_01.png', 'Teste de estilo', 'F0', DONE, 'Herói, 4 poses, 2056×765; precisa de tratamento de grade/paleta'],
    ['A-002', 'assets/_source/chr_kael_ref_raw_v1.png', 'Referência (bruta)', 'F0', DONE, 'Kael oficial, 4 poses, fundo transparente'],
    ['A-003', 'assets/sprites/characters/kael/chr_kael_ref.png', 'Sprite', 'F0', WIP, '4 quadros 64×64, velmora32; rosto da pose de combate pede retoque'],
    ['A-004', 'assets/_source/chr_eco_ref_raw_v1.png', 'Referência (bruta)', 'F0', DONE, 'Eco; gerado pela ponte MCP do Codex'],
    ['A-005', 'assets/sprites/characters/eco/chr_eco_ref.png', 'Sprite', 'F0', DONE, '4 quadros 64×64; pedra levemente pêssego'],
    ['A-006', 'assets/_source/chr_lyra_ref_raw_v1.png', 'Referência (bruta)', 'F0', DONE, 'Lyra; gerada pelo gen_image.ps1'],
    ['A-007', 'assets/sprites/characters/lyra/chr_lyra_ref.png', 'Sprite', 'F0', DONE, '4 quadros 64×64'],
    ['A-008', 'assets/audio/music/bgm_vila_caldeira_test_a.mp3', 'Música', 'F0', DONE, 'Aprovada: tema de Vila Caldeira (Suno chirp-v5-5, 60 s)'],
    ['A-009', 'assets/audio/music/bgm_vila_caldeira_test_b.mp3', 'Música (reserva)', 'F0', DONE, 'Variação B (55 s), guardada para uso futuro'],
    ['A-010', 'assets/_source/chr_kael_walk_raw_v1.png', 'Referência (bruta)', 'F1', DONE, 'Caminhada do Kael; gerada pela ponte MCP com a referência oficial anexada'],
    ['A-011', 'assets/sprites/characters/kael/chr_kael_walk.png', 'Sprite', 'F1', DONE, 'Grade 3 × 4 de 64×64 (baixo, esquerda, cima)'],
    ['A-012', 'assets/sprites/characters/gerd/npc_gerd_ref.png', 'Sprite', 'F1', DONE, 'Mestre Gerd, 4 poses (52 px, mais baixo que o Kael)'],
    ['A-013', 'assets/portraits/por_kael_neutral.png', 'Retrato', 'F1', DONE, '64×64, gerado com a referência do Kael'],
    ['A-014', 'assets/portraits/por_gerd_neutral.png', 'Retrato', 'F1', DONE, '64×64, gerado com a referência do Gerd'],
    ['A-015', 'assets/fonts/PixelifySans.ttf', 'Fonte', 'F1', DONE, 'Google Fonts, licença OFL 1.1 (texto em assets/fonts/)'],
    ['A-016', 'assets/sprites/characters/brann/chr_brann_ref.png', 'Sprite', 'F1', DONE, 'Brann, 4 poses; manopla a vapor'],
    ['A-017', 'assets/sprites/enemies/enm_oil_slime.png', 'Sprite', 'F1', DONE, 'Slime de Óleo: parado, respirando, ataque, dano (56×48)'],
    ['A-018', 'assets/sprites/enemies/enm_brass_sentinel.png', 'Sprite', 'F2', DONE, 'Sentinela de Latão (inimigo mecânico, 72×48)'],
    ['A-019', 'assets/ui/ico_items.png', 'Ícones', 'F2', DONE, '16 ícones 16×16: consumíveis, equipamentos, gemas'],
    ['A-020', 'assets/sprites/characters/villagers/npc_villagers.png', 'Sprite', 'F2', DONE, 'Lojista e estalajadeira (grade 2 × 4)'],
    ['A-021', 'assets/ui/bg_title.png', 'Arte', 'F2', DONE, 'Tela de título 640×360 (Kael, Eco e o Coração de Éter)'],
    ['A-022', 'assets/audio/music/bgm_battle_a.mp3 + _b.mp3', 'Música', 'F2', DONE, 'Temas de batalha (Suno, 90 s) — aprovados os dois; o jogo alterna A e B a cada batalha'],
    ['A-023', 'assets/audio/music/bgm_victory_a.mp3', 'Música', 'F2', WIP, 'Fanfarra de vitória (Suno, 30 s; variação B guardada) — aguardando avaliação'],
    ['A-024', 'assets/audio/music/bgm_title_b.mp3', 'Música', 'F2', DONE, 'Tema de título (Suno, 90 s) — aprovada a variação B (A guardada)'],
  ], [9, 30, 14, 9, 15, 23]),
);

// 12. Riscos
children.push(
  H1('12. Riscos'),
  table(['Risco', 'Prob.', 'Impacto', 'Mitigação'], [
    ['Escopo grande demais', 'Alta', 'Alto', 'Vertical slice cedo; revisar metas de conteúdo após Fase 3; cortar opcionais antes do núcleo'],
    ['Inconsistência na arte gerada', 'Alta', 'Alto', 'Guia de estilo, prompt-base, referências fixas, pós-processamento'],
    ['Animação de sprites', 'Média', 'Alto', 'Poucos frames + tweens; ou animação por partes'],
    ['Termos de uso do áudio por IA', 'Baixa', 'Alto', 'Conta paga com direito comercial (confirmado); manter a assinatura ativa ao gerar e guardar prompts e IDs das tarefas'],
    ['Perda de trabalho', 'Baixa', 'Alto', 'Git + backup remoto desde a Fase 0'],
    ['Combate pouco divertido', 'Média', 'Alto', 'Protótipo e playtest na Fase 1 antes de produzir conteúdo'],
    ['Mudanças da engine', 'Baixa', 'Médio', 'Fixar Godot 4.7.2 durante todo o projeto'],
  ], [26, 10, 11, 53]),
);

// 13. Decisões
children.push(
  H1('13. Registro de decisões'),
  table(['ID', 'Decisão', 'Opções', 'Escolha', 'Data'], [
    ['D-01', 'Título, premissa e tom', '—', 'O Coração de Éter (título provisório). Tom: mistura equilibrada. Mundo: fantasia clássica + steampunk', today],
    ['D-02', 'Estilo visual', 'Pixel art 16-bit / HD-2D / 2D ilustrado', 'Pixel art 16-bit', today],
    ['D-03', 'Modelo de combate', 'CTB (FFX) / ATB (FF7, CT) / Híbrido', 'Híbrido: CTB + timing', today],
    ['D-04', 'Arena de batalha', 'No próprio mapa (CT) / arena separada (FF)', 'No próprio mapa', today],
    ['D-05', 'Progressão', 'Tabuleiro / Gemas / Híbrido', 'Híbrido: níveis + árvore + gemas', today],
    ['D-06', 'Viagem no tempo', 'Sim / Não / Parcial', 'Não', today],
    ['D-07', 'Resolução base', '640×360 / 1280×720 / 1920×1080', '640×360 (escala inteira)', today],
    ['D-08', 'Fonte de áudio', 'Livre / pago / compositor / IA', 'IA: Suno via MCP da AceDataCloud; conta paga com direito comercial sobre as músicas', today],
    ['D-09', 'Integração com o Codex', 'MCP / CLI direto', 'Os dois funcionam: CLI (tools/gen_image.ps1) e a nova ponte MCP (adapter.cjs → Codex App Server)', today],
  ], [9, 22, 38, 19, 12]),
);

// 14. Histórico
children.push(
  H1('14. Histórico de versões'),
  table(['Versão', 'Data', 'Alterações'], [
    ['0.1', created, 'Criação do documento: visão, sistemas, arquitetura, pipeline de arte, fases 0–6, riscos e decisões pendentes.'],
    ['0.2', today, 'Decisões D-01 a D-09 registradas (premissa: O Coração de Éter); projeto Godot, Git/GitHub e teste de imagem concluídos; seções de combate, progressão, arte e áudio atualizadas.'],
    ['0.3', today, 'Bíblia da história v0.1 criada (docs/Historia_O_Coracao_de_Eter.docx); sumário estático (compatível com LibreOffice); tabelas e títulos não se separam mais entre páginas.'],
    ['0.4', today, 'História aprovada (bíblia v0.2): morte simulada de Gerd, triângulo Kael–Lyra–Isolde; sistema de afinidade e matriz de finais adicionados.'],
    ['0.5', today, 'Guia de Estilo v0.1 (paleta Velmora 32, tamanhos, prompt-base, pipeline); referência oficial do Kael; ferramenta pixelize.mjs.'],
    ['0.6', today, 'Guia de Estilo aprovado (v1.0); GDD do combate híbrido v0.1 criado (docs/GDD_Combate.docx).'],
    ['0.7', today, 'GDD do combate aprovado (v1.0); input map com 12 ações (teclado + gamepad); GUT 9.7.1 instalado com testes rodando.'],
    ['0.8', today, 'Referências oficiais do Eco e da Lyra (3 personagens no total); ponte MCP do Codex testada; Suno MCP conectado e token validado.'],
    ['0.9', today, 'Licença do áudio confirmada (conta paga); primeira música de teste (Vila Caldeira, 2 variações); TurnQueue e DamageFormula implementados com 25 testes novos.'],
    ['1.0', today, 'Fase 0 concluída: tema de Vila Caldeira aprovado (versão A; B guardada como reserva). CLAUDE.md criado. Início da Fase 1: Kael andando no mapa de teste com colisão e câmera; ciclo de caminhada; pixelize.mjs aceita grades (41 testes).'],
    ['1.1', today, 'Conversa com NPC: Mestre Gerd no mapa de teste, retratos do Kael e do Gerd, caixa de diálogo com texto letra por letra, DialogueManager (autoload).'],
    ['1.2', today, 'Transições de cena: SceneManager (fade), portas, pontos de chegada, casa de teste, AudioManager, FieldMap (56 testes).'],
    ['1.3', today, 'Primeira batalha: inimigo no mapa, formação no próprio cenário, fila CTB, menu e alvo, timing de ataque e defesa, vitória/derrota; Brann e Slime de Óleo (76 testes).'],
    ['2.0', today, 'Fase 2 implementada em 4 blocos, aguardando aprovação do Diretor. A: GameState, níveis/XP, salvar. B: combate completo (status, itens, Barra de Éter, especiais, timing por personagem, IA por regras, troca, técnicas combinadas, fuga, iniciativa). C: equipamento, gemas, árvores. D: menu principal, loja, estalagem, diálogo com escolhas/afinidade, missões, cutscenes, opções, idioma, tela de título (155 testes).'],
  ], [12, 18, 70]),
  gap(),
  H2('Próximos passos'),
  N('Diretor: jogar e aprovar a Fase 2 (menu, loja, estalagem, missão do Gerd, Lyra, batalhas com a Sentinela).', 'next'),
  N('Fase 3 (vertical slice): roteiro do prólogo, tilesets reais pelo Codex, Ferro-Velho do Sul, primeiro chefe.', 'next'),
);

// ---------- document ----------
const numCfg = ref => ({ reference: ref, levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 360 } } } }] });

children.splice(tocIndex, 0, ...tocEntries.map(t => new Paragraph({ children: [new TextRun({ text: t, size: 24 })], spacing: { after: 140 } })));

const doc = new Document({
  creator: 'Claude',
  title: 'Projeto RPG — Planejamento e Controle de Fases',
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 34, bold: true, color: ACCENT, font: 'Georgia' },
        paragraph: { spacing: { before: 240, after: 200 }, outlineLevel: 0, border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: GOLD, space: 4 } } } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, color: ACCENT }, paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1, keepNext: true, keepLines: true } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 22, bold: true, color: '444444' }, paragraph: { spacing: { before: 160, after: 80 }, outlineLevel: 2, keepNext: true, keepLines: true } },
    ],
  },
  numbering: {
    config: [
      { reference: 'bullets', levels: [
        { level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 300 } } } },
        { level: 1, format: LevelFormat.BULLET, text: '◦', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1000, hanging: 300 } } } },
      ] },
      numCfg('num'), numCfg('pilares'), numCfg('pipe'), numCfg('next'),
    ],
  },
  features: { updateFields: true },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: 'Projeto RPG — Planejamento e Controle', size: 16, color: '888888' })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: ['Página ', PageNumber.CURRENT, ' de ', PageNumber.TOTAL_PAGES], size: 16, color: '888888' })] })] }) },
    children,
  }],
});

Packer.toBuffer(doc).then(buf => { fs.writeFileSync(OUT, buf); console.log('written', OUT, buf.length); });
