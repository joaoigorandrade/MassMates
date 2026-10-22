The original plan is a solid technical blueprint, especially regarding privacy (keeping Confession and Spiritual Diary data strictly on-device) and respectful monetization (protecting prayer and Scripture screens from ads). However, when stripped of code and examined strictly as a **User Experience (UX) and Product Design document**, several critical gaps, friction points, and logical errors emerge.

---

## Part 1: Deep UX Analysis, Errors & Improvements

### 1. Critical Errors & Logical Gaps in the Original Plan

* **The "Local-Only Diary" Data Loss Trap:**
  * *The Error:* Storing the Spiritual Diary and Confession logs strictly on the device protects privacy, but the plan fails to address what happens when a user loses, breaks, or upgrades their phone. Losing years of spiritual reflections and confession history without warning is a catastrophic UX failure.
  * *The Fix:* Add transparent onboarding warnings that private entries live *only* on the phone, coupled with a **Biometric Lock (Face ID / Touch ID)** for the Diary tab and a simple **"Export Encrypted Backup"** feature so users can manually safeguard their history.

* **Undefined "Guardian Angel" Mechanic:**
  * *The Error:* The plan references a "Guardian Angel draw" and card in the Group Progress tab, but never defines how a user experiences it. Is it anonymous? Does it reset weekly or per challenge? How do users interact with their assigned person?
  * *The Fix:* Define the user loop clearly: an opt-in weekly or challenge-long secret prayer pairing where a user is assigned a groupmate to pray for daily, with a dedicated button to send an anonymous *"Your Guardian Angel prayed for you today"* nudge.

* **Ambiguous Streak & "Rule of Life" Logic:**
  * *The Error:* During onboarding, users select a "Rule of Life" (e.g., Rosary + Daily Gospel + Morning Offering). However, the plan doesn't clarify what increments the daily **Streak**. Does completing *one* item keep the streak alive, or must the user complete *100%* of their Rule of Life? Furthermore, if a user only logs a private Confession, does that count toward their public streak?
  * *The Fix:* Separate the **Daily Streak** (completed at least 1 spiritual practice today, private or public) from the **Rule of Life Ring** (completing 100% of one's chosen daily commitments). This prevents discouragement while still rewarding full discipline.

* **Missing Community Safety & Moderation (App Store Requirement):**
  * *The Error:* The app features group feeds, photo proof uploads, prayer walls, and real-time chat, yet has **zero UX flows for moderation**. Apple will reject an app with user-generated content that lacks reporting and blocking mechanisms, and group leaders have no way to manage disruptive members.
  * *The Fix:* Add user flows for Group Admin controls (remove member, delete post, reset invite code) and member safety (block user, report inappropriate photo/comment).

* **Photo Proof Privacy & Storage Friction:**
  * *The Error:* Requiring "Photo Proof" for spiritual practices (like Mental Prayer or Mass) can feel performative or intrusive inside a church, and there is no mention of who can see those photos in Discoverable/Public groups.
  * *The Fix:* Reframe "Proof" as **"Sharing & Witness."** Make "Reflection Text" or "Honor System (Amen)" the recommended defaults, and clearly badge groups that require photos so users know before joining.

### 2. UX Friction Points & Recommended Improvements

* **Elimination of Scroll Fatigue (Single-Viewport Rule):**
  * *Issue:* Crowded vertical feeds, stacked cards, and lengthy configuration forms force users into constant scrolling, cluttering the mental space and destroying spiritual recollection.
  * *Improvement:* Deconstruct complex flows into discrete, **single-viewport screens without vertical scroll** (390×844pt viewport constraint). When content overflows, decompose it into paginated steps, carousel cards, or dedicated child views (e.g., Onboarding steps 1–3, Gospel paged reading, Examen 1 question per screen, Confession 1 commandment per screen, Group tabs as focused single-viewport pages).

* **Cold-Start Onboarding Fatigue:**
  * *Issue:* Overloaded setup screens combining name, parish, photo, rule picker, and tracking disclosures create drop-off.
  * *Improvement:* Break setup into three feather-light single-screen steps (`04a` Name & Parish, `04b` Rule Template Picker, `04c` Privacy Affirmation).

* **Group Limit vs. Sponsored Challenges Conflict:**
  * *Issue:* Limiting free users to 2 groups while also promoting "Official Sponsored Challenges" creates a clash.
  * *Improvement:* Allow **2 Personal/Parish Groups** for free, plus **1 Official/Seasonal Challenge** slot that doesn't count against their personal group limit. Additional slots can be unlocked for 30 days via a rewarded video.

* **Audio & Eyes-Closed Rosary Experience:**
  * *Issue:* Looking at screens during prayer breaks contemplative silence.
  * *Improvement:* Include optional **subtle haptic bead-counting** (tap anywhere on screen to advance Hail Marys with distinct haptics for Our Father) and background timer integration with Dynamic Island / Lock Screen.

---

## Part 2: Updated MassMates User Experience Plan

# MassMates: Product & User Experience Plan (v2.2)

**Primary Language:** Portuguese (Brazil) | **Secondary Language:** English  
**Design System:** Sacred Quiet (Stitch Project `4744816768065646201`, Asset `b1053e5c86c94c00b021f1e75ea3d0f7`)

**Core Mission:** Help Catholics build daily spiritual consistency through fraternal accountability, liturgical rhythm, and complete respect for interior recollection, extreme visual minimalism, and absolute privacy.

---

## 1. Experience Principles & Visual Identity

### 1.1 The Single-Viewport Minimalist Architecture
* **Zero-Scroll Standard:** Every primary screen and modal is engineered to fit within a single mobile viewport (390×844pt standard iPhone) without vertical scrolling.
* **Progressive Disclosure & Horizontal Flow:** If content exceeds a single viewport, it is decomposed into horizontal paging (`TabView(selection:).tabViewStyle(.page)`), step-by-step sequential sheets, or dedicated child sub-screens pushed with back navigation.
* **Quiet First (Whitespace & Hairlines over Cards):** Heavy drop shadows, embossed card boxes, and cluttered borders are banned. Depth is created purely through generous negative space (`#FAF8F5` in Light, `#121110` in Dark) and ultra-thin 1pt hairline dividers (`#E7E3DC` / `#33302C`).
* **Sacred Book Typography:** Book serif (`New York`) for sacred texts, liturgical headers, and contemplation; clean sans-serif (`SF Pro`) for UI controls and metadata; tabular rounded numerals (`SF Pro Rounded`) for statistics and streaks.

### 1.2 Privacy & Trust Architecture
* **Sacred Privacy by Default:** Confession examinations and personal Spiritual Diary reflections live strictly on-device in encrypted local storage. They never sync to Supabase, never appear in group feeds, and never feed ad targeting algorithms.
* **Biometric Guard & Manual Backup:** The Spiritual Diary and Confession modules are protected by **Face ID / Touch ID**. Users can export an encrypted JSON backup file at any time.
* **Authentic Liturgical Texts:** Scripture readings, Psalms, and Saints of the Day use official Church-approved translations (CNBB in Brazil).

---

## 2. Core Mechanics & Gamification Rules

* **Daily Streak vs. Rule of Life Ring:**
  * **The Streak Flame:** Increments when the user logs *at least one* spiritual practice per day (public or private).
  * **The Rule of Life Ring:** Measures percentage completion of the specific commitments chosen in the user's personal daily rule.
* **Fraternities vs. Challenges:**
  * **Fraternities (Continuous):** Small ongoing parish or family groups with no expiration.
  * **Challenges / Seasons (Time-Bound):** Fixed duration (e.g., *St. Michael's Lent* 40 days, *Novena to Our Lady of Aparecida* 9 days).
* **Group Scoring Modes (Creator-Selected):**
  1. **Faithful Days:** 1 point per active day, emphasizing consistency over volume.
  2. **Collective Treasure:** No competitive leaderboard; all check-ins contribute to a shared group goal (e.g., *"500 Rosaries this month"*).
  3. **Custom Points:** Weighted points by devotion (Mass = 30 pts, Rosary = 20 pts, Gospel = 10 pts).
* **The Secret Guardian Angel Mechanic:**
  * Opt-in weekly or challenge-long secret pairing within each group.
  * Each user sees their protected groupmate's name and prayer intentions.
  * Tapping *"Rezei pelo meu protegido"* dispatches an anonymous encouraging notification. Identities are revealed only at the cycle's conclusion.

---

## 3. Screen-by-Screen User Journey (Ultra-Minimalist & No-Scroll Decomposed Flow)

### Flow 1: Onboarding & Personal Commitment (No-Scroll Steps)

1. **Welcome & Value Proposition (`01_Splash` & `02_Onboarding`):**
   * Three full-screen paged slides (no scrolling):
     1. *Constância Espiritual* — Daily spiritual rhythm paired with church liturgy.
     2. *Fraternidade & Oração* — Praying together with your parish or small group.
     3. *Silêncio & Intimidade* — Sacred privacy for confession and personal diary.
   * Single tap advances; bottom dot indicators.

2. **Account Sign-In (`03_Auth`):**
   * Single-viewport screen: Serif title, subtitle, three clean native sign-in buttons (Apple, Google, Email magic link), and brief terms footnote. Zero scrolling.

3. **Profile Setup Flow (`04a`–`04c` Decomposed 3-Step Wizard):**
   * Instead of a long, scrolling configuration form, setup is split into 3 single-viewport steps:
     * **`04a_ProfileName`:** Step 1/3 — Avatar photo circle + underline text fields for Name and Parish/City. Next button.
     * **`04b_ProfileRuleOfLife`:** Step 2/3 — Radio selector between 3 preset rules (*Essencial Diária*, *Devocional Clássica*, *Ascética/Quaresmal*) + "Personalizar" modal. Next button.
     * **`04c_ProfilePrivacy`:** Step 3/3 — Three concise bullet points on local storage, zero diary tracking, and transparent ad-supported model. "Aceitar e começar" button.

---

### Flow 2: The "Hoje" Tab (Personal Spiritual Hub)

4. **Today Dashboard (`05_TodayDashboard` — Single Viewport):**
   * **No Scroll Guarantee:** All core elements fit squarely in 844pt height above the minimal 4-slot Tab Bar:
     * *Liturgical Header:* Liturgical season pill (e.g., `TEMPO COMUM · VERDE` with 6pt green dot), Saint of the Day in 34pt New York Serif, and streak flame numeral (e.g., `🔥 12`).
     * *Rule of Life Ring:* Large central liturgical-tint ring with `3/5` numeral and caption *"Regra de Vida"*. Tapping the ring or *"Ver regra →"* pushes the dedicated checklist screen.
     * *Quick Devotional Access:* Two clean hairline-separated rows:
       * *Evangelho do dia* (`Lc 12,49-53`) with right chevron.
       * *Oração & Terço* with right chevron.
     * *Ad Anchor:* Tiny, quiet single-line banner labeled `"Patrocinado"` anchored above tab bar.

5. **Rule of Life Checklist Sub-Screen (`05b_RuleOfLifeChecklist` — Single Viewport):**
   * Pushed screen from Today ring: Back chevron, title *"Regra de Vida"*, horizontal progress bar (`3 de 5`).
   * Exactly 5 spacious 56pt rows with circular check toggles:
     * *Oferecimento da manhã* (completed)
     * *Evangelho do dia* (completed)
     * *Terço Mariano* (completed)
     * *Angelus (12h ou 18h)* (pending)
     * *Exame da noite* (pending)
   * Bottom text link: *"Editar regra de vida"*. Zero ads.

6. **Daily Gospel & Scripture Reader (`06_DailyGospelPaged` — Single Viewport Horizontal Pages):**
   * **Strictly Ad-Free & Zero-Scroll:** Uses horizontal paging between readings instead of an endless scrolling missal:
     * *Top Bar:* Close `X`, segmented reading switcher (`1ª Leitura · Salmo · Evangelho`), text-size selector (`Aa`).
     * *Page View:* Active reading formatted in New York Serif 19/30pt, max 60 characters measure, sized to fit the screen without scrolling.
     * *Bottom Bar:* 3-page dot indicator and quiet button *"Lectio Divina →"*.

7. **Lectio Divina Guided Completion (`06b_LectioDivina` — Single Viewport):**
   * Pushed or advanced from Gospel: Distraction-free four-stage contemplation prompt:
     1. *Ler* — O que o texto diz em si?
     2. *Meditar* — O que Deus me diz através deste texto?
     3. *Orar* — O que respondo a Deus em oração?
     4. *Contemplar* — Repousar no silêncio da Sua presença.
   * Prominent liturgical-tint button: *"Concluir & Registrar Fruto"*, pre-filling a check-in.

8. **Prayer Timer & Guided Rosary (`07_PrayerTimerModal` — Single Viewport):**
   * Segmented selector: *Silêncio Mental* vs. *Terço*.
   * *Mental Prayer Mode:* Minimal countdown ring (10 min, 15 min, 30 min) with ambient silence or soft bell. Operates in background with Dynamic Island / Lock Screen Live Activity.
   * *Guided Rosary Mode:* Displays current Mystery (e.g., *"2º Mistério Gozoso: A Visitação"*), spiritual fruit, and a circular 10-bead ring. Supports full-screen tap-anywhere eyes-closed haptic advancement.
   * Zero ads, zero background clutter.

---

### Flow 3: The "Grupos" Tab (Community & Discovery)

9. **Groups Home (`08_GroupsHome` — Single Viewport):**
   * Header: Serif title *"Grupos"*, top-right `+` button, slot status caption (`SUAS VAGAS · 2 DE 3`).
   * Active Group List (maximum 3 concise 64pt rows):
     * *Fraternidade São José* (Continuous, 8 members).
     * *Jovens da Matriz* (Continuous, 14 members).
     * *Quaresma de São Miguel* (Seasonal Challenge, Day 12 of 40 progress).
   * Discovery Row: *"Descobrir desafios sazonais →"* pushes discovery screen.
   * Bottom Actions: Hairline-divided pill buttons: *"Entrar com código"* | *"Criar grupo"*.

10. **Discover Challenges Sub-Screen (`08b_DiscoverChallenges` — Single Viewport):**
    * Pushed screen: Back chevron, title *"Desafios Sazonais"*.
    * Three featured seasonal initiatives with date badges and participant counts:
      * *Novena de Nossa Senhora Aparecida* (9 days).
      * *Quaresma Arquidiocesana* (40 days).
      * *Rosário de Outubro* (Sponsored challenge, tastefully badged `"Patrocinado"`).
    * One-tap *"Participar"* with seasonal slot allocation.

11. **Create or Join Group Modals (`09a`–`09c` Decomposed Modals):**
    * **`09a_JoinGroupCode`:** 24pt sheet with capsule grabber: Serif title *"Entrar em um grupo"*, 6 individual digit underline cells (`4 8 2 _ _ _`), and green button *"Entrar"*.
    * **`09b_CreateGroupIdentity`:** Step 1/2: Group name underline field, 64pt circular photo picker, and type selector (*Fraternidade contínua* vs. *Desafio com datas*).
    * **`09c_CreateGroupRules`:** Step 2/2: Scoring Mode radio picker (*Dias fiéis*, *Tesouro coletivo*, *Pontos personalizados*) and Sharing Requirement (*Aberto*, *Fruto escrito*, *Foto testemunho*). Next creates group.

---

### Flow 4: Inside a Group (`10a`–`10e` Decomposed Tabs)

Instead of a cluttered, infinitely scrolling screen, group details are divided into four ultra-minimalist sub-tabs plus a dedicated Guardian Angel card:

12. **Group Feed (`10a_GroupFeed` — Single Viewport Paged/Compact):**
    * Displays the latest 2–3 community check-in witnesses with member avatar, devotion badge, brief reflection excerpt, and quiet reactions (*"Amém 8"*, *"Unidos em oração 3"*).
    * Quiet pagination link: *"Ver registros anteriores →"*. Includes 1 clearly labeled native card per page.

13. **Group Progress & Collective Goal (`10_GroupProgress` — Single Viewport):**
    * Collective Goal Bar (e.g., *"Meta do Mês: 312 / 500 Terços"*).
    * Guardian Angel summary row: *"Seu Anjo da Guarda →"* with wing icon (pushes dedicated view).
    * Member Consistency Ranking: Top 5 member consistency list in clean hairline rows with active day counts.

14. **Secret Guardian Angel Dedicated Screen (`10b_GuardianAngel` — Single Viewport):**
    * Sacred sanctuary card: Protected soul's name (e.g., *Maria Clara*), her prayer intentions in book serif italic, cycle end date (*"Revelação no domingo"*), and prominent action button: *"Rezei pelo meu protegido"* (dispatches anonymous nudge).

15. **Prayer Intentions Wall (`10c_GroupIntentions` — Single Viewport):**
    * Clean list of active prayer requests with *"Rezei por você (N)"* counter button and *"Pedir oração"* composer sheet.

16. **Fraternal Chat & Announcements (`10d_GroupChat` — Single Viewport):**
    * Top pinned announcement banner (e.g., *"Encontro presencial no sábado às 19h"*).
    * Compact message transcript and lightweight message composer.

---

### Flow 5: The Check-In Engine (Central `+` Button)

17. **Check-In Wizard (`11a`–`11c` Decomposed 3-Step Sheet):**
    * **`11a_CheckInPractice`:** Step 1/3: 2-column grid of 8 devotion tiles (Terço, Santa Missa, Evangelho, Adoração, Oração Mental, Leitura Espiritual, Jejum, Confissão). Confession is marked with a lock icon.
    * **`11b_CheckInFruit`:** Step 2/3: Underline reflection text area (*"Fruto da oração"*), optional photo witness button, and destination toggles (*Fraternidade São José*, *Jovens da Matriz*, *Só no meu diário*). If Confession was selected, destination is permanently locked to *Só no meu diário* with public sharing disabled.
    * **`11c_CheckInCelebration`:** Step 3/3: Animated closed ring checkmark, streak flame increment (`🔥 13 dias seguidos`), and confirmation message. Single tap to dismiss.

---

### Flow 6: The "Meu Caminho" Tab (Personal Growth & History)

18. **My Path Dashboard (`12_MyPathDashboard` — Single Viewport):**
    * **Consistency Heatmap:** Compact 12-week grid of rounded squares shaded in liturgical green opacities (15%, 35%, 65%, 100%).
    * **Spiritual Totals:** 3 clean tabular numerals: Lifetime Rosaries, Masses, and Prayer Hours.
    * **Navigation Rows:** Chevrons leading to:
      * *Diário Espiritual* (protected by Face ID icon).
      * *Graça & Misericórdia* (streak repair and theme unlocks).
      * *Ajustes* (settings index).

19. **Grace & Mercy Sub-Screen (`12b_GraceAndMercy` — Single Viewport):**
    * Pushed screen: Two clean option cards with *"Assistir vídeo"*:
      * *Misericórdia da Sequência:* Repair 1 missed day per month due to sickness or travel.
      * *Temas de Santos:* Unlock seasonal liturgical icons and accent palettes for 7 days.

20. **Spiritual Diary Index (`13_SpiritualDiaryList` — Single Viewport Month Pager):**
    * Month switcher (`‹ Outubro 2026 ›`).
    * Displays 5 latest reflections in clean hairline rows showing date, practice pill, and 1-line italic quote.
    * Tapping any row opens the single-entry reader. Bottom Face ID status pill.

21. **Single Entry Immersive Reader (`14_DiaryEntryReader` — Single Viewport Book Card):**
    * Sacred quiet reading screen for one specific entry: Date, devotion tag, full prayer reflection in 19/30 New York Serif, and horizontal chevrons (`← 20 Out` | `22 Out →`) to flip between reflections. Zero ads.

22. **Settings Hub & Sub-Screens (`14` & `14a`–`14c` Decomposed Hierarchy):**
    * **`14_SettingsIndex`:** 4 grouped navigation rows with chevrons: *Lembretes Litúrgicos*, *Aparência & Idioma*, *Privacidade & Conta*, plus App Version and two-tap *Excluir Conta*.
    * **`14a_LiturgicalReminders`:** 5 toggle rows with pickers: Morning Offering (06:30), Angelus (12:00 & 18:00), Rosary (20:00), Night Examen (22:00).
    * **`14b_AppearanceAndLanguage`:** Theme switcher (Sistema / Claro / Escuro), App Icon picker, Language toggle (Português / English).
    * **`14c_PrivacyAndAccount`:** Face ID biometric lock toggle, encrypted backup export button, and ad personalization opt-outs.

---

### Flow 7: Sacred Devotional Guides (Single Step / Rite per Screen)

23. **Nightly Examination of Conscience (`15_ExamenStepByStep` — 5 Single-Viewport Steps):**
    * Uses a 5-step horizontal wizard (1 step per screen):
      * *Passo 1:* Presença de Deus — Agradecer pelas graças do dia.
      * *Passo 2:* Rever o Dia — Onde amei e onde fraquejei? (Optional reflection text field).
      * *Passo 3:* Pedir Perdão — Ato de Contrição.
      * *Passo 4:* Resolução para o Amanhã — Um propósito concreto.
      * *Passo 5:* Oração Final e bênção da noite.

24. **Confession Preparation & Examination (`16_ConfessionStepByStep` — 10 Single-Viewport Steps):**
    * 10 distinct, unhurried screens (one per Commandment):
      * Shows the Commandment in bold serif, biblical context, and 3–4 concise checklist questions with taps.
      * Stored strictly in volatile device memory; automatically wiped once the user completes or exits the confession guide.

25. **Holy Mass Guide & Responses (`17_HolyMassRiteByRite` — 6 Single-Viewport Rites):**
    * Paged missal screen divided into 6 clear liturgical sections:
      1. *Ritos Iniciais* (Saudação, Ato Penitencial, Glória).
      2. *Liturgia da Palavra* (Leituras, Homilia, Credo).
      3. *Liturgia Eucarística* (Ofertório, Oração Eucarística).
      4. *Rito da Comunhão* (Pai Nosso, Cordeiro de Deus, Comunhão).
      5. *Ritos Finais* (Bênção, Envio).
    * Traditional liturgical formatting: Red rubrics in uppercase small caps, priest lines indicated by `S.` and people's responses in bold `T.`. Zero ads, zero scrolling.

---

## 4. Respectful Monetization Experience

MassMates is **100% free for all users and parishes**, maintaining revenue through ads that strictly respect sacred boundaries:

| Placement | Screen Location | Format & Guardrails |
| :--- | :--- | :--- |
| **Sanctuary Rule (Zero Ads)** | Daily Gospel (`06`), Prayer Timer (`07`), Diary (`13`/`14`), Confession (`16`), Mass Guide (`17`) | **Strictly Ad-Free.** Never display banners, interstitial videos, or sponsored links during prayer, contemplation, or private examination. |
| **Single-Line Banner** | Bottom of Today Dashboard (`05`) | Static, quiet single-line banner row labeled `"Patrocinado"`. Never occludes navigation or triggers accidental taps. |
| **In-Feed Sponsor Card** | Group Feed (`10a`) & Discovery (`08b`) | Maximum 1 quiet card per 6 organic posts, matching the Sacred Quiet token aesthetic. |
| **Post-Check-In Interstitial** | Dismissal of Non-Confession Check-In (`11c`) | Capped strictly at **maximum 1 impression per 24 hours**. Never shown on launch, never on Confession logs. |
| **Voluntary Rewarded Video** | Profile (`12b`), Group Slot Unlock (`08`) | 100% opt-in. Unlocks Streak Mercy (1/month), +1 Group Slot (30 days), or Saint App Themes (7 days). |

**Prohibited Categories:** Gambling, dating, political campaigns, occult, and alcoholic products are permanently blocked at the ad-network mediation level.

---

## 5. Stitch MCP Screen Directory & Traceability Matrix

Every screen in the MassMates user journey is synchronized 1:1 with Stitch Project `4744816768065646201`:

| Screen Code | Screen Title in Stitch MCP | Dimensions | Scroll Mode | Key Architectural Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `01`/`02` | `02 Onboarding — Boas-Vindas Minimalista` | 390×844 | Paged (No scroll) | 3 calm onboarding slides introducing mission & privacy |
| `03` | `03 Autenticação — Acesso Minimalista` | 390×844 | Single Viewport | Minimalist sign-in with Apple, Google, Email |
| `04a` | `04a Perfil — Nome (1/3)` | 390×844 | Single Viewport | Onboarding Step 1: Avatar, Name, Parish |
| `04b` | `04b Perfil — Regra de Vida (2/3)` | 390×844 | Single Viewport | Onboarding Step 2: 3 preset rule selectors |
| `04c` | `04c Perfil — Privacidade (3/3)` | 390×844 | Single Viewport | Onboarding Step 3: Privacy, local storage & ad model |
| `05` | `05 Hoje — Ultra Minimal` | 390×844 | Single Viewport | Today Hub: Liturgical header, central ring, Gospel/Timer links |
| `05b` | `05b Regra de Vida — Checklist` | 390×844 | Single Viewport | Daily 5-item spiritual practice checkoff screen |
| `06` | `06 Evangelho — Leitura Paginada` | 390×844 | Paged (No scroll) | Horizontal reading pages (1ª Leitura, Salmo, Evangelho) |
| `06b` | `06b Lectio Divina — Concluir` | 390×844 | Single Viewport | 4-step Lectio Divina meditation & completion trigger |
| `07` | `07 Oração — Ultra Minimal` | 390×844 | Single Viewport | Mental prayer timer countdown & eyes-closed Rosary guide |
| `08` | `08 Grupos — Ultra Minimal` | 390×844 | Single Viewport | Active groups overview & slot capacity status |
| `08b` | `08b Descobrir Desafios` | 390×844 | Single Viewport | Featured seasonal initiatives & sponsored novenas |
| `09a` | `09a Entrar com Código` | 390×844 | Modal (No scroll) | 6-digit underline PIN entry modal |
| `09b` | `09b Criar Grupo — Identidade (1/2)` | 390×844 | Modal (No scroll) | Group creation: Name, photo, fraternity vs. challenge |
| `09c` | `09c Criar Grupo — Regras (2/2)` | 390×844 | Modal (No scroll) | Group creation: Scoring mode & sharing requirements |
| `10a` | `10a Grupo — Mural` | 390×844 | Single Viewport | Community check-ins feed & fraternal reactions |
| `10b` | `10b Anjo da Guarda` | 390×844 | Single Viewport | Secret protected soul card & anonymous prayer nudge |
| `10c` | `10c Grupo — Intenções` | 390×844 | Single Viewport | Group prayer wall & "Rezei por você" counter |
| `10d` | `10d Grupo — Chat` | 390×844 | Single Viewport | Real-time chat & pinned community announcements |
| `10e` | `10 Grupo — Progresso` | 390×844 | Single Viewport | Collective goal progress bar & consistency leaderboard |
| `11a` | `11a Registro — Prática` | 390×844 | Modal (No scroll) | 8-devotion practice selector grid with confession lock |
| `11b` | `11b Registro — Fruto & Destino` | 390×844 | Modal (No scroll) | Reflection note, photo witness, and destination toggles |
| `11c` | `11c Registro — Celebração` | 390×844 | Modal (No scroll) | Ring completion animation, streak flame increment |
| `12` | `12 Meu Caminho — Ultra Minimal` | 390×844 | Single Viewport | 12-week heatmap, lifetime devotional numerals, links |
| `12b` | `12b Graça & Misericórdia` | 390×844 | Single Viewport | Streak repair & seasonal liturgical theme unlock |
| `13` | `13 Diário — Ultra Minimal` | 390×844 | Single Viewport | Monthly journal index with 5 recent entries & Face ID |
| `14` | `14 Leitura — Entrada Única` | 390×844 | Single Viewport | Immersive book serif reflection reader with day paging |
| `14_Idx` | `14 Ajustes — Índice` | 390×844 | Single Viewport | Settings directory & account deletion |
| `14a` | `14a Lembretes Litúrgicos` | 390×844 | Single Viewport | Angelus (12h/18h), Morning offering, Rosary alerts |
| `14b` | `14b Aparência & Idioma` | 390×844 | Single Viewport | Theme picker (Light/Dark/System), icons, language |
| `14c` | `14c Privacidade & Conta` | 390×844 | Single Viewport | Face ID lock toggle, encrypted backup export |
| `15` | `15 Exame da Noite — Um Passo por Tela` | 390×844 | Paged (No scroll) | 5 single-viewport examination steps |
| `16` | `16 Confissão — Um Mandamento por Tela` | 390×844 | Paged (No scroll) | 10 single-viewport commandment examination steps |
| `17` | `17 Santa Missa — Um Rito por Tela` | 390×844 | Paged (No scroll) | 6 single-viewport traditional missal rite guides |

---

## 6. Phased Implementation & Verification

1. **Phase 1 — Design System Alignment:** Verify contrast compliance for all liturgical tints against `#FAF8F5` and `#121110`.
2. **Phase 2 — Navigation Routing:** Connect all sub-screens using `Navigation` package (`Routable`, `Navigator<Route>`, `NavigationStackWrapper`).
3. **Phase 3 — Swift Testing Verification:** Ensure all screens maintain zero compiler warnings, 100% test coverage, and full VoiceOver accessibility.
