// Builds docs/GDD_Combate.docx — combat system design document.
// Usage: node build_combat.js <output.docx>
const { createDoc } = require('./lib');

const d = createDoc();
const { children: c, P, H1, H2, H3, B, N, Code, gap, table } = d;

d.cover({
  title: 'O CORAÇÃO DE ÉTER',
  subtitle: 'GDD — Sistema de Combate',
  tagline: 'Turnos CTB + comandos com timing · batalha no próprio mapa',
  info: [
    ['Versão', '0.1 — proposta para aprovação'],
    ['Data', '24/09/2026'],
    ['Decisões de base', 'D-03 híbrido (CTB + timing) · D-04 no próprio mapa · D-05 níveis + árvore + gemas'],
    ['Status dos números', 'Valores iniciais; ajustados na Fase 5 (balanceamento)'],
  ],
});

// ---------- 1 ----------
c.push(
  H1('1. Visão geral'),
  P('O combate une a **estratégia da fila de turnos do FFX** (CTB: o jogo pausa na escolha e mostra quem age a seguir) com a **participação ativa do Sea of Stars / Super Mario RPG** (apertar o botão no momento certo durante golpes e defesas) e a **fluidez do Chrono Trigger** (a luta acontece onde o encontro começou, sem troca de tela).'),
  H2('1.1 Pilares do combate'),
  B('**Cada turno é uma decisão:** a fila mostra as consequências de cada ação antes de confirmá-la.'),
  B('**Habilidade recompensa, nunca pune:** acertar o timing melhora o resultado; errar dá o resultado normal.'),
  B('**Identidade por personagem:** cada herói tem um tipo de timing e um papel próprio.'),
  B('**Ritmo ágil:** animações curtas, opção de acelerar a batalha, entrada e saída sem carregamento.'),
);

// ---------- 2 ----------
c.push(
  H1('2. Fluxo da batalha'),
  H2('2.1 Início: encontro no mapa'),
  B('Inimigos são visíveis e patrulham o mapa. O contato com o jogador inicia a batalha no mesmo lugar.'),
  B('**Iniciativa:** se o jogador tocar o inimigo pelas costas (ou com um golpe de campo), o grupo age primeiro.'),
  B('**Emboscada:** se o inimigo tocar o jogador pelas costas, os inimigos agem primeiro.'),
  B('Alguns inimigos são evitáveis; chefes e encontros de história são fixos.'),
  H2('2.2 Posicionamento'),
  B('Cada área de combate do mapa tem **pontos de batalha** (marcadores no Godot) para 3 heróis e até 6 inimigos.'),
  B('Sem marcadores próximos, uma formação automática é montada a partir do ponto de contato.'),
  B('Os personagens não se movem livremente: avançam para atacar e voltam ao seu ponto (estilo Chrono Trigger).'),
  B('As posições importam para técnicas de área (linha, círculo, cone).'),
  H2('2.3 Ciclo de turno'),
  N('A fila (CTB) indica quem age.'),
  N('Herói: o jogador escolhe comando e alvo; a fila mostra onde o herói vai parar após a ação. Inimigo: a IA escolhe.'),
  N('A ação é executada com animação; aparecem os prompts de timing (ataque do herói ou defesa contra inimigo).'),
  N('Dano, cura e status são aplicados; a Barra de Éter é atualizada.'),
  N('Fim de batalha? Se não, volta ao passo 1.'),
  H2('2.4 Fim da batalha'),
  table(['Resultado', 'O que acontece'], [
    ['Vitória', 'XP, Pontos de Éter (PE) para gemas, moedas e itens. Os inimigos somem do mapa (voltam ao sair da área).'],
    ['Fuga', 'Comando Fugir: chance = 50% + (VEL média do grupo − VEL média dos inimigos)%, entre 10% e 95%. Falhar gasta o turno (peso 2). Impossível contra chefes.'],
    ['Derrota', 'Tela de derrota com opções "Tentar de novo" (reinicia a batalha) e "Carregar jogo".'],
  ], [18, 82]),
);

// ---------- 3 ----------
c.push(
  H1('3. Fila de turnos (CTB)'),
  P('Cada combatente tem um **contador**. Age quem tem o menor contador; o tempo "passa" subtraindo esse valor de todos. Depois de agir, o contador recebe o atraso da ação escolhida.'),
  H2('3.1 Fórmulas'),
  Code('tique_base(VEL) = floor(3000 / (VEL + 20))'),
  Code('atraso(ação)    = tique_base × peso_da_ação × modificadores'),
  Code('contador_inicial = tique_base × 3 × aleatório(0,9 a 1,1)   (Iniciativa: 0 para o grupo)'),
  gap(),
  table(['VEL', 'Tique base', 'Atraso de ação normal (peso 3)'], [
    ['10 (inimigo lento)', '100', '300'],
    ['15 (Brann)', '85', '255'],
    ['25 (Kael)', '66', '198'],
    ['40 (Mira)', '50', '150'],
    ['80 (fim de jogo)', '30', '90'],
  ], [34, 22, 44]),
  gap(),
  H2('3.2 Peso das ações'),
  table(['Peso', 'Ações'], [
    ['2 (rápida)', 'Defender, usar item, fuga que falhou'],
    ['3 (normal)', 'Atacar, maioria das técnicas e magias, golpe especial'],
    ['4 (pesada)', 'Magias fortes, técnicas de área'],
    ['5–6 (muito pesada)', 'Magias supremas, algumas técnicas combinadas'],
  ], [25, 75]),
  gap(),
  H2('3.3 Regras'),
  B('**Prévia:** ao escolher uma ação, a fila mostra um "fantasma" do herói na posição em que vai cair.'),
  B('**Pressa** divide o tique base por 2; **Lentidão** multiplica por 2; **Parar** congela o contador.'),
  B('**Atrasar:** algumas técnicas empurram o contador do alvo (ex.: +50% do tique base dele).'),
  B('**Trocar personagem:** o herói da reserva assume o lugar e o contador de quem saiu, e **age na hora** (estilo FFX). Uma troca por turno.'),
  B('**Empate:** age primeiro quem tem maior VEL; persistindo, o herói.'),
  B('A fila mostra os próximos **10 turnos** no canto da tela.'),
);

// ---------- 4 ----------
c.push(
  H1('4. Comandos com timing'),
  P('Durante a execução (nunca durante a escolha), um sinal visual e sonoro indica o momento de apertar o botão de ação.'),
  H2('4.1 Janelas e resultados'),
  table(['Resultado', 'Janela (60 fps)', 'Ataque do herói', 'Defesa contra inimigo'], [
    ['Perfeito', '±3 quadros (±50 ms)', 'dano ×1,3 + efeito extra do personagem', 'dano recebido ×0,5'],
    ['Bom', '±8 quadros (±133 ms)', 'dano ×1,1', 'dano recebido ×0,75'],
    ['Errou / não apertou', '—', 'dano normal (sem penalidade)', 'dano normal'],
  ], [18, 22, 32, 28]),
  gap(),
  B('**Sinal:** brilho na arma do herói (ataque) ou no próprio herói (defesa) + som curto.'),
  B('Apertar antes da janela "gasta" a tentativa (evita apertar sem parar).'),
  B('**Acessibilidade:** dificuldade do timing (fácil = janelas 2×, normal, difícil = janelas ½) e modo **automático** (sempre "Bom").'),
  H2('4.2 Timing de cada personagem'),
  table(['Personagem', 'Tipo', 'Como funciona', 'Perfeito dá'], [
    ['Kael', 'Sobrecarga', 'Apertar no pico do pistão da lâmina', 'golpe extra (50% do dano)'],
    ['Eco', 'Bloqueio perfeito', 'Apertar no impacto de um ataque ao grupo', 'protege o grupo inteiro (×0,5 para todos)'],
    ['Lyra', 'Canalização', 'Segurar e soltar quando o círculo fechar', 'magia +30% e custo de MP −25%'],
    ['Brann', 'Pressão de vapor', 'Segurar para carregar; soltar antes de estourar', 'dano ×1,6; estourar = ele fica Sobreaquecido'],
    ['Mira', 'Combo', 'Sequência de 3–5 botões mostrada na tela', '+1 golpe por botão certo'],
    ['Selene', 'Prece', 'Apertar no ritmo do sino (3 toques)', 'cura +30% e remove 1 status'],
    ['Isolde', 'Calibragem', 'Parar o ponteiro na zona verde', 'torreta com +1 turno de duração'],
  ], [14, 18, 38, 30]),
);

// ---------- 5 ----------
c.push(
  H1('5. Atributos e fórmulas'),
  H2('5.1 Atributos'),
  table(['Sigla', 'Atributo', 'Uso'], [
    ['HP', 'Vida', 'KO em 0'],
    ['MP', 'Mana', 'custo de magias e técnicas'],
    ['FOR', 'Força', 'dano físico'],
    ['MAG', 'Magia', 'dano mágico e cura'],
    ['DEF', 'Defesa', 'reduz dano físico'],
    ['ESP', 'Espírito', 'reduz dano mágico, resistência a status'],
    ['VEL', 'Velocidade', 'frequência de turnos (CTB)'],
    ['SOR', 'Sorte', 'crítico, roubo, drops'],
    ['PRE / EVA', 'Precisão / Evasão', 'acerto físico'],
  ], [14, 26, 60]),
  gap(),
  H2('5.2 Dano físico'),
  Code('ATQ   = FOR + poder_da_arma'),
  Code('dano  = ATQ × mult_técnica × 100 / (100 + DEF_alvo)'),
  Code('        × variação(0,95–1,05) × crítico × elemento × timing × defesa_do_alvo'),
  H2('5.3 Dano mágico e cura'),
  Code('dano  = (MAG × 2 + poder_magia) × mult × 100 / (100 + ESP_alvo)'),
  Code('        × variação × elemento × timing × fator_Éter_regional'),
  Code('cura  = (MAG × 1,5 + poder_cura) × variação × timing × fator_Éter_regional'),
  H2('5.4 Acerto, crítico e limites'),
  Code('acerto%  = limitar(95 + (PRE − EVA_alvo) / 2, 5, 100)     (magia sempre acerta)'),
  Code('crítico% = 3 + SOR / 8      →  dano ×1,5'),
  Code('dano máximo = 9999          (quebrável por gema especial no fim do jogo)'),
  H2('5.5 Elementos'),
  P('Oito elementos: Fogo, Gelo, Raio, Água, Terra, Vento, Luz e Sombra. Mais o tipo **Mecânico** (inimigos de metal).', undefined, true),
  table(['Afinidade', 'Multiplicador'], [
    ['Fraco', '×1,5'], ['Normal', '×1,0'], ['Resiste', '×0,5'], ['Imune', '×0'], ['Absorve', 'cura em vez de ferir'],
  ], [50, 50]),
  gap(),
  H2('5.6 Fator Éter regional'),
  P('Liga o combate à história: onde o Império drenou o Éter, a magia enfraquece para todos (heróis e inimigos).', undefined, true),
  table(['Região', 'Fator', 'Exemplo'], [
    ['Drenada', '×0,7', 'arredores da Refinaria de Cinzamar'],
    ['Normal', '×1,0', 'maioria das regiões'],
    ['Intacta', '×1,2', 'coração de Sylvaran, Aethel'],
  ], [25, 15, 60]),
  gap(),
  H2('5.7 Exemplo de cálculo (nível 1)'),
  P('Kael (FOR 12, arma 10) ataca um Slime de Óleo (DEF 5):', undefined, true),
  Code('22 × 1,0 × 100/105 ≈ 21 de dano   →  com Perfeito: 21 × 1,3 ≈ 27 + golpe extra de 13'),
  P('Lyra (MAG 15) lança Fogo (poder 20) no mesmo Slime (ESP 5, fraco a Fogo), região normal:', undefined, true),
  Code('(30 + 20) × 1,0 × 100/105 × 1,5 ≈ 71 de dano'),
);

// ---------- 6 ----------
c.push(
  H1('6. Status'),
  P('A duração conta em turnos **do afetado** (natural para a fila CTB). Status negativos têm chance de falhar conforme o ESP do alvo.', undefined, true),
  table(['Status', 'Efeito', 'Duração'], [
    ['Veneno', 'perde 6% do HP máx. a cada turno', '5 turnos'],
    ['Sono', 'não age; acorda ao receber dano físico', '3 turnos'],
    ['Silêncio', 'não usa magias', '4 turnos'],
    ['Cegueira', 'acerto físico −50%', '4 turnos'],
    ['Paralisia', 'perde o próximo turno', '1 turno'],
    ['Confusão', 'age contra alvo aleatório; 50% de sair ao receber dano', '3 turnos'],
    ['Petrificação', 'contagem de 3 turnos; ao zerar, fica fora da batalha', 'até curar'],
    ['Sobreaquecido', 'próximo golpe ×1,5, mas recebe +25% de dano (vapor)', '2 turnos'],
    ['Desmontado', 'inimigo mecânico perde uma peça (DEF ou uma habilidade) — Ressonância do Kael', 'batalha'],
    ['Pressa', 'tique base ÷2', '5 turnos'],
    ['Lentidão', 'tique base ×2', '5 turnos'],
    ['Proteção', 'dano físico recebido ×0,67', '5 turnos'],
    ['Barreira', 'dano mágico recebido ×0,67', '5 turnos'],
    ['Regeneração', 'recupera 6% do HP máx. a cada turno', '5 turnos'],
  ], [20, 60, 20]),
);

// ---------- 7 ----------
c.push(
  H1('7. Barra de Éter e golpes especiais'),
  B('Cada herói tem uma **Barra de Éter** de 0 a 100 (equivalente ao Limit Break / Overdrive).'),
  B('Enche com: dano recebido (60% do percentual de HP perdido), +6 por Perfeito, +3 por Bom, +10 quando um aliado cai.'),
  B('Cheia: o comando **Especial** fica disponível (peso 3). A barra zera após o uso e persiste entre batalhas.'),
  B('Golpes especiais também têm timing próprio (ex.: Engrenagem Final do Kael: sequência de 4 Perfeitos = versão máxima).'),
  H2('Técnicas combinadas (Dual / Triple)'),
  B('Todos os participantes precisam estar no grupo ativo, sem KO, sem Sono/Paralisia/Silêncio, e pagar seu custo de MP.'),
  B('A técnica sai no turno do primeiro participante; os outros **também gastam o turno** (contador recebe o atraso da técnica).'),
  B('Cada participante tem seu prompt de timing em sequência.'),
  B('São liberadas pelas árvores de habilidade e por momentos da história.'),
);

// ---------- 8 ----------
c.push(
  H1('8. Progressão em combate'),
  H2('8.1 Níveis e árvore'),
  B('XP sobe o nível (atributos base) e dá **Pontos de Habilidade** para a árvore do personagem (técnicas, passivas, timings melhores).'),
  B('Curva de XP e atributos por nível ficam na planilha de balanceamento (Fase 5).'),
  H2('8.2 Gemas'),
  table(['Tipo', 'O que faz', 'Exemplo'], [
    ['Magia', 'dá magias de um elemento; novas magias a cada nível da gema', 'Gema de Fogo: Fogo → Fogo+ → Inferno'],
    ['Suporte', 'modifica o ataque ou outra gema', 'Lâmina Elemental: ataque ganha o elemento da gema vizinha'],
    ['Comando', 'adiciona um comando ao menu', 'Roubar, Analisar'],
    ['Atributo', 'aumenta atributos', '+10% HP, +VEL'],
    ['Timing', 'altera janelas de timing', 'Olho de Relojoeiro: janela Perfeito +50%'],
  ], [16, 44, 40]),
  gap(),
  B('Gemas ficam em encaixes da arma e da armadura; algumas armas têm **encaixes ligados** (Suporte afeta a gema ao lado).'),
  B('Gemas sobem de nível com **Pontos de Éter (PE)** ganhos em batalha.'),
  H2('8.3 Recompensas'),
  table(['Situação', 'XP e PE'], [
    ['Grupo ativo', '100%'],
    ['Reserva', '75%'],
    ['Nocauteado no fim', '50%'],
  ], [50, 50]),
);

// ---------- 9 ----------
c.push(
  H1('9. Inimigos e IA'),
  B('A IA é uma **lista de regras** por inimigo: condição → ação → alvo, com peso de probabilidade. A primeira regra válida de maior prioridade vence; empates sorteiam pelo peso.'),
  B('Condições: HP próprio abaixo de X%, aliado caído, alvo com status, turno N, fase do chefe.'),
  B('Alvos: aleatório, menor HP, maior ameaça (quem causou mais dano), quem tem status, curandeiro.'),
  B('**Chefes** têm fases por HP (ex.: 100–60%, 60–25%, 25–0%), com mudanças de padrão, falas e pontos fracos.'),
  B('Todo chefe deve ter um **sinal** antes de um golpe forte (ex.: "O General Voss acumula vapor…"), dando chance de reagir.'),
  H2('Exemplo de IA — Slime de Óleo'),
  table(['Prioridade', 'Condição', 'Ação', 'Alvo', 'Peso'], [
    ['1', 'HP < 30%', 'Fugir', '—', '50'],
    ['2', 'sempre', 'Investida', 'aleatório', '70'],
    ['2', 'sempre', 'Jato de óleo (Lentidão)', 'maior VEL', '30'],
  ], [14, 20, 30, 20, 16]),
);

// ---------- 10 ----------
c.push(
  H1('10. Arquitetura técnica (Godot)'),
  table(['Arquivo / classe', 'Responsabilidade'], [
    ['scripts/battle/battle_manager.gd', 'máquina de estados da batalha: início → turno → comando → execução → resolução → fim'],
    ['scripts/battle/turn_queue.gd (TurnQueue)', 'contadores CTB, próximo a agir, prévia da fila para uma ação'],
    ['scripts/battle/damage_formula.gd (DamageFormula)', 'fórmulas puras (dano, cura, acerto, crítico) — testadas automaticamente'],
    ['scripts/battle/timing_controller.gd', 'janelas de timing, leitura do botão, resultado PERFEITO/BOM/ERROU'],
    ['scripts/battle/enemy_ai.gd', 'avaliação da lista de regras'],
    ['scripts/battle/battle_area.gd', 'pontos de batalha no mapa e formação automática'],
    ['scenes/battle/battle_ui.tscn', 'fila de turnos, menu de comandos, cursor de alvo, números de dano'],
    ['data/skills/*.tres (SkillData)', 'id, nome, peso, custo, poder, multiplicador, elemento, tipo (físico/mágico), forma do alvo, tipo de timing, status'],
    ['data/characters, data/enemies (CombatantData)', 'atributos, afinidades, IA, recompensas'],
  ], [40, 60]),
  gap(),
  P('Sinais principais: turn_started(combatente), action_chosen(ação), timing_resolved(resultado), damage_applied(alvo, valor), battle_ended(resultado).'),
  P('As fórmulas ficam isoladas em DamageFormula e TurnQueue para serem testadas sem abrir uma batalha.'),
);

// ---------- 11 ----------
c.push(
  H1('11. Parâmetros de balanceamento'),
  P('Todos centralizados em um arquivo de configuração (data/balance/combat.tres) para ajuste sem mexer no código.', undefined, true),
  table(['Parâmetro', 'Valor inicial'], [
    ['Constante do tique base', '3000 / (VEL + 20)'],
    ['Peso normal / rápido / pesado', '3 / 2 / 4'],
    ['Multiplicador Perfeito / Bom (ataque)', '×1,3 / ×1,1'],
    ['Multiplicador Perfeito / Bom (defesa)', '×0,5 / ×0,75'],
    ['Janela Perfeito / Bom', '±3 / ±8 quadros'],
    ['Crítico', '3% + SOR/8, ×1,5'],
    ['Variação de dano', '0,95–1,05'],
    ['Fraqueza / resistência', '×1,5 / ×0,5'],
    ['Fator Éter drenada / intacta', '×0,7 / ×1,2'],
    ['Barra de Éter: Perfeito / Bom / aliado caído', '+6 / +3 / +10'],
    ['XP reserva / nocauteado', '75% / 50%'],
    ['Dano máximo', '9999'],
  ], [55, 45]),
);

// ---------- 12 ----------
c.push(
  H1('12. Escopo do protótipo (Fase 1)'),
  P('O mínimo para validar a sensação do combate antes de produzir conteúdo:', undefined, true),
  B('3 heróis (Kael, Lyra, Brann com arte provisória) contra 2 inimigos, no próprio mapa.'),
  B('Fila CTB com prévia; comandos Atacar e Defender; uma magia (Fogo).'),
  B('Timing de ataque (Perfeito/Bom) e de defesa.'),
  B('Vitória, derrota e volta ao mapa.'),
  B('Testes automáticos de DamageFormula e TurnQueue.'),
);

// ---------- 13 ----------
c.push(
  H1('13. Pontos para aprovação'),
  table(['#', 'Pergunta', 'Proposta'], [
    ['C-01', 'Trocar personagem gasta turno?', 'Não: quem entra age na hora (estilo FFX), uma troca por turno'],
    ['C-02', 'Errar o timing tem penalidade?', 'Não: resultado normal'],
    ['C-03', 'Reservas ganham XP?', 'Sim, 75%'],
    ['C-04', 'Nome da barra de golpe especial', '"Barra de Éter"'],
    ['C-05', 'Defesa Perfeita gera contra-ataque?', 'Só com gema ou habilidade específica'],
    ['C-06', 'Derrota', '"Tentar de novo" (reinicia a batalha) ou carregar jogo'],
  ], [10, 40, 50]),
);

d.write(process.argv[2], { title: 'O Coração de Éter — GDD Combate', header: 'O Coração de Éter — GDD Combate' });
