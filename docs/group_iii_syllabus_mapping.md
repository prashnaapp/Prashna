# Telangana Group-III Canonical Syllabus Mapping

Status: documentation-only. This file does **not** modify Flutter code,
Firestore, questions, progress, tests, Group-II data, or production content.

## 1. Official source

- Source file: `Group-III Scheme and Syllabus20230102131218.pdf`
  (local copy also observed as
  `Group-III Scheme and Syllabus20230102131218(2).pdf`)
- Authority: Telangana State Public Service Commission — Scheme and Syllabus
  for recruitment to the posts of Group – III Services
- Extracted pages used:
  - Page 1 — scheme of examination
  - Page 2 — Paper-I syllabus (11 numbered units)
  - Pages 3–4 — Paper-II Parts I–III
  - Pages 5–6 — Paper-III Parts I–III
- Group-II syllabus documents and Group-II app data were **not** used as a
  source for this mapping.

## 2. Group-III examination structure (official)

| Paper | Official subject | Official internal division | Questions | Duration | Marks |
|---|---|---|---:|---|---:|
| Paper-I | GENERAL STUDIES AND GENERAL ABILITIES | No Parts | 150 | 2½ hours | 150 |
| Paper-II | HISTORY, POLITY AND SOCIETY | 3 Parts × 50 | 150 | 2½ hours | 150 |
| Paper-III | ECONOMY AND DEVELOPMENT | 3 Parts × 50 | 150 | 2½ hours | 150 |

Total official marks: **450**.

Official Paper-II Parts (scheme page 1 / syllabus pages 3–4):

1. Socio-Cultural History of Telangana and Formation of Telangana State
2. Overview of the Indian Constitution and Politics
3. Social Structure, Issues and Public Policies

Official Paper-III Parts (scheme page 1 / syllabus pages 5–6):

1. Indian Economy: Issues and Challenges
2. Economy and Development of Telangana
3. Issues of Development and Change

Languages of written exam (page 1): English, Telugu and Urdu.

## 3. Locked app hierarchy

```text
COURSE = Group-III

Paper-I:
  Group-III → Paper-I → Syllabus Unit → Test → Questions

Paper-II:
  Group-III → Paper-II → Part-I / Part-II / Part-III → Syllabus Unit → Test → Questions

Paper-III:
  Group-III → Paper-III → Part-I / Part-II / Part-III → Syllabus Unit → Test → Questions
```

Hard exclusions for the APP tree:

- No Lessons level
- No Topics / Subtopics as an extra folder level below Syllabus Unit
- No “Indian Economy” folder between Part-I and a syllabus unit
- No nesting deeper than: Syllabus Unit → Test → Questions
- Part headings remain Part labels only; they are not additional folders
  under the Part

Proposed stable ID grammar (documentation only; not implemented yet):

```text
course
  group-iii
paper
  group-iii-paper-{i|ii|iii}
part
  group-iii-paper-{ii|iii}-part-{i|ii|iii}
syllabus-unit
  group-iii-paper-i-unit-{01..11}
  group-iii-paper-{ii|iii}-part-{i|ii|iii}-unit-{01..}
```

## 4. How official PDF wording becomes APP folders

| Official PDF concept | APP role |
|---|---|
| Paper title | Paper |
| Roman-numeral Part heading (Paper-II / Paper-III) | Part label only |
| Numbered syllabus item (1, 2, 3, …) | One Syllabus Unit folder (final folder before Tests) |
| Em-dash fragments inside a numbered item | Content for future Tests/Questions — **not** extra folders |
| Nested phrases under an item (e.g. “Agriculture and Allied Sectors” inside item 3) | May become the **display name** of that same numbered unit when locked by product rules; still one folder, not a child folder |

Transformation rules applied below:

1. Preserve official wording in `officialName`.
2. Use a short `displayName` only when the PDF already provides a clear lead
   title, or when this phase explicitly locks a display name.
3. Do **not** invent Test titles in this document.
4. Do **not** invent Syllabus Units that are not numbered (or otherwise
   discrete) in the PDF.

## 5. Paper-I complete mapping

Paper-I has **no Parts**.

Source: page 2 — `PAPER-I: GENERAL STUDIES AND GENERAL ABILITIES`

| # | proposed stableId | officialName (PDF) | displayName (APP folder) |
|---:|---|---|---|
| 1 | `group-iii-paper-i-unit-01` | Current Affairs – Regional, National & International. | Current Affairs – Regional, National & International |
| 2 | `group-iii-paper-i-unit-02` | International Relations and Events. | International Relations and Events |
| 3 | `group-iii-paper-i-unit-03` | General Science; India’s Achievements in Science and Technology. | General Science; India’s Achievements in Science and Technology |
| 4 | `group-iii-paper-i-unit-04` | Environmental Issues; Disaster Management- Prevention and Mitigation Strategies. | Environmental Issues; Disaster Management- Prevention and Mitigation Strategies |
| 5 | `group-iii-paper-i-unit-05` | World Geography, Indian Geography and Geography of Telangana State. | World Geography, Indian Geography and Geography of Telangana State |
| 6 | `group-iii-paper-i-unit-06` | History and Cultural Heritage of India. | History and Cultural Heritage of India |
| 7 | `group-iii-paper-i-unit-07` | Society, Culture, Heritage, Arts and Literature of Telangana. | Society, Culture, Heritage, Arts and Literature of Telangana |
| 8 | `group-iii-paper-i-unit-08` | Policies of Telangana State. | Policies of Telangana State |
| 9 | `group-iii-paper-i-unit-09` | Social Exclusion, Rights Issues and Inclusive Policies. | Social Exclusion, Rights Issues and Inclusive Policies |
| 10 | `group-iii-paper-i-unit-10` | Logical Reasoning; Analytical Ability and Data Interpretation. | Logical Reasoning; Analytical Ability and Data Interpretation |
| 11 | `group-iii-paper-i-unit-11` | Basic English. (8th Class Standard) | Basic English. (8th Class Standard) |

APP path for every Paper-I unit:

```text
Group-III → Paper-I → [Syllabus Unit] → Tests → Questions
```

Tests under these units: **not defined in the PDF** → not invented here.

## 6. Paper-II complete mapping by Part

### Part-I — Socio-Cultural History of Telangana and Formation of Telangana State

proposed partId: `group-iii-paper-ii-part-i`

| # | proposed stableId | officialName (full PDF item) | displayName (APP folder) | display note |
|---:|---|---|---|---|
| 1 | `group-iii-paper-ii-part-i-unit-01` | Satavahanas, Ikshvakus, Vishnukundins, Mudigonda and Vemulawada Chalukyas and their contribution to culture; Social and Religious conditions; Buddhism and Jainism in Ancient Telangana; Growth of Language and Literature, Art and Architecture. | Ancient Telangana Dynasties and Culture | Display compression of item 1. Full official text retained in `officialName`. |
| 2 | `group-iii-paper-ii-part-i-unit-02` | The establishment of Kakatiya kingdom and their contribution to socio-cultural development. Growth of Language and Literature under the Kakatiyas; Popular protest against Kakatiyas: Sammakka - Sarakka Revolt; Art, Architecture and Fine Arts. Rachakonda and Deverakonda Velamas, Social and Religious Conditions; Growth of Language and Literature, Socio- Cultural contribution of Qutubshahis - Growth of Language, Literature, Art, Architecture, Festivals, Dance, and Music. Emergence of Composite Culture. | Kakatiyas and Medieval Telangana | Locked display example for this phase. Not an extra hierarchy under Kakatiyas / Literature / Lessons. |
| 3 | `group-iii-paper-ii-part-i-unit-03` | Asaf Jahi Dynasty; Nizam-British Relations: Salarjung Reforms and their impact; Socio - Cultural- Religious Conditions under the Nizams: Educational Reforms, Establishment of Osmania University; Growth of Employment and the Rise of Middle Classes. | Asaf Jahi Dynasty and the Nizams | Display compression using the item’s opening official subject. |
| 4 | `group-iii-paper-ii-part-i-unit-04` | Socio-cultural and Political Awakening in Telangana: Role of Arya Samaj- Andhra Mahasabha; Andhra Saraswatha Parishat, Literary and Library movements, Adi- Hindu movement, Andhra Mahila Sabha and the growth of Women’s movement; Tribal Revolts, Ramji Gond and Kumaram Bheem, -The Telangana Peasant Armed Struggle ; Causes and Consequences. | Socio-cultural and Political Awakening in Telangana | Lead title taken from official PDF wording. |
| 5 | `group-iii-paper-ii-part-i-unit-05` | Integration of Hyderabad State into Indian Union and formation of Andhra Pradesh. Gentlemen Agreement; Mulki Movement 1952-56; Violation of Safeguards – Regional imbalances - Assertion of Telangana identity; Agitation for Separate Telangana State 1969- 70 - Growth of popular protest against discrimination and movements towards the formation of Telangana State 1971-2014. | Integration, Safeguards and Formation of Telangana State | Display compression spanning Integration → 1971–2014 formation content. Full official text retained. |

APP path:

```text
Group-III → Paper-II → Part-I → [Syllabus Unit] → Tests → Questions
```

Critical non-example (forbidden):

```text
Part-I → Kakatiyas → Language and Literature → Lessons
```

Correct for unit 2:

```text
Part-I → Kakatiyas and Medieval Telangana → Tests
```

### Part-II — Overview of the Indian Constitution and Politics

proposed partId: `group-iii-paper-ii-part-ii`

| # | proposed stableId | officialName (PDF) | displayName (APP folder) |
|---:|---|---|---|
| 1 | `group-iii-paper-ii-part-ii-unit-01` | Evolution of the Indian Constitution – Nature and salient features – Preamble. | Evolution of the Indian Constitution |
| 2 | `group-iii-paper-ii-part-ii-unit-02` | Fundamental Rights – Directive Principles of the State Policy – Fundamental Duties. | Fundamental Rights, Directive Principles and Duties |
| 3 | `group-iii-paper-ii-part-ii-unit-03` | Distinctive Features of the Indian Federalism – Distribution of Legislative, Financial and Administrative Powers between the Union and States. | Indian Federalism and Distribution of Powers |
| 4 | `group-iii-paper-ii-part-ii-unit-04` | Union and State Government – President – Prime Minister and Council of Ministers; Governor, Chief Minister and Council of Ministers – Powers and Functions. | Union and State Government |
| 5 | `group-iii-paper-ii-part-ii-unit-05` | Indian Constitution; Amendment Procedures and Amendment Acts. | Constitutional Amendments |
| 6 | `group-iii-paper-ii-part-ii-unit-06` | Rural and Urban Governance with special reference to the 73 rd and 74 th Amendment Acts. | Rural and Urban Governance |
| 7 | `group-iii-paper-ii-part-ii-unit-07` | Electoral Mechanism: Electoral Laws, Election Commission, Political Parties, Anti defection Law and Electoral Reforms. | Electoral Mechanism |
| 8 | `group-iii-paper-ii-part-ii-unit-08` | Judicial System in India – Judicial Review; Judicial Activism; Supreme Court and High Courts. | Judicial System in India |
| 9 | `group-iii-paper-ii-part-ii-unit-09` | a) Special Constitutional Provisions for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Economically Weaker Sections (EWS). b) National Commissions for the Enforcement – National Commission for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Human Rights. | Special Constitutional Provisions and National Commissions |
| 10 | `group-iii-paper-ii-part-ii-unit-10` | National Integration issues and challenges: Insurgency; Internal Security; Inter-State Disputes. | National Integration Issues and Challenges |

APP path:

```text
Group-III → Paper-II → Part-II → [Syllabus Unit] → Tests → Questions
```

### Part-III — Social Structure, Issues and Public Policies

proposed partId: `group-iii-paper-ii-part-iii`

| # | proposed stableId | officialName (PDF) | displayName (APP folder) |
|---:|---|---|---|
| 1 | `group-iii-paper-ii-part-iii-unit-01` | Indian Social Structure: Salient Features of Indian society: Family, Marriage, Kinship, Caste, Tribe, Ethnicity, Religion and Women. | Indian Social Structure |
| 2 | `group-iii-paper-ii-part-iii-unit-02` | Social Issues: Inequality and Exclusion: Casteism, Communalism, Regionalism, Violence against Women, Child Labour, Human trafficking, Disability, Aged and Third / Trans-Gender Issues. | Social Issues |
| 3 | `group-iii-paper-ii-part-iii-unit-03` | Social Movements: Peasant Movement, Tribal movement, Backward Classes Movement, Dalit Movement, Environmental Movement, Women’s Movement, Regional Autonomy Movement, Human Rights / Civil Rights Movement. | Social Movements |
| 4 | `group-iii-paper-ii-part-iii-unit-04` | Social Policies and Welfare Programmes: Affirmative Policies for SCs, STs, OBC, Women, Minorities, Labour, Disabled and Children; Welfare Programmes: Employment, Poverty Alleviation Programmes; Rural and Urban, Women and Child Welfare, Tribal Welfare. | Social Policies and Welfare Programmes |
| 5 | `group-iii-paper-ii-part-iii-unit-05` | Society in Telangana: Socio- Cultural Features and Issues in Telangana; Vetti, Jogini, Devadasi System, Child Labour, Girl Child, Flourosis, Migration, Farmer’s; Artisanal and Service Communities in Distress. | Society in Telangana |

APP path:

```text
Group-III → Paper-II → Part-III → [Syllabus Unit] → Tests → Questions
```

## 7. Paper-III complete mapping by Part

### Part-I — Indian Economy: Issues and Challenges

proposed partId: `group-iii-paper-iii-part-i`

Official Part heading (PDF): **Indian Economy: Issues and Challenges**

APP rule: this heading labels **Part-I only**. It must **not** become an
extra folder under Part-I.

| # | proposed stableId | official numbered lead (PDF) | officialName (full PDF item) | displayName (APP folder) |
|---:|---|---|---|---|
| 1 | `group-iii-paper-iii-part-i-unit-01` | Demography | Demography: Demographic Features of Indian Population – Size and Growth Rate of Population – Demographic Dividend – Sectoral Distribution of Population – Population Policies of India | Demography |
| 2 | `group-iii-paper-iii-part-i-unit-02` | National Income | National Income: Concepts & Components of National Income – Measurement Methods – National Income Estimates in India and its Trends – Sectoral Contribution – Per Capita Income | National Income |
| 3 | `group-iii-paper-iii-part-i-unit-03` | Primary and Secondary Sectors | Primary and Secondary Sectors: Agriculture and Allied Sectors – Contribution to National Income – Cropping Pattern – Agricultural Production and Productivity – Green Revelation – Irrigation – Agricultural Finance and Marketing – Agricultural Pricing – Agricultural Subsidies and Food Security – Agricultural Labour – Growth and Performance of Allied Sectors | Agriculture and Allied Sectors |
| 4 | `group-iii-paper-iii-part-i-unit-04` | Industry and Services Sectors | Industry and Services Sectors: Growth and Structure of Industry in India – Contribution to National Income – Industrial Policies – Large Scale Industries – MSMEs – Industrial Finance – Contribution of Services Sector to National Income – Importance of Services Sector – Sub Sectors of Services – Economic Infrastructure – India’s Foreign Trade | Industry and Services Sectors |
| 5 | `group-iii-paper-iii-part-i-unit-05` | Planning, NITI Aayog and Public Finance | Planning, NITI Aayog and Public Finance: Objectives of India’s Five Year Plans – Targets, Achievements and Failures of Five Year Plans – NITI Aayog – Budget in India – Concepts of Budget Deficits – FRBM – Recent Union Budgets – Public Revenue, Public Expenditure and Public Debt – Finance Commissions | Planning, NITI Aayog and Public Finance |

Locked unit-3 path:

```text
Group-III → Paper-III → Part-I → Agriculture and Allied Sectors → Tests → Questions
```

Forbidden:

```text
Group-III → Paper-III → Part-I → Indian Economy → Agriculture and Allied Sectors
Group-III → Paper-III → Part-I → Primary and Secondary Sectors → Agriculture and Allied Sectors
```

Notes for unit 3:

- The PDF numbers this item as **“Primary and Secondary Sectors”** and then
  immediately continues with **“Agriculture and Allied Sectors – …”**.
- This mapping keeps **one** APP folder for that numbered item.
- The locked APP `displayName` is **Agriculture and Allied Sectors**.
- The full official numbered wording remains in `officialName`.
- “Primary and Secondary Sectors” is **not** retained as a separate nested
  folder.

### Part-II — Economy and Development of Telangana

proposed partId: `group-iii-paper-iii-part-ii`

| # | proposed stableId | officialName (PDF) | displayName (APP folder) |
|---:|---|---|---|
| 1 | `group-iii-paper-iii-part-ii-unit-01` | Structure and Growth of Telangana Economy: Telangana Economy in Undivided Andhra Pradesh (1956-2014) – State Finances ( Dhar Commission, Wanchu Committee, Lalit Committee, Bhargava Committee) – Land Reforms - Growth and Development of Telangana Economy Since 2014 – Sectoral Contribution to State Income – Per Capita Income | Structure and Growth of Telangana Economy |
| 2 | `group-iii-paper-iii-part-ii-unit-02` | Demography and HRD: Size and Growth Rate of Population – Demographic Features of Telangana Economy – Age Structure of Population – Demographic Dividend. | Demography and HRD |
| 3 | `group-iii-paper-iii-part-ii-unit-03` | Agriculture and Allied Sectors: Importance of Agriculture – Trends in Growth Rate of Agriculture – Contribution of Agriculture and Allied Sectors to GSDP/GSVA – Land Use and Land Holdings Pattern – Cropping Pattern – Irrigation – Growth and Development of Allied Sectors – Agricultural Policies and Programmes | Agriculture and Allied Sectors |
| 4 | `group-iii-paper-iii-part-ii-unit-04` | Industry and Service Sectors: Structure and Growth of Industry – Contribution of Industry to GSDP/GSVA – MSME – Industrial Policies – Components, Structure and Growth of Services Sector – Its Contribution to GSDP/GSVA – Social and Economic Infrastructure | Industry and Service Sectors |
| 5 | `group-iii-paper-iii-part-ii-unit-05` | State Finances, Budget and Welfare Policies: State Revenue, Expenditure and Debt – State Budgets – Welfare Policies of the State | State Finances, Budget and Welfare Policies |

APP path:

```text
Group-III → Paper-III → Part-II → [Syllabus Unit] → Tests → Questions
```

### Part-III — Issues of Development and Change

proposed partId: `group-iii-paper-iii-part-iii`

| # | proposed stableId | officialName (PDF) | displayName (APP folder) |
|---:|---|---|---|
| 1 | `group-iii-paper-iii-part-iii-unit-01` | Growth and Development: Concepts of Growth and Development – Characteristics of Development and Underdevelopment – Measurement of Economic Growth and Development – Human Development – Human Development Indices – Human Development Reports | Growth and Development |
| 2 | `group-iii-paper-iii-part-iii-unit-02` | Social Development: Social Infrastructure – Health and Education – Social Sector – Social Inequalities – Caste – Gender – Religion – Social Transformation – Social Security | Social Development |
| 3 | `group-iii-paper-iii-part-iii-unit-03` | Poverty and Unemployment: Concepts of Poverty – Measurement of Poverty – Income Inequalities - Concepts of Unemployment – Poverty, Unemployment and Welfare Programmes | Poverty and Unemployment |
| 4 | `group-iii-paper-iii-part-iii-unit-04` | Regional Inequalities: Urbanization – Migration – Land Acquisition – Resettlement and Rehabilitation | Regional Inequalities |
| 5 | `group-iii-paper-iii-part-iii-unit-05` | Environment and Sustainable Development: Concepts of Environment – Environmental Protection and Sustainable Development – Types of Pollution – Pollution Control – Effects of Environment – Environmental Policies of India | Environment and Sustainable Development |

APP path:

```text
Group-III → Paper-III → Part-III → [Syllabus Unit] → Tests → Questions
```

## 8. Coverage counts

| Area | Official numbered items | Mapped APP Syllabus Units | Nested folders added | Lessons invented |
|---|---:|---:|---:|---:|
| Paper-I | 11 | 11 | 0 | 0 |
| Paper-II Part-I | 5 | 5 | 0 | 0 |
| Paper-II Part-II | 10 | 10 | 0 | 0 |
| Paper-II Part-III | 5 | 5 | 0 | 0 |
| Paper-III Part-I | 5 | 5 | 0 | 0 |
| Paper-III Part-II | 5 | 5 | 0 | 0 |
| Paper-III Part-III | 5 | 5 | 0 | 0 |
| **Total** | **46** | **46** | **0** | **0** |

## 9. Ambiguous / not invented

The following are **explicitly not invented** in this phase:

1. **Test names / Test counts**  
   The PDF defines papers, parts, and syllabus content. It does **not** define
   app Test titles such as “Test 1”, “Establishment of Kakatiya Kingdom”, or
   “30 Questions”. Those remain for a later content/test-authoring phase.

2. **Lesson / subtopic folders**  
   Em-dash fragments inside a numbered syllabus item are content fragments,
   not additional APP folders.

3. **Indian Economy as an APP folder**  
   Rejected. It is the official Paper-III Part-I heading only.

4. **Primary and Secondary Sectors as a parent folder above Agriculture and Allied Sectors**  
   Rejected. Paper-III Part-I unit 3 remains one folder; locked display name is
   Agriculture and Allied Sectors.

5. **Paper-II Part-I short titles for units 1, 3, and 5**  
   The PDF gives long paragraphs without separate short titles. The
   `displayName` values above are **UI compressions** of official content:
   - unit 1 → Ancient Telangana Dynasties and Culture
   - unit 3 → Asaf Jahi Dynasty and the Nizams
   - unit 5 → Integration, Safeguards and Formation of Telangana State  
   If product owners prefer different short labels, only `displayName` should
   change; the numbered official text must stay.

6. **Paper-II Part-II units 1–3, 5, 9 display shortenings**  
   Lead phrases were shortened for folder labels; full PDF wording remains in
   `officialName`.

7. **Whether Paper-III Part-I unit 3 should keep “Primary and Secondary Sectors” as displayName instead**  
   Locked for the APP as **Agriculture and Allied Sectors** by this phase.
   Reopening that choice is a product decision, not something this mapping
   invents further.

8. **Spelling / punctuation as printed**  
   PDF forms such as `Green Revelation`, `Flourosis`, `Stra tegies` line
   wraps, and spaced words were normalized only where extraction clearly
   split a single official word. Meaning was not changed.

9. **Group-II reuse**  
   No Group-II IDs, lessons, or topic trees were copied into this mapping.

## 10. Boundary status before implementation

Safe to implement later from this document:

- Paper IDs and titles
- Part IDs and Part labels for Papers II–III
- Paper-I’s 11 syllabus units
- Paper-II / Paper-III syllabus-unit counts and official text
- Locked Paper-III Part-I path ending at Agriculture and Allied Sectors

Requires human confirmation before coding:

- Final `displayName` wording for Paper-II Part-I units 1, 3, and 5
- Whether any Paper-II Part-II display shortenings should instead use the full
  official sentence as the visible folder title
- Future Test naming under each Syllabus Unit

## Phase 5.22V result

- Files changed: `docs/group_iii_syllabus_mapping.md` only
- Flutter / Dart implementation: no
- Group-II data: unchanged
- Firestore: unchanged
- Tests / analyzer / deploy: not run for this documentation-only phase
- Production data: not created
