// Roteiro do Prólogo (vertical slice, Fase 3). Usage: node build_prologue.js <out.docx>
const { createDoc } = require('./lib');

const out = process.argv[2] || 'Roteiro_Prologo.docx';
const today = new Date().toISOString().slice(0, 10);
const d = createDoc();
const { children, P, H1, H2, H3, B, N, gap, table, cover } = d;

// Dialogue line: speaker + text (in-game Portuguese).
const L = (who, text) => P(`**${who}:** ${text}`);
const stage = text => P(text, { italics: true, color: '666666' });

cover({
  title: 'O Coração de Éter',
  subtitle: 'Roteiro do Prólogo — "A Máquina que Sabia meu Nome"',
  tagline: 'Vertical slice (Fase 3): 30–60 minutos jogáveis',
  info: [
    ['Documento', 'Roteiro jogável do prólogo: cenas, diálogos, mapas, encontros, tutoriais, assets'],
    ['Versão', '0.1 — rascunho para aprovação do Diretor'],
    ['Data', today],
    ['Base', 'Bíblia da história v0.2 (prólogo), GDD do Combate v1.0, Guia de Estilo v1.0'],
    ['Status', 'Aguardando aprovação — ver capítulo 9 (decisões pendentes)'],
  ],
});

// ---------- 1 ----------
children.push(
  H1('1. Visão geral'),
  P('O prólogo apresenta Vila Caldeira, o mestre Gerd, o dom de Kael (ouvir as máquinas) e Eco. O tom é leve e cheio de humor até a chegada do Império; os últimos cinco minutos dão o primeiro impacto da história: a "morte" de Gerd.'),
  table(['Item', 'Definição'], [
    ['Duração alvo', '35–50 min no primeiro jogo (≈ 60 min explorando tudo)'],
    ['Grupo', 'Kael (sempre) · Gerd (convidado, cenas 3–7) · Eco (a partir da cena 5)'],
    ['Mapas', 'Vila Caldeira (exterior), Oficina Brunor (interior), Loja/Estalagem (interiores), Estrada do Sul, Ferro-Velho do Sul (3 áreas + câmara)'],
    ['Inimigos', '6 comuns + 1 chefe (Triturador) + 1 luta roteirizada (General Voss)'],
    ['Missões secundárias', '2 (O Gato da Dona Berta · Peças para o Relojoeiro)'],
    ['Músicas', 'Vila Caldeira ✓, Batalha A/B ✓, Vitória ✓, Título ✓ + novas: Ferro-Velho, Chefe, Tema do Império, Adeus (cena final)'],
    ['Fim', 'Kael e Eco fogem pela estrada norte; tela "Fim do Prólogo" e salvamento'],
  ], [25, 75]),
  gap(),
  H2('1.1 Fluxo'),
  table(['#', 'Cena', 'Local', 'O que o jogador faz', 'Min.'], [
    ['1', 'Manhã de oficina', 'Oficina Brunor', 'Movimento, interação, conversa; recebe a primeira tarefa', '3'],
    ['2', 'A vila', 'Vila Caldeira', 'Explora, conhece NPCs, loja, estalagem, missões opcionais', '8–12'],
    ['3', 'O pedido de Gerd', 'Oficina → Estrada do Sul', 'Gerd entra como convidado; primeira batalha (tutorial)', '4'],
    ['4', 'Ferro-Velho do Sul', 'Áreas 1–3', 'Dungeon curta: timing, técnicas, baús, alavanca da esteira, ponto de salvamento', '10–15'],
    ['5', 'A máquina que sabia meu nome', 'Câmara funda', 'Cutscene: Kael ouve a voz; Eco desperta e entra no grupo', '3'],
    ['6', 'O Triturador', 'Câmara funda', 'Chefe: Ressonância (desmontar partes) e defesa com timing', '5–8'],
    ['7', 'Jantar na oficina', 'Oficina Brunor (noite)', 'Cena calma; escolha de diálogo; salvar', '3'],
    ['8', 'O Império chega', 'Vila Caldeira (manhã)', 'Dirigível, soldados, luta contra Voss (derrota roteirizada)', '5'],
    ['9', 'Corre, garoto', 'Oficina → Portão Norte', 'Gerd segura os soldados; explosão; fuga; fim do prólogo', '3'],
  ], [5, 22, 20, 45, 8]),
);

// ---------- 2 ----------
children.push(
  H1('2. Mapas'),
  H2('2.1 Vila Caldeira (exterior, ~60×40 tiles)'),
  B('Cidade-oficina na fronteira do Império: casas de tijolo e enxaimel, telhados de ardósia e cobre, canos de latão correndo pelas paredes, chaminés soltando vapor, um canal estreito cortando a praça.'),
  B('**Praça central:** poço, bancos, placa de avisos (cartaz imperial "Éter para todos!"), lampiões de Éter.'),
  B('**Pontos:** Oficina Brunor (leste), Loja do Tobias, Estalagem da Dona Berta, Relojoaria do Sr. Anselmo, Portão Sul (para o Ferro-Velho), Portão Norte (fechado até a cena 9).'),
  B('**Ambiente:** gatos, fumaça de chaminé animada, um relógio de torre que marca a hora (enfeite).'),
  H2('2.2 Interiores'),
  B('**Oficina Brunor:** bancada, fornalha, peças penduradas, cama de Kael no mezanino, mesa de jantar; porta dos fundos (usada na cena 9).'),
  B('**Loja do Tobias:** balcão, prateleiras de poções e peças. **Estalagem:** balcão, 3 mesas, escada (enfeite). **Relojoaria:** relógios nas paredes (tique-taque como SFX).'),
  H2('2.3 Estrada do Sul (~40×20)'),
  B('Estrada de terra com trilhos abandonados; primeiro encontro fixo (tutorial). Um baú escondido atrás de uma carroça quebrada.'),
  H2('2.4 Ferro-Velho do Sul'),
  table(['Área', 'Descrição', 'Destaques'], [
    ['1. Pátio de Sucata', 'Montanhas de sucata, guindaste parado, poças de óleo', 'Encontros visíveis; baú com Poção ×2'],
    ['2. Esteira Quebrada', 'Galpão com esteira transportadora e prensas', 'Puzzle: a alavanca liga a esteira e move um bloco de sucata que abre a passagem; ponto de salvamento (caldeira que Kael "escuta")'],
    ['3. Poço das Engrenagens', 'Descida em espiral por um poço de engrenagens gigantes', 'Engrenagens giram como plataformas (enfeite animado); baú com Gema de Fogo'],
    ['Câmara funda', 'Sala de pedra clara com circuitos dourados apagados — ruína aetheliana sob o ferro-velho', 'Eco dorme coberto de musgo; arena do chefe'],
  ], [20, 40, 40]),
  gap(),
  P('Os encontros são visíveis no mapa (sem batalhas aleatórias). Tocar pelas costas dá iniciativa; ser tocado pelas costas é emboscada (sistemas da Fase 2).'),
);

// ---------- 3 ----------
children.push(H1('3. Roteiro cena a cena'));

children.push(
  H2('Cena 1 — Manhã de oficina'),
  stage('Tela preta. Som de martelo. Fade-in: interior da Oficina Brunor, manhã. Kael dorme debruçado na bancada, com uma válvula na mão.'),
  L('Gerd', 'Kael! Se você ficar mais um minuto roncando em cima dessa válvula, ela vai aprender a roncar também.'),
  L('Kael', 'Hm... eu não tava dormindo. Tava... escutando.'),
  L('Gerd', 'Escutando. Claro. E o que ela disse?'),
  L('Kael', 'Que a rosca tá espanada e que o senhor apertou com força demais.'),
  L('Gerd', '...Hmpf. Vai lavar a cara. Tenho uma entrega pra você.'),
  stage('Controle livre. Dicas na tela: mover (setas / analógico), interagir (Z / A). Três objetos na oficina têm falas de Kael ao interagir (fornalha, relógio quebrado, foto antiga de Gerd de uniforme imperial — "Nunca vi o velho sorrir assim.").'),
  L('Gerd', 'Leva essa caixa de engrenagens pro Tobias, na loja. E não aceita menos de 80 moedas, ouviu? Aquele pão-duro vai chorar miséria.'),
  stage('Recebe o item-chave "Caixa de Engrenagens". Objetivo no diário: "Entregar a caixa ao Tobias".'),

  H2('Cena 2 — A vila'),
  stage('Música: Vila Caldeira. O jogador explora livremente. A entrega é o único objetivo obrigatório.'),
  H3('Tobias (loja)'),
  L('Tobias', 'Ah, a encomenda do Gerd! Sessenta moedas, e isso é um favor que eu faço.'),
  L('Kael', 'Ele disse que o senhor ia chorar miséria.'),
  L('Tobias', '...Oitenta. Mas diz pra ele que eu não chorei.'),
  stage('Recebe 80 moedas. A loja abre (tutorial de compra: "Compre poções antes de sair da vila").'),
  H3('Falas de ambiente (uma por NPC, mudam depois da cena 7)'),
  B('**Dona Berta (estalagem):** "O Éter subiu de novo. Daqui a pouco uma lamparina vai custar mais que um jantar."'),
  B('**Pip (menino na praça):** "Você viu o dirigível ontem à noite? Era ENORME! Tinha uma bandeira azul com uma engrenagem!"'),
  B('**Guarda Olavo:** "Ordem da capital: ninguém entra no Ferro-Velho sem autorização. ...Mas eu almoço ao meio-dia, se é que me entende."'),
  B('**Velha Ilse (junto ao canal):** "Minha avó dizia que o canal brilhava à noite. Hoje só brilha quando derramam Éter nele."'),
  B('**Cartaz imperial:** "ÉTER PARA TODOS! — A Grande Bomba de Cinzamar trará luz a cada lar de Velmora."'),
  H3('Missões secundárias'),
  B('**O Gato da Dona Berta:** o gato Fuligem fugiu para o Ferro-Velho. Encontrá-lo na Área 2 (atrás das prensas) e trazê-lo de volta. Recompensa: Pena de Fênix + 1 ponto de afinidade com Gerd ("Você tem jeito com bicho arisco. Puxou a mim.").'),
  B('**Peças para o Relojoeiro:** o Sr. Anselmo precisa de 3 "Molas de Latão" (drop do Rato-Engrenagem). Recompensa: Amuleto de Engrenagem. Ao entregar: "Engraçado... meus relógios pararam todos às 3 da manhã, ontem. Todos ao mesmo tempo." (presságio: foi quando o dirigível passou).'),

  H2('Cena 3 — O pedido de Gerd'),
  stage('De volta à oficina com as moedas.'),
  L('Gerd', 'Oitenta? Hah! Aprendeu alguma coisa comigo, afinal.'),
  L('Gerd', 'Agora o serviço de verdade: a caldeira da estalagem precisa de uma válvula de bronze antiga. Só tem no Ferro-Velho do Sul.'),
  L('Kael', 'O Ferro-Velho? O guarda disse que é proibido.'),
  L('Gerd', 'O guarda também disse que a esposa dele cozinha bem. ...Eu vou junto. Minhas costas reclamam, mas este braço aqui ainda funciona.'),
  stage('Gerd bate no braço mecânico, que solta um chiado de vapor. Gerd entra no grupo como convidado (não aparece no menu Formação; não recebe equipamento).'),
  stage('Estrada do Sul: encontro fixo com dois Slimes de Óleo. Tutorial de batalha em 3 caixas curtas: (1) a fila de turnos no topo; (2) "Aperte Z / A quando o anel dourado fechar para um golpe Perfeito"; (3) "Na vez do inimigo, aperte no impacto para se defender".'),
  L('Gerd', 'Bom reflexo. Quando o anel fechar, é aí que a máquina quer que você bata. Escuta ela.'),

  H2('Cena 4 — Ferro-Velho do Sul'),
  stage('Música: Ferro-Velho (nova). Encontros visíveis. Gerd comenta cada tipo de inimigo na primeira vez (uma linha).'),
  B('**Rato-Engrenagem:** "Ratos comendo cobre. Até a praga daqui é mecânica."'),
  B('**Corvo de Sucata:** "Esses bichos roubam parafuso até do meu bolso. Acerta antes que ele fuja!"'),
  B('**Aranha-Parafuso:** "Cuidado com o veneno. Tem antídoto na bolsa?"'),
  stage('Área 2, ponto de salvamento (caldeira velha). Ao interagir pela primeira vez:'),
  L('Kael', '(Ela tá... cansada. Como se alguém tivesse esquecido de desligar ela há anos.)'),
  L('Gerd', 'Kael? Tá falando sozinho de novo?'),
  L('Kael', 'Tô falando com a caldeira. É diferente.'),
  stage('Puzzle da esteira: a alavanca liga a esteira; o bloco de sucata desliza e revela a descida. Técnica combinada liberada no primeiro combate da Área 3: "Faísca e Ferro" (Kael + Gerd), ensinada por Gerd.'),
  L('Gerd', 'Eu seguro, você corta. Igual na oficina, só que o parafuso morde de volta.'),

  H2('Cena 5 — A máquina que sabia meu nome'),
  stage('Fim do Poço das Engrenagens. Os circuitos dourados das paredes se acendem um a um quando Kael passa. A música para. Só um zumbido baixo.'),
  L('Kael', 'Mestre... o senhor tá ouvindo isso?'),
  L('Gerd', '(pausa) ...Ouvindo o quê, garoto?'),
  stage('No centro da câmara, uma figura de pedra clara e latão, coberta de musgo, sentada como se dormisse. Kael se aproxima. Um único olho azul se acende.'),
  L('???', '...Kael.'),
  L('Kael', 'Ele... ele sabe meu nome!'),
  L('Gerd', '(baixinho, para si) ...Então ainda funciona.'),
  L('Kael', 'O senhor disse alguma coisa?'),
  L('Gerd', 'Disse que isso aí deve valer uma fortuna. Vamos embora.'),
  L('???', 'Designação: E-C-O. Diretiva: ...dado corrompido. Kael: presente. Diretiva parcialmente cumprida.'),
  L('Kael', 'Eco. Tá bom, Eco. Você... vem com a gente?'),
  L('Eco', 'Afirmativo. Pergunta: o que é "a gente"?'),
  stage('Eco entra no grupo. O pulso de Éter do despertar reativa uma máquina enorme enterrada na sucata acima da câmara — o chão treme.'),

  H2('Cena 6 — O Triturador'),
  stage('Uma prensa de sucata gigante com duas garras cai na câmara. Música: Chefe (nova).'),
  L('Eco', 'Alerta. Máquina hostil. Nível de irritação: elevado.'),
  L('Kael', 'Ela tá com dor! Os braços tão travados... se eu soltar as garras, ela para!'),
  stage('Dica de tutorial: "Ressonância revela as partes de um inimigo mecânico. Destruir uma parte desativa os golpes dela." Detalhes da luta no capítulo 5.'),
  stage('Vitória:'),
  L('Kael', '(Ela tá... quieta agora. Obrigada, ela disse. Eu acho.)'),
  L('Eco', 'Observação: Kael conversa com máquinas desligadas. Registrando como comportamento normal.'),
  L('Gerd', 'Pega a válvula e vamos pra casa. Esse lugar me dá arrepio.'),

  H2('Cena 7 — Jantar na oficina'),
  stage('Noite. Mesa com sopa; Eco sentado na ponta, sem prato, observando. Música: Vila Caldeira (versão calma, ou a mesma faixa com volume baixo).'),
  L('Eco', 'Pergunta: por que humanos se sentam juntos para abastecer?'),
  L('Gerd', 'Porque comer sozinho é triste, lata velha.'),
  L('Eco', 'Registrando: "triste". Pedido de definição.'),
  stage('Escolha de diálogo (Kael):'),
  table(['Resposta', 'Efeito'], [
    ['"Triste é quando falta alguém na mesa."', 'Afinidade Eco +2. Gerd fica em silêncio e olha a foto antiga.'],
    ['"Triste é sopa sem sal. Né, mestre?"', 'Afinidade Gerd +1. Gerd ri pela primeira vez no jogo.'],
    ['"Eu te explico amanhã, Eco."', 'Nenhuma. Eco: "Amanhã. Registrado." (a frase pesa depois da cena 9)'],
  ], [45, 55]),
  gap(),
  L('Gerd', 'Kael... se um dia aparecer alguém perguntando por essa máquina, você não sabe de nada. Entendeu?'),
  L('Kael', 'Por quê? O senhor sabe o que ele é?'),
  L('Gerd', 'Sei que é tarde. Vai dormir.'),
  stage('Ponto de salvamento: a cama de Kael (descansar recupera tudo e salva). As falas dos NPCs mudam para a manhã seguinte.'),

  H2('Cena 8 — O Império chega'),
  stage('Manhã. Sombra enorme sobre a vila: um dirigível imperial. Música: Tema do Império (novo). Soldados na praça. Pip corre até Kael.'),
  L('Pip', 'Kael! Os soldados tão revirando as casas atrás de um "artefato"! O Guarda Olavo tentou impedir e levaram ele!'),
  stage('Na praça: o General Voss, em armadura a vapor, diante dos moradores.'),
  L('Voss', 'Uma máquina foi ativada no Ferro-Velho ontem. Os medidores de Brasaforte registraram o pulso daqui. Entreguem-na, e ninguém se machuca.'),
  L('Eco', 'Declaração: sou a máquina.'),
  L('Kael', 'Eco!'),
  L('Voss', '...Um aetheliano funcionando. Então o velho Brunor mentiu esse tempo todo. Peguem.'),
  stage('Batalha roteirizada contra Voss + 2 Soldados Imperiais (capítulo 5). Ao fim do 4º turno de Voss (ou se o grupo cair), a luta acaba sem tela de derrota.'),
  L('Voss', 'Coragem. Falta de juízo, mas coragem. Algemas.'),

  H2('Cena 9 — Corre, garoto'),
  stage('Explosão de vapor: Gerd arromba a praça com um carrinho de oficina em chamas, derrubando os soldados.'),
  L('Gerd', 'Pela oficina! Porta dos fundos! AGORA!'),
  stage('Controle curto: correr da praça até a oficina (soldados bloqueiam ruas; caminho único, sem batalhas). Dentro da oficina:'),
  L('Kael', 'O senhor vem com a gente!'),
  L('Gerd', 'Esses joelhos não correm mais, garoto. Mas esta oficina ainda sabe fazer barulho.'),
  L('Gerd', 'Vai pro norte. Pra floresta. E Kael...'),
  L('Gerd', '...escuta ele. Ele sabe mais do que parece. Eu devia ter te contado tudo antes.'),
  L('Eco', 'Gerd Brunor. Pergunta: você vem "amanhã"?'),
  L('Gerd', '(sorri) ...Cuida dele, lata velha.'),
  stage('Gerd abre todas as válvulas da fornalha. Kael e Eco saem pelos fundos. Soldados invadem a oficina pela frente. Corte para fora: a oficina explode numa coluna de vapor e fogo. Música: Adeus (nova).'),
  L('Kael', 'MESTRE!'),
  L('Eco', '...Registrando: "triste".'),
  stage('Portão Norte. Kael olha para trás uma vez. Fade para branco. Texto: "Fim do Prólogo — A Máquina que Sabia meu Nome". Salvar. (No jogo completo, segue o Ato 1: Floresta de Sylvaran.)'),
);

// ---------- 4 ----------
children.push(
  H1('4. Tutoriais'),
  P('Cada sistema é ensinado uma vez, na hora em que é usado, com uma caixa curta que pode ser desativada nas opções. Nada é explicado antes de ser necessário.'),
  table(['Sistema', 'Onde', 'Como'], [
    ['Movimento e interação', 'Cena 1', 'Dica na tela + três objetos com falas'],
    ['Loja e dinheiro', 'Cena 2', 'Entrega ao Tobias abre a loja'],
    ['Menu principal (itens, equipar, status)', 'Cena 2', 'Ao receber o Amuleto ou comprar a 1ª arma'],
    ['Fila de turnos (CTB) e timing de ataque/defesa', 'Cena 3', 'Batalha fixa na Estrada do Sul (3 caixas)'],
    ['Encontros visíveis, iniciativa e emboscada', 'Cena 4', 'Primeira área do Ferro-Velho'],
    ['Pontos de salvamento', 'Cena 4', 'Caldeira da Área 2'],
    ['Técnicas combinadas', 'Cena 4', 'Gerd ensina "Faísca e Ferro"'],
    ['Status (veneno)', 'Cena 4', 'Primeira Aranha-Parafuso'],
    ['Gemas e encaixes', 'Cena 4', 'Baú com Gema de Fogo'],
    ['Troca de personagens', 'Cena 5', 'Eco entra como 3º ativo; troca é mostrada quando alguém cai'],
    ['Ressonância e partes', 'Cena 6', 'Chefe Triturador'],
    ['Barra de Éter / golpe especial', 'Cena 6', 'Barra de Kael enche durante o chefe; dica quando fica cheia'],
    ['Escolhas de diálogo', 'Cena 7', 'Jantar'],
  ], [34, 14, 52]),
);

// ---------- 5 ----------
children.push(
  H1('5. Inimigos e encontros'),
  P('Valores são pontos de partida; o balanceamento final acontece com o trecho jogável (tarefa "Balanceamento do trecho"). Nível do grupo esperado: 1 na estrada, 3–4 no chefe.'),
  table(['Inimigo', 'Onde', 'Papel', 'Destaque', 'Asset'], [
    ['Slime de Óleo', 'Estrada, Área 1', 'Básico', 'Fraco a fogo', 'existe'],
    ['Rato-Engrenagem', 'Área 1–2', 'Rápido, fraco', 'Age 2× na fila; dropa Mola de Latão (missão)', 'novo'],
    ['Corvo de Sucata', 'Área 1–3', 'Ladrão', 'Rouba um item e foge se não for derrotado em 3 turnos', 'novo'],
    ['Aranha-Parafuso', 'Área 2–3', 'Status', 'Veneno; fraca a gelo', 'novo'],
    ['Sentinela de Latão', 'Área 3', 'Elite', 'Aviso de golpe forte (Canhão) — pede defesa com timing', 'existe'],
    ['Lâmpada Errante', 'Área 3', 'Mágico', 'Fantasminha de Éter vazado; usa magia de raio; imune a físico por 1 turno após brilhar', 'novo'],
    ['**Triturador**', 'Câmara funda', 'Chefe', 'Ver 5.1', 'novo (96–128 px)'],
    ['Soldado Imperial', 'Cena 8', 'Roteiro', 'Rifle a vapor; aparece no Ato 1 também', 'novo'],
    ['**General Voss**', 'Cena 8', 'Luta roteirizada', 'Ver 5.2', 'novo (sprite de mapa + batalha)'],
  ], [20, 14, 14, 40, 12]),
  gap(),
  H2('5.1 Chefe: Triturador'),
  B('Prensa de sucata com **3 partes**: Garra Esquerda, Garra Direita e Núcleo. O Núcleo só recebe dano cheio depois que uma garra cai.'),
  B('**Garra (cada):** "Esmagar" — golpe físico forte em um alvo, com aviso um turno antes ("A garra se ergue..."). Defesa perfeita reduz para ×0,5.'),
  B('**Núcleo:** "Vapor Escaldante" — dano a todos + chance de Queimadura; usado só quando as duas garras estão de pé ou quando uma cai (reação de raiva).'),
  B('**Ressonância (Kael):** revela as partes e o HP de cada uma; a Ressonância com Perfeito causa Atordoado na parte alvo por 1 turno.'),
  B('**Fase final (Núcleo < 30%):** "Compactar" — puxa um herói para dentro (Preso 2 turnos) — Eco pode usar Proteger para impedir. É onde o jogador descobre o papel de tanque de Eco.'),
  B('Recompensas: Válvula de Bronze (item-chave), 120 XP, 200 moedas, Lâmina-Engrenagem (arma de Kael).'),
  H2('5.2 Luta roteirizada: General Voss'),
  B('Voss + 2 Soldados. Voss tem HP muito alto e defesa que ignora dano abaixo de 10 — o jogador sente que não dá para vencer, mas os golpes dele são lentos e sempre avisados (bom momento para o jogador praticar defesa).'),
  B('Acaba no fim do 4º turno de Voss ou quando o grupo cai. **Sem tela de derrota**; os soldados podem ser derrotados (dão XP normal — pequena vitória dentro da derrota).'),
  B('Voss usa "Punho de Pistão" (físico forte) e "Ordem de Captura" (turno sem ataque; soldados agem logo em seguida).'),
);

// ---------- 6 ----------
children.push(
  H1('6. Personagens no trecho'),
  table(['Personagem', 'Nível', 'Habilidades no trecho', 'Observação'], [
    ['Kael', '1 → 4', 'Atacar, Golpe Rápido, Pistão, Ressonância (cena 6), Engrenagem Final (especial)', 'Lâmina-Engrenagem ao vencer o chefe'],
    ['Gerd (convidado)', 'fixo', 'Atacar, Bomba de Oficina (dano em área), Remendo (cura Kael/Eco), "Faísca e Ferro" com Kael', 'Não sobe de nível, não equipa, não sai do grupo; não pode ser trocado'],
    ['Eco', '3 → 4', 'Atacar, Proteger, Reparo, Barreira, Protocolo Aegis (especial)', 'Entra no nível médio do grupo'],
  ], [16, 10, 46, 28]),
  gap(),
  P('Lyra e Brann continuam nos dados do jogo (para o Ato 1), mas não aparecem no vertical slice. A casa da Lyra e a missão "Barulho na vila" do protótipo saem do mapa.'),
);

// ---------- 7 ----------
children.push(
  H1('7. Áudio'),
  table(['Faixa', 'Uso', 'Status'], [
    ['Tema de título (B)', 'Tela de título', 'pronta'],
    ['Vila Caldeira (A)', 'Vila, interiores, jantar', 'pronta'],
    ['Batalha A/B (alternadas)', 'Batalhas comuns', 'pronta'],
    ['Vitória (B)', 'Fim de batalha', 'pronta'],
    ['Ferro-Velho do Sul', 'Dungeon: metálico, percussão de oficina, mistério leve, loop', 'nova (Suno)'],
    ['Chefe', 'Triturador (e outros chefes do Ato 1)', 'nova (Suno)'],
    ['Tema do Império', 'Chegada de Voss e luta roteirizada: metais, marcha, órgão a vapor', 'nova (Suno)'],
    ['Adeus', 'Explosão da oficina e fuga: piano/cordas, curta (≈60 s)', 'nova (Suno)'],
  ], [28, 52, 20]),
  gap(),
  P('**SFX** (a definir com o Diretor: Suno gera efeitos, mas pode ser mais prático usar um banco livre CC0): passos, cursor/confirmar/cancelar, golpe, golpe perfeito, defesa, cura, vapor, explosão, porta, baú, subir de nível, relógio da relojoaria.'),
);

// ---------- 8 ----------
children.push(
  H1('8. Lista de assets (Codex)'),
  table(['Asset', 'Tipo', 'Status'], [
    ['Tileset Vila Caldeira (exterior + interiores)', 'Tileset 16×16', 'em geração'],
    ['Tileset Ferro-Velho do Sul (sucata, esteira, engrenagens, ruína aetheliana)', 'Tileset 16×16', 'a fazer'],
    ['Kael, Eco, Gerd: poses de batalha (ataque, magia/técnica, dano, KO, vitória)', 'Sprites 64×64', 'a fazer'],
    ['Eco: ciclo de caminhada; Gerd: ciclo de caminhada', 'Sprites 64×64', 'a fazer'],
    ['Retratos: Kael (5 expressões), Gerd (4), Eco (3), Voss (2), Tobias, Berta, Pip, Anselmo', 'Retratos 64×64', 'a fazer (Kael e Gerd neutros existem)'],
    ['NPCs: Tobias, Berta, Pip, Olavo, Ilse, Anselmo, gato Fuligem, soldados', 'Sprites de mapa', 'parcial (aldeões genéricos existem)'],
    ['Inimigos: Rato-Engrenagem, Corvo de Sucata, Aranha-Parafuso, Lâmpada Errante, Soldado', '32–64 px', 'a fazer'],
    ['Chefe Triturador (corpo + 2 garras separadas para as partes)', '96–128 px', 'a fazer'],
    ['General Voss (mapa + batalha)', '64×64 (batalha 80×80)', 'a fazer'],
    ['Dirigível imperial (sombra e sprite sobre a vila)', 'Sprite grande', 'a fazer'],
    ['UI final: moldura de janela, cursor, ícones de status, barra de Éter', 'UI', 'a fazer'],
    ['VFX: corte, faísca, fogo, gelo, raio, cura, vapor, explosão', 'Folhas de efeito', 'a fazer'],
  ], [60, 22, 18]),
);

// ---------- 9 ----------
children.push(
  H1('9. Decisões pendentes (Diretor)'),
  N('**Gerd como convidado (cenas 3–7).** A meta do vertical slice é 3 personagens, mas o prólogo canônico só tem Kael e Eco. Proposta: Gerd luta como convidado. Isso ensina técnicas combinadas cedo e deixa a "morte" dele mais pesada, porque o jogador lutou ao lado dele. Alternativa: estender o slice até a entrada da Lyra (mais longo, ~90 min).', 'num2'),
  N('**Chefe Triturador** (novo, não está na bíblia): o prólogo precisa de um chefe vencível, já que a luta com Voss é uma derrota roteirizada.', 'num2'),
  N('**Gerd reconhece Eco** na cena 5 ("Então ainda funciona") — pista discreta de que ele escondeu a máquina (segredo da bíblia).', 'num2'),
  N('**Voss captura o Guarda Olavo** e reconhece o sobrenome Brunor — reforça que Gerd era ex-engenheiro imperial.', 'num2'),
  N('**Missões secundárias** (gato Fuligem e molas do relojoeiro) substituem a missão de teste do Gerd.', 'num2'),
  N('**Nomes novos:** Tobias (lojista), Dona Berta (estalajadeira), Pip, Guarda Olavo, Velha Ilse, Sr. Anselmo (relojoeiro), gato Fuligem.', 'num2'),
);

d.write(out, { title: 'O Coração de Éter — Roteiro do Prólogo', header: 'O Coração de Éter · Roteiro do Prólogo v0.1' });
