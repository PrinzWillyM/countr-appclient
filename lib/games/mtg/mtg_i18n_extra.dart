// Ergänzungen (Zug-Timer, Missed Triggers, Wer beginnt?, neue Anleitung).
// Haben in mtgT() Vorrang vor der Basis-Übersetzung.
const Map<String, Map<String, String>> mtgExtraTranslations = {
  'de': {
    'settings': 'Einstellungen', 'options': 'Optionen', 'round': 'Runde', 'start_turn': 'Ich beginne', 'tie': 'Gleichstand!', 'starts': 'Beginnt!', 'roll_d20': 'd20 werfen',
    'turn_timer': 'Zug-Timer',
    'turn_timer_desc': 'Zeigt, wer am Zug ist und wie lange der Zug schon dauert. Tippe auf die Zeit, um an den nächsten Spieler (im Uhrzeigersinn) weiterzugeben.',
    'missed_triggers': 'Missed Triggers',
    'missed_triggers_desc': 'Jeder Spieler darf pro Spiel 3 verpasste Trigger nachholen. So bleibt das Spiel fair, wenn unterschiedlich erfahrene Spieler zusammen spielen. Tippe auf ein Symbol, um einen davon zu verbrauchen.',
    'rules_text': '• Tippe auf die linke / rechte Hälfte einer Kachel für −1 / +1. Gedrückt halten für ±10.\n'
        '• Commander-Schaden: Ziehe das Schild-Abzeichen auf einen anderen Spieler und passe den Schaden dort mit − / + an (zieht auch Leben ab).\n'
        '• Steuer-Knopf neben dem Schild: +2 Commander-Steuer. Gedrückt halten für −2.\n'
        '• Das Regler-Symbol öffnet Farbe, Marken (Gift, Energie, Erfahrung) und Commander-Schaden.\n'
        '• Der Knopf in der Mitte öffnet das Menü: Neustart, Einstellungen (Spieler, Anordnung, Startleben, Zug-Timer, Missed Triggers), Wer beginnt? und Würfel.\n'
        '• Ein Spieler ist raus bei 0 Leben, 10 Giftmarken oder 21 Schaden von einem Commander.',
  },
  'en': {
    'settings': 'Settings', 'options': 'Options', 'round': 'Round', 'start_turn': 'I start', 'tie': 'Tie!', 'starts': 'Goes first!', 'roll_d20': 'Roll d20',
    'turn_timer': 'Turn timer',
    'turn_timer_desc': 'Shows whose turn it is and how long it has taken. Tap the time to pass the turn to the next player (clockwise).',
    'missed_triggers': 'Missed triggers',
    'missed_triggers_desc': 'Every player may take back 3 missed triggers per game. Keeps the game fair when players of different experience play together. Tap a symbol to use one.',
    'rules_text': '• Tap the left / right half of a tile for −1 / +1. Hold for ±10.\n'
        '• Commander damage: drag the shield badge onto another player and adjust the damage there with − / + (also reduces life).\n'
        '• Tax button next to the shield: +2 commander tax. Hold for −2.\n'
        '• The sliders icon opens color, counters (poison, energy, experience) and commander damage.\n'
        '• The center button opens the menu: restart, settings (players, layout, starting life, turn timer, missed triggers), high roll and dice.\n'
        '• A player is out at 0 life, 10 poison counters or 21 damage from a single commander.',
  },
  'fr': {
    'settings': 'Réglages', 'options': 'Options', 'round': 'Tour', 'start_turn': 'Je commence', 'tie': 'Égalité !', 'starts': 'Commence !', 'roll_d20': 'Lancer le d20',
    'turn_timer': 'Minuteur de tour',
    'turn_timer_desc': 'Indique qui joue et depuis combien de temps. Touchez le temps pour passer au joueur suivant (sens horaire).',
    'missed_triggers': 'Déclenchements oubliés',
    'missed_triggers_desc': 'Chaque joueur peut rattraper 3 déclenchements oubliés par partie. Cela garde la partie équitable entre joueurs d\'expérience différente. Touchez un symbole pour en utiliser un.',
    'rules_text': '• Touchez la moitié gauche / droite d\'une tuile pour −1 / +1. Maintenez pour ±10.\n'
        '• Blessures de commandant : faites glisser le badge bouclier sur un autre joueur et ajustez avec − / + (réduit aussi les points de vie).\n'
        '• Bouton de taxe à côté du bouclier : +2 de taxe de commandant. Maintenez pour −2.\n'
        '• L\'icône de réglages ouvre couleur, marqueurs (poison, énergie, expérience) et blessures de commandant.\n'
        '• Le bouton central ouvre le menu : recommencer, réglages (joueurs, disposition, points de vie, minuteur, déclenchements oubliés), qui commence et dés.\n'
        '• Un joueur est éliminé à 0 point de vie, 10 marqueurs poison ou 21 blessures d\'un même commandant.',
  },
  'it': {
    'settings': 'Impostazioni', 'options': 'Opzioni', 'round': 'Round', 'start_turn': 'Inizio io', 'tie': 'Pareggio!', 'starts': 'Inizia!', 'roll_d20': 'Lancia il d20',
    'turn_timer': 'Timer del turno',
    'turn_timer_desc': 'Mostra di chi è il turno e da quanto dura. Tocca il tempo per passare al giocatore successivo (in senso orario).',
    'missed_triggers': 'Inneschi dimenticati',
    'missed_triggers_desc': 'Ogni giocatore può recuperare 3 inneschi dimenticati per partita. Mantiene il gioco equo tra giocatori di diversa esperienza. Tocca un simbolo per usarne uno.',
    'rules_text': '• Tocca la metà sinistra / destra di una casella per −1 / +1. Tieni premuto per ±10.\n'
        '• Danno del comandante: trascina lo scudo su un altro giocatore e regola il danno con − / + (riduce anche i punti vita).\n'
        '• Pulsante tassa accanto allo scudo: +2 tassa del comandante. Tieni premuto per −2.\n'
        '• L\'icona impostazioni apre colore, segnalini (veleno, energia, esperienza) e danno del comandante.\n'
        '• Il pulsante centrale apre il menu: ricomincia, impostazioni (giocatori, disposizione, punti vita, timer, inneschi dimenticati), chi inizia e dadi.\n'
        '• Un giocatore è eliminato a 0 punti vita, 10 segnalini veleno o 21 danni da un singolo comandante.',
  },
  'es': {
    'settings': 'Ajustes', 'options': 'Opciones', 'round': 'Ronda', 'start_turn': 'Empiezo yo', 'tie': '¡Empate!', 'starts': '¡Empieza!', 'roll_d20': 'Tirar d20',
    'turn_timer': 'Temporizador de turno',
    'turn_timer_desc': 'Muestra a quién le toca y cuánto dura su turno. Toca el tiempo para pasar al siguiente jugador (en sentido horario).',
    'missed_triggers': 'Disparos olvidados',
    'missed_triggers_desc': 'Cada jugador puede recuperar 3 habilidades disparadas olvidadas por partida. Mantiene la partida justa entre jugadores de distinta experiencia. Toca un símbolo para usar uno.',
    'rules_text': '• Toca la mitad izquierda / derecha de una casilla para −1 / +1. Mantén pulsado para ±10.\n'
        '• Daño de comandante: arrastra el escudo sobre otro jugador y ajusta el daño con − / + (también resta vidas).\n'
        '• Botón de impuesto junto al escudo: +2 de impuesto de comandante. Mantén pulsado para −2.\n'
        '• El icono de ajustes abre color, contadores (veneno, energía, experiencia) y daño de comandante.\n'
        '• El botón central abre el menú: reiniciar, ajustes (jugadores, disposición, vidas, temporizador, disparos olvidados), quién empieza y dados.\n'
        '• Un jugador queda eliminado con 0 vidas, 10 contadores de veneno o 21 de daño de un mismo comandante.',
  },
  'pt': {
    'settings': 'Configurações', 'options': 'Opções', 'round': 'Rodada', 'start_turn': 'Eu começo', 'tie': 'Empate!', 'starts': 'Começa!', 'roll_d20': 'Rolar d20',
    'turn_timer': 'Cronômetro de turno',
    'turn_timer_desc': 'Mostra de quem é a vez e há quanto tempo dura o turno. Toque no tempo para passar ao próximo jogador (sentido horário).',
    'missed_triggers': 'Gatilhos esquecidos',
    'missed_triggers_desc': 'Cada jogador pode recuperar 3 gatilhos esquecidos por partida. Mantém o jogo justo entre jogadores de experiências diferentes. Toque num símbolo para usar um.',
    'rules_text': '• Toque na metade esquerda / direita de um bloco para −1 / +1. Segure para ±10.\n'
        '• Dano de comandante: arraste o escudo sobre outro jogador e ajuste o dano com − / + (também reduz a vida).\n'
        '• Botão de taxa ao lado do escudo: +2 de taxa de comandante. Segure para −2.\n'
        '• O ícone de ajustes abre cor, marcadores (veneno, energia, experiência) e dano de comandante.\n'
        '• O botão central abre o menu: reiniciar, configurações (jogadores, disposição, vida inicial, cronômetro, gatilhos esquecidos), quem começa e dados.\n'
        '• Um jogador é eliminado com 0 de vida, 10 marcadores de veneno ou 21 de dano de um único comandante.',
  },
  'nl': {
    'settings': 'Instellingen', 'options': 'Opties', 'round': 'Ronde', 'start_turn': 'Ik begin', 'tie': 'Gelijkspel!', 'starts': 'Begint!', 'roll_d20': 'Gooi d20',
    'turn_timer': 'Beurttimer',
    'turn_timer_desc': 'Toont wie aan de beurt is en hoe lang de beurt al duurt. Tik op de tijd om de beurt door te geven (met de klok mee).',
    'missed_triggers': 'Gemiste triggers',
    'missed_triggers_desc': 'Elke speler mag per spel 3 gemiste triggers alsnog uitvoeren. Zo blijft het eerlijk als spelers met verschillende ervaring samen spelen. Tik op een symbool om er één te gebruiken.',
    'rules_text': '• Tik op de linker- / rechterhelft van een tegel voor −1 / +1. Houd vast voor ±10.\n'
        '• Commander-schade: sleep het schild naar een andere speler en pas de schade daar aan met − / + (verlaagt ook het leven).\n'
        '• Belastingknop naast het schild: +2 commander-belasting. Houd vast voor −2.\n'
        '• Het instellingen-icoon opent kleur, markers (gif, energie, ervaring) en commander-schade.\n'
        '• De knop in het midden opent het menu: opnieuw, instellingen (spelers, indeling, startleven, beurttimer, gemiste triggers), wie begint en dobbelstenen.\n'
        '• Een speler ligt eruit bij 0 leven, 10 gifmarkers of 21 schade van één commander.',
  },
  'pl': {
    'settings': 'Ustawienia', 'options': 'Opcje', 'round': 'Runda', 'start_turn': 'Zaczynam', 'tie': 'Remis!', 'starts': 'Zaczyna!', 'roll_d20': 'Rzuć d20',
    'turn_timer': 'Licznik tury',
    'turn_timer_desc': 'Pokazuje, czyja jest tura i jak długo trwa. Dotknij czasu, aby przekazać turę następnemu graczowi (zgodnie z ruchem wskazówek zegara).',
    'missed_triggers': 'Pominięte wyzwalacze',
    'missed_triggers_desc': 'Każdy gracz może nadrobić 3 pominięte wyzwalacze na grę. Dzięki temu gra jest uczciwa, gdy grają osoby o różnym doświadczeniu. Dotknij symbolu, aby jeden wykorzystać.',
    'rules_text': '• Dotknij lewej / prawej połowy kafelka, aby dać −1 / +1. Przytrzymaj dla ±10.\n'
        '• Obrażenia dowódcy: przeciągnij tarczę na innego gracza i ustaw obrażenia przyciskami − / + (odejmuje też życie).\n'
        '• Przycisk podatku obok tarczy: +2 podatku dowódcy. Przytrzymaj dla −2.\n'
        '• Ikona ustawień otwiera kolor, znaczniki (trucizna, energia, doświadczenie) i obrażenia dowódcy.\n'
        '• Przycisk na środku otwiera menu: od nowa, ustawienia (gracze, układ, życie, licznik tury, pominięte wyzwalacze), kto zaczyna i kości.\n'
        '• Gracz odpada przy 0 życia, 10 znacznikach trucizny lub 21 obrażeniach od jednego dowódcy.',
  },
  'tr': {
    'settings': 'Ayarlar', 'options': 'Seçenekler', 'round': 'Tur', 'start_turn': 'Ben başlıyorum', 'tie': 'Beraberlik!', 'starts': 'Başlıyor!', 'roll_d20': 'd20 at',
    'turn_timer': 'Tur zamanlayıcı',
    'turn_timer_desc': 'Sıranın kimde olduğunu ve ne kadar sürdüğünü gösterir. Sırayı sonraki oyuncuya (saat yönünde) geçirmek için süreye dokun.',
    'missed_triggers': 'Kaçırılan tetikler',
    'missed_triggers_desc': 'Her oyuncu oyun başına 3 kaçırılan tetiği telafi edebilir. Farklı deneyimdeki oyuncular birlikte oynarken oyunu adil tutar. Birini kullanmak için bir simgeye dokun.',
    'rules_text': '• −1 / +1 için bir kutunun sol / sağ yarısına dokun. ±10 için basılı tut.\n'
        '• Komutan hasarı: kalkan rozetini başka bir oyuncuya sürükle ve hasarı orada − / + ile ayarla (candan da düşer).\n'
        '• Kalkanın yanındaki vergi düğmesi: +2 komutan vergisi. −2 için basılı tut.\n'
        '• Ayarlar simgesi renk, sayaçlar (zehir, enerji, deneyim) ve komutan hasarını açar.\n'
        '• Ortadaki düğme menüyü açar: yeniden başlat, ayarlar (oyuncular, düzen, can, zamanlayıcı, kaçırılan tetikler), kim başlar ve zar.\n'
        '• Bir oyuncu 0 can, 10 zehir sayacı veya tek bir komutandan 21 hasarla elenir.',
  },
  'id': {
    'settings': 'Pengaturan', 'options': 'Opsi', 'round': 'Ronde', 'start_turn': 'Saya mulai', 'tie': 'Seri!', 'starts': 'Mulai duluan!', 'roll_d20': 'Lempar d20',
    'turn_timer': 'Pengatur waktu giliran',
    'turn_timer_desc': 'Menunjukkan giliran siapa dan berapa lama giliran berjalan. Ketuk waktu untuk memberikan giliran ke pemain berikutnya (searah jarum jam).',
    'missed_triggers': 'Pemicu terlewat',
    'missed_triggers_desc': 'Setiap pemain boleh mengulang 3 pemicu yang terlewat per permainan. Menjaga permainan tetap adil antara pemain dengan pengalaman berbeda. Ketuk simbol untuk memakai satu.',
    'rules_text': '• Ketuk setengah kiri / kanan kotak untuk −1 / +1. Tahan untuk ±10.\n'
        '• Kerusakan komandan: seret lencana perisai ke pemain lain dan atur kerusakan dengan − / + (juga mengurangi nyawa).\n'
        '• Tombol pajak di samping perisai: +2 pajak komandan. Tahan untuk −2.\n'
        '• Ikon pengaturan membuka warna, penanda (racun, energi, pengalaman) dan kerusakan komandan.\n'
        '• Tombol tengah membuka menu: mulai ulang, pengaturan (pemain, tata letak, nyawa awal, pengatur waktu, pemicu terlewat), siapa mulai dan dadu.\n'
        '• Pemain kalah pada 0 nyawa, 10 penanda racun, atau 21 kerusakan dari satu komandan.',
  },
  'sv': {
    'settings': 'Inställningar', 'options': 'Alternativ', 'round': 'Runda', 'start_turn': 'Jag börjar', 'tie': 'Oavgjort!', 'starts': 'Börjar!', 'roll_d20': 'Slå d20',
    'turn_timer': 'Turtimer',
    'turn_timer_desc': 'Visar vems tur det är och hur länge turen har pågått. Tryck på tiden för att lämna över till nästa spelare (medurs).',
    'missed_triggers': 'Missade triggers',
    'missed_triggers_desc': 'Varje spelare får ta igen 3 missade triggers per match. Håller spelet rättvist när spelare med olika erfarenhet spelar tillsammans. Tryck på en symbol för att använda en.',
    'rules_text': '• Tryck på vänster / höger halva av en ruta för −1 / +1. Håll inne för ±10.\n'
        '• Commander-skada: dra sköldmärket till en annan spelare och justera skadan där med − / + (drar även liv).\n'
        '• Skatteknappen bredvid skölden: +2 commander-skatt. Håll inne för −2.\n'
        '• Inställningsikonen öppnar färg, markörer (gift, energi, erfarenhet) och commander-skada.\n'
        '• Knappen i mitten öppnar menyn: starta om, inställningar (spelare, layout, startliv, turtimer, missade triggers), vem börjar och tärningar.\n'
        '• En spelare är ute vid 0 liv, 10 giftmarkörer eller 21 skada från en och samma commander.',
  },
  'hr': {
    'settings': 'Postavke', 'options': 'Opcije', 'round': 'Runda', 'start_turn': 'Ja počinjem', 'tie': 'Neriješeno!', 'starts': 'Počinje!', 'roll_d20': 'Baci d20',
    'turn_timer': 'Mjerač poteza',
    'turn_timer_desc': 'Pokazuje tko je na potezu i koliko potez traje. Dodirni vrijeme za predaju poteza sljedećem igraču (u smjeru kazaljke na satu).',
    'missed_triggers': 'Propušteni okidači',
    'missed_triggers_desc': 'Svaki igrač smije nadoknaditi 3 propuštena okidača po igri. Tako igra ostaje poštena kad igraju igrači različitog iskustva. Dodirni simbol da iskoristiš jedan.',
    'rules_text': '• Dodirni lijevu / desnu polovicu pločice za −1 / +1. Drži za ±10.\n'
        '• Šteta zapovjednika: povuci značku štita na drugog igrača i podesi štetu s − / + (oduzima i život).\n'
        '• Gumb poreza pokraj štita: +2 poreza zapovjednika. Drži za −2.\n'
        '• Ikona postavki otvara boju, žetone (otrov, energija, iskustvo) i štetu zapovjednika.\n'
        '• Gumb u sredini otvara izbornik: ponovo, postavke (igrači, raspored, život, mjerač poteza, propušteni okidači), tko počinje i kockice.\n'
        '• Igrač ispada s 0 života, 10 žetona otrova ili 21 štete od jednog zapovjednika.',
  },
  'ru': {
    'settings': 'Настройки', 'options': 'Опции', 'round': 'Раунд', 'start_turn': 'Я начинаю', 'tie': 'Ничья!', 'starts': 'Ходит первым!', 'roll_d20': 'Бросить d20',
    'turn_timer': 'Таймер хода',
    'turn_timer_desc': 'Показывает, чей сейчас ход и сколько он длится. Нажмите на время, чтобы передать ход следующему игроку (по часовой стрелке).',
    'missed_triggers': 'Пропущенные триггеры',
    'missed_triggers_desc': 'Каждый игрок может за игру 3 раза разыграть пропущенный триггер. Это сохраняет честность, когда играют игроки с разным опытом. Нажмите на символ, чтобы использовать один.',
    'rules_text': '• Нажмите на левую / правую половину плитки для −1 / +1. Удерживайте для ±10.\n'
        '• Урон командира: перетащите значок щита на другого игрока и настройте урон кнопками − / + (жизни тоже уменьшаются).\n'
        '• Кнопка налога рядом со щитом: +2 налога командира. Удерживайте для −2.\n'
        '• Значок настроек открывает цвет, счётчики (яд, энергия, опыт) и урон командира.\n'
        '• Кнопка в центре открывает меню: заново, настройки (игроки, расположение, жизни, таймер хода, пропущенные триггеры), кто первый и кубики.\n'
        '• Игрок выбывает при 0 жизней, 10 счётчиках яда или 21 уроне от одного командира.',
  },
  'ja': {
    'settings': '設定', 'options': 'オプション', 'round': 'ラウンド', 'start_turn': '先攻する', 'tie': '同点！', 'starts': '先攻！', 'roll_d20': 'd20を振る',
    'turn_timer': 'ターンタイマー',
    'turn_timer_desc': '誰のターンか、どれくらい経過したかを表示します。時間をタップすると次のプレイヤー（時計回り）にターンを渡します。',
    'missed_triggers': '誘発忘れ',
    'missed_triggers_desc': '各プレイヤーは1ゲームにつき3回まで、忘れた誘発をやり直せます。経験の違うプレイヤー同士でも公平に遊べます。記号をタップして1回使います。',
    'rules_text': '• タイルの左半分 / 右半分をタップで −1 / +1。長押しで ±10。\n'
        '• 統率者ダメージ：盾バッジを別のプレイヤーにドラッグし、− / + でダメージを調整します（ライフも減ります）。\n'
        '• 盾の横の税ボタン：統率者税 +2。長押しで −2。\n'
        '• 設定アイコンで色、カウンター（毒・エネルギー・経験）、統率者ダメージを開きます。\n'
        '• 中央のボタンでメニュー：リスタート、設定（プレイヤー、レイアウト、初期ライフ、ターンタイマー、誘発忘れ）、先攻決め、ダイス。\n'
        '• ライフ0、毒カウンター10個、または1体の統率者から21点のダメージで敗北です。',
  },
  'ko': {
    'settings': '설정', 'options': '옵션', 'round': '라운드', 'start_turn': '내가 시작', 'tie': '동점!', 'starts': '선공!', 'roll_d20': 'd20 굴리기',
    'turn_timer': '턴 타이머',
    'turn_timer_desc': '누구의 턴인지와 턴이 얼마나 지났는지 보여줍니다. 시간을 탭하면 다음 플레이어(시계 방향)에게 턴을 넘깁니다.',
    'missed_triggers': '놓친 유발',
    'missed_triggers_desc': '각 플레이어는 게임당 3번까지 놓친 유발을 되돌릴 수 있습니다. 경험이 다른 플레이어끼리도 공정하게 플레이할 수 있습니다. 기호를 탭해 하나를 사용하세요.',
    'rules_text': '• 타일의 왼쪽 / 오른쪽 절반을 탭하면 −1 / +1. 길게 누르면 ±10.\n'
        '• 커맨더 피해: 방패 배지를 다른 플레이어에게 드래그하고 − / + 로 피해를 조정하세요 (라이프도 줄어듭니다).\n'
        '• 방패 옆 세금 버튼: 커맨더 세금 +2. 길게 누르면 −2.\n'
        '• 설정 아이콘으로 색상, 카운터(독, 에너지, 경험), 커맨더 피해를 엽니다.\n'
        '• 가운데 버튼은 메뉴를 엽니다: 다시 시작, 설정(플레이어, 배치, 시작 라이프, 턴 타이머, 놓친 유발), 선공 정하기, 주사위.\n'
        '• 라이프 0, 독 카운터 10개 또는 한 커맨더에게 받은 피해 21이면 탈락합니다.',
  },
  'zh': {
    'settings': '设置', 'options': '选项', 'round': '轮', 'start_turn': '我先开始', 'tie': '平局！', 'starts': '先手！', 'roll_d20': '掷 d20',
    'turn_timer': '回合计时器',
    'turn_timer_desc': '显示轮到谁以及该回合已用时间。点击时间可将回合交给下一位玩家（顺时针）。',
    'missed_triggers': '遗漏触发',
    'missed_triggers_desc': '每位玩家每局可补回 3 次遗漏的触发。让经验不同的玩家也能公平对局。点击一个符号来使用一次。',
    'rules_text': '• 点击方块的左半 / 右半部分 −1 / +1。长按 ±10。\n'
        '• 指挥官伤害：把盾牌徽章拖到另一名玩家上，然后用 − / + 调整伤害（同时扣除生命）。\n'
        '• 盾牌旁的税按钮：指挥官税 +2。长按 −2。\n'
        '• 设置图标可打开颜色、指示物（中毒、能量、经验）和指挥官伤害。\n'
        '• 中间的按钮打开菜单：重新开始、设置（玩家、布局、初始生命、回合计时器、遗漏触发）、谁先手和骰子。\n'
        '• 生命为 0、10 个中毒指示物或受到同一指挥官 21 点伤害时出局。',
  },
  'hi': {
    'settings': 'सेटिंग्स', 'options': 'विकल्प', 'round': 'राउंड', 'start_turn': 'मैं शुरू करूँ', 'tie': 'बराबरी!', 'starts': 'शुरू करेगा!', 'roll_d20': 'd20 फेंकें',
    'turn_timer': 'टर्न टाइमर',
    'turn_timer_desc': 'दिखाता है कि किसकी बारी है और बारी कितनी देर से चल रही है। अगले खिलाड़ी (घड़ी की दिशा में) को बारी देने के लिए समय पर टैप करें।',
    'missed_triggers': 'छूटे ट्रिगर',
    'missed_triggers_desc': 'हर खिलाड़ी प्रति गेम 3 छूटे हुए ट्रिगर दोबारा कर सकता है। अलग-अलग अनुभव वाले खिलाड़ियों के साथ खेल निष्पक्ष रहता है। एक का उपयोग करने के लिए किसी चिह्न पर टैप करें।',
    'rules_text': '• −1 / +1 के लिए टाइल के बाएँ / दाएँ आधे हिस्से पर टैप करें। ±10 के लिए दबाकर रखें।\n'
        '• कमांडर डैमेज: ढाल बैज को दूसरे खिलाड़ी पर खींचें और − / + से डैमेज बदलें (जीवन भी घटता है)।\n'
        '• ढाल के पास टैक्स बटन: +2 कमांडर टैक्स। −2 के लिए दबाकर रखें।\n'
        '• सेटिंग्स आइकन रंग, काउंटर (विष, ऊर्जा, अनुभव) और कमांडर डैमेज खोलता है।\n'
        '• बीच का बटन मेनू खोलता है: फिर से शुरू, सेटिंग्स (खिलाड़ी, लेआउट, जीवन, टर्न टाइमर, छूटे ट्रिगर), कौन शुरू करेगा और पासे।\n'
        '• 0 जीवन, 10 विष काउंटर या एक ही कमांडर से 21 डैमेज पर खिलाड़ी बाहर हो जाता है।',
  },
  'bn': {
    'settings': 'সেটিংস', 'options': 'বিকল্প', 'round': 'রাউন্ড', 'start_turn': 'আমি শুরু করব', 'tie': 'সমান!', 'starts': 'শুরু করবে!', 'roll_d20': 'd20 ছুড়ুন',
    'turn_timer': 'টার্ন টাইমার',
    'turn_timer_desc': 'কার পালা এবং পালা কতক্ষণ চলছে তা দেখায়। পরের খেলোয়াড়কে (ঘড়ির কাঁটার দিকে) পালা দিতে সময়ে ট্যাপ করুন।',
    'missed_triggers': 'মিস করা ট্রিগার',
    'missed_triggers_desc': 'প্রত্যেক খেলোয়াড় প্রতি গেমে ৩টি মিস করা ট্রিগার আবার করতে পারে। ভিন্ন অভিজ্ঞতার খেলোয়াড়দের মধ্যে খেলা ন্যায্য থাকে। একটি ব্যবহার করতে একটি চিহ্নে ট্যাপ করুন।',
    'rules_text': '• −1 / +1 এর জন্য টাইলের বাম / ডান অর্ধেকে ট্যাপ করুন। ±10 এর জন্য চেপে ধরে রাখুন।\n'
        '• কমান্ডার ড্যামেজ: ঢাল ব্যাজ অন্য খেলোয়াড়ের উপর টেনে আনুন এবং − / + দিয়ে ড্যামেজ ঠিক করুন (জীবনও কমে)।\n'
        '• ঢালের পাশে ট্যাক্স বোতাম: +2 কমান্ডার ট্যাক্স। −2 এর জন্য চেপে ধরে রাখুন।\n'
        '• সেটিংস আইকন রং, কাউন্টার (বিষ, শক্তি, অভিজ্ঞতা) এবং কমান্ডার ড্যামেজ খোলে।\n'
        '• মাঝের বোতাম মেনু খোলে: আবার শুরু, সেটিংস (খেলোয়াড়, বিন্যাস, জীবন, টার্ন টাইমার, মিস করা ট্রিগার), কে শুরু করবে এবং পাশা।\n'
        '• ০ জীবন, ১০টি বিষ কাউন্টার বা একই কমান্ডার থেকে ২১ ড্যামেজে খেলোয়াড় বাদ পড়ে।',
  },
};
