# Telangana Group-II Canonical Syllabus Mapping

Status: documentation-only, proposed canonical IDs. This file does not modify
Flutter code, Firestore, questions, progress, tests, or production data.

## Source and representation rules

- Source: `APQV85-Group-II Scheme and Syllabus20221230143844.pdf`
- Source authority: Telangana State Public Service Commission Group-II Scheme
  and Syllabus PDF.
- The official source uses Paper, Section, and numbered Topic terminology.
- `Lesson` is an application decomposition of an explicitly listed source
  item. Lesson numbering is not government numbering.
- Every lesson below has `sourceType: application_decomposition`.
- `officialName` preserves the source wording, including the source typo
  `Green Revelation`.
- `displayName` is UI-only and may be shorter.
- `stableId` is proposed only. Existing production IDs are not changed.
- No topic-wise marks or study weights are assigned.

## Proposed stable ID grammar

```text
course
  group-ii
paper
  group-ii-paper-{i|ii|iii|iv}
section
  group-ii-paper-{paper}-section-{01|02|03}
topic
  group-ii-paper-{paper}-topic-{01..11}                 # Paper I
  group-ii-paper-{paper}-section-{01..03}-topic-{01..10}
lesson
  {topic-stableId}-lesson-{01..nn}
```

Paper I has no Section. Papers II–IV have three Sections each. Numeric
components are contextual and zero-padded; `topic-01` is not a global identity.

## Official exam structure

| Paper | officialName | official structure |
|---|---|---|
| Paper I | General Studies and General Abilities | 150 marks |
| Paper II | History, Polity and Society | 3 Sections × 50 marks |
| Paper III | Economy and Development | 3 Sections × 50 marks |
| Paper IV | Telangana Movement and State Formation | 3 Sections × 50 marks |

Total official marks: 600. These marks are recorded only as exam structure;
they are not allocated to Topics or Lessons.

## Paper I — General Studies and General Abilities

Paper I has no artificial Section. The following are the 11 official Topics.
No application Lessons are introduced because the source lists these as
top-level items without a separately detailed lesson paragraph.

| stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-i-topic-01` | Current Affairs – Regional, National & International. | Current Affairs |
| `group-ii-paper-i-topic-02` | International Relations and Events. | International Relations |
| `group-ii-paper-i-topic-03` | General Science; India’s Achievements in Science and Technology | General Science and Technology |
| `group-ii-paper-i-topic-04` | Environmental Issues; Disaster Management - Prevention and Mitigation Strategies. | Environment and Disaster Management |
| `group-ii-paper-i-topic-05` | World Geography, Indian Geography and Geography of Telangana State. | Geography |
| `group-ii-paper-i-topic-06` | History and Cultural Heritage of India. | Indian History and Heritage |
| `group-ii-paper-i-topic-07` | Society, Culture, Heritage, Arts and Literature of Telangana. | Telangana Society and Culture |
| `group-ii-paper-i-topic-08` | Policies of Telangana State. | Telangana State Policies |
| `group-ii-paper-i-topic-09` | Social Exclusion, Rights Issues and Inclusive Policies. | Social Inclusion and Rights |
| `group-ii-paper-i-topic-10` | Logical Reasoning; Analytical Ability and Data Interpretation. | Reasoning and Data Interpretation |
| `group-ii-paper-i-topic-11` | Basic English. ( 10th Class Standard) | Basic English |

## Paper II — History, Polity and Society

### Section I — Socio-Cultural History of India and Telangana

Section stable ID: `group-ii-paper-ii-section-01`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-ii-section-01-topic-01` | Salient features of Indus Valley Civilization: Society and Culture. -Early and Later Vedic Culture; Religious Movements in Sixth Century B.C. – Jainism and Buddhism. Socio, Cultural and Economic Contribution during Mauryas, Guptas, Pallavas, Chalukyas and Cholas – Administrative System. Art and Architecture - Harsha and the Rajput Age. | Ancient India and Early Empires |
| `group-ii-paper-ii-section-01-topic-02` | The Establishment of Delhi Sultanate-Socio-Economic, Cultural Conditions and Administrative System under the Sultanate –Sufi and Bhakti Movements. The Mughals: Socio-Economic and Cultural Conditions; Language, Literature, Art and Architecture. Rise of Marathas and their contribution to Culture; Socio-Economic, Cultural conditions in the Deccan under the Bahamani’s and Vijayanagara -Literature, Art and Architecture. | Medieval India |
| `group-ii-paper-ii-section-01-topic-03` | Advent of Europeans: Rise and Expansion of British Rule: Socio-Economic and Cultural Policies - Cornwallis, Wellesley, William Bentinck, Dalhousie and others. The Rise of Socio-Religious Reform Movements in the Nineteenth Century. Social Protest Movements in India –Jotiba and Savithribai Phule, Ayyankali, Narayana Guru, Periyar Ramaswamy Naicker, Gandhi, Ambedkar etc. Indian Freedom Movement – 1885-1947. | Colonial Rule and Freedom Movement |
| `group-ii-paper-ii-section-01-topic-04` | Socio-Economic and Cultural conditions in Ancient Telangana Satavahanas, Ikshvakus, Vishnukundins, Mudigonda and Vemulawada Chalukyas. Religion, Language, Literature, Art and Architecture; Medieval Telangana - Contribution of Kakatiyas, Rachakonda and Devarakonda Velamas, Qutub Shahis; Socio – Economic and Cultural developments: Emergence of Composite Culture. Fairs, Festivals, Moharram, Urs, Jataras etc. | Ancient and Medieval Telangana |
| `group-ii-paper-ii-section-01-topic-05` | Foundation of AsafJahi Dynasty- from Nizam –ul- Mulk to Mir Osaman Ali Khan - SalarJung Reforms; Social and Economic conditions-Jagirdars, Zamindars, Deshmuks, and Doras- Vetti and Bhagela system and position of Women. Rise of Socio-Cultural Movements in Telangana: Arya Samaj, Andhra Maha Sabha, Andhra Mahila Sabha, Adi-Hindu Movements, Literary and Library Movements. Tribal and Peasant Revolts: Ramji Gond, Kumaram Bheemu, and Telangana Peasant Armed Struggle – Police Action and the End of Nizam Rule. | Asaf Jahi Telangana |

All rows below use `sourceType: application_decomposition`.

In the lesson ledgers, `...topic-01-lesson-01` is compact notation for the
full stable ID of the Topic currently being listed, followed by
`-lesson-01`. For example, under Paper II Section I Topic 1 it expands to
`group-ii-paper-ii-section-01-topic-01-lesson-01`. The notation is not a
separate ID and cannot collide across Sections.

#### Topic 01 lessons

- `...topic-01-lesson-01` — officialName: `Salient features of Indus Valley Civilization: Society and Culture.` — displayName: Indus Valley Society and Culture
- `...topic-01-lesson-02` — officialName: `Early and Later Vedic Culture` — displayName: Vedic Culture
- `...topic-01-lesson-03` — officialName: `Religious Movements in Sixth Century B.C.` — displayName: Religious Movements
- `...topic-01-lesson-04` — officialName: `Jainism and Buddhism.` — displayName: Jainism and Buddhism
- `...topic-01-lesson-05` — officialName: `Socio, Cultural and Economic Contribution during Mauryas` — displayName: Mauryan Contributions
- `...topic-01-lesson-06` — officialName: `Guptas` — displayName: Gupta Contributions
- `...topic-01-lesson-07` — officialName: `Pallavas` — displayName: Pallava Contributions
- `...topic-01-lesson-08` — officialName: `Chalukyas` — displayName: Chalukya Contributions
- `...topic-01-lesson-09` — officialName: `Cholas` — displayName: Chola Contributions
- `...topic-01-lesson-10` — officialName: `Administrative System.` — displayName: Administrative Systems
- `...topic-01-lesson-11` — officialName: `Art and Architecture` — displayName: Art and Architecture
- `...topic-01-lesson-12` — officialName: `Harsha and the Rajput Age.` — displayName: Harsha and Rajput Age

#### Topic 02 lessons

- `...topic-02-lesson-01` — officialName: `The Establishment of Delhi Sultanate` — displayName: Delhi Sultanate
- `...topic-02-lesson-02` — officialName: `Socio-Economic, Cultural Conditions and Administrative System under the Sultanate` — displayName: Sultanate Society and Administration
- `...topic-02-lesson-03` — officialName: `Sufi and Bhakti Movements.` — displayName: Sufi and Bhakti Movements
- `...topic-02-lesson-04` — officialName: `The Mughals: Socio-Economic and Cultural Conditions` — displayName: Mughal Society and Culture
- `...topic-02-lesson-05` — officialName: `Language, Literature, Art and Architecture.` — displayName: Mughal Language, Literature and Arts
- `...topic-02-lesson-06` — officialName: `Rise of Marathas and their contribution to Culture` — displayName: Marathas and Culture
- `...topic-02-lesson-07` — officialName: `Socio-Economic, Cultural conditions in the Deccan under the Bahamani’s and Vijayanagara` — displayName: Bahamani and Vijayanagara Deccan
- `...topic-02-lesson-08` — officialName: `Literature, Art and Architecture.` — displayName: Deccan Literature, Art and Architecture

#### Topic 03 lessons

- `...topic-03-lesson-01` — officialName: `Advent of Europeans` — displayName: European Advent
- `...topic-03-lesson-02` — officialName: `Rise and Expansion of British Rule` — displayName: British Rule
- `...topic-03-lesson-03` — officialName: `Socio-Economic and Cultural Policies` — displayName: British Socio-Economic Policies
- `...topic-03-lesson-04` — officialName: `Cornwallis` — displayName: Cornwallis
- `...topic-03-lesson-05` — officialName: `Wellesley` — displayName: Wellesley
- `...topic-03-lesson-06` — officialName: `William Bentinck` — displayName: William Bentinck
- `...topic-03-lesson-07` — officialName: `Dalhousie and others` — displayName: Dalhousie and Others
- `...topic-03-lesson-08` — officialName: `The Rise of Socio-Religious Reform Movements in the Nineteenth Century.` — displayName: Socio-Religious Reform
- `...topic-03-lesson-09` — officialName: `Social Protest Movements in India` — displayName: Social Protest Movements
- `...topic-03-lesson-10` — officialName: `Jotiba and Savithribai Phule` — displayName: Phule Reformers
- `...topic-03-lesson-11` — officialName: `Ayyankali` — displayName: Ayyankali
- `...topic-03-lesson-12` — officialName: `Narayana Guru` — displayName: Narayana Guru
- `...topic-03-lesson-13` — officialName: `Periyar Ramaswamy Naicker` — displayName: Periyar Ramaswamy Naicker
- `...topic-03-lesson-14` — officialName: `Gandhi` — displayName: Gandhi
- `...topic-03-lesson-15` — officialName: `Ambedkar etc.` — displayName: Ambedkar and Others
- `...topic-03-lesson-16` — officialName: `Indian Freedom Movement – 1885-1947.` — displayName: Indian Freedom Movement

#### Topic 04 lessons

- `...topic-04-lesson-01` — officialName: `Socio-Economic and Cultural conditions in Ancient Telangana` — displayName: Ancient Telangana Society
- `...topic-04-lesson-02` — officialName: `Satavahanas` — displayName: Satavahanas
- `...topic-04-lesson-03` — officialName: `Ikshvakus` — displayName: Ikshvakus
- `...topic-04-lesson-04` — officialName: `Vishnukundins` — displayName: Vishnukundins
- `...topic-04-lesson-05` — officialName: `Mudigonda and Vemulawada Chalukyas` — displayName: Telangana Chalukyas
- `...topic-04-lesson-06` — officialName: `Religion` — displayName: Religion
- `...topic-04-lesson-07` — officialName: `Language` — displayName: Language
- `...topic-04-lesson-08` — officialName: `Literature` — displayName: Literature
- `...topic-04-lesson-09` — officialName: `Art and Architecture` — displayName: Art and Architecture
- `...topic-04-lesson-10` — officialName: `Medieval Telangana` — displayName: Medieval Telangana
- `...topic-04-lesson-11` — officialName: `Contribution of Kakatiyas` — displayName: Kakatiyas
- `...topic-04-lesson-12` — officialName: `Rachakonda and Devarakonda Velamas` — displayName: Rachakonda and Devarakonda Velamas
- `...topic-04-lesson-13` — officialName: `Qutub Shahis` — displayName: Qutub Shahis
- `...topic-04-lesson-14` — officialName: `Socio – Economic and Cultural developments` — displayName: Socio-Economic and Cultural Development
- `...topic-04-lesson-15` — officialName: `Emergence of Composite Culture` — displayName: Composite Culture
- `...topic-04-lesson-16` — officialName: `Fairs` — displayName: Fairs
- `...topic-04-lesson-17` — officialName: `Festivals` — displayName: Festivals
- `...topic-04-lesson-18` — officialName: `Moharram` — displayName: Moharram
- `...topic-04-lesson-19` — officialName: `Urs` — displayName: Urs
- `...topic-04-lesson-20` — officialName: `Jataras etc.` — displayName: Jataras and Others

#### Topic 05 lessons

- `...topic-05-lesson-01` — officialName: `Foundation of AsafJahi Dynasty` — displayName: Asaf Jahi Dynasty
- `...topic-05-lesson-02` — officialName: `from Nizam –ul- Mulk to Mir Osaman Ali Khan` — displayName: Nizam-ul-Mulk to Mir Osman Ali Khan
- `...topic-05-lesson-03` — officialName: `SalarJung Reforms` — displayName: Salar Jung Reforms
- `...topic-05-lesson-04` — officialName: `Social and Economic conditions` — displayName: Social and Economic Conditions
- `...topic-05-lesson-05` — officialName: `Jagirdars` — displayName: Jagirdars
- `...topic-05-lesson-06` — officialName: `Zamindars` — displayName: Zamindars
- `...topic-05-lesson-07` — officialName: `Deshmuks` — displayName: Deshmuks
- `...topic-05-lesson-08` — officialName: `Doras` — displayName: Doras
- `...topic-05-lesson-09` — officialName: `Vetti and Bhagela system` — displayName: Vetti and Bhagela
- `...topic-05-lesson-10` — officialName: `position of Women` — displayName: Women
- `...topic-05-lesson-11` — officialName: `Rise of Socio-Cultural Movements in Telangana` — displayName: Telangana Socio-Cultural Movements
- `...topic-05-lesson-12` — officialName: `Arya Samaj` — displayName: Arya Samaj
- `...topic-05-lesson-13` — officialName: `Andhra Maha Sabha` — displayName: Andhra Maha Sabha
- `...topic-05-lesson-14` — officialName: `Andhra Mahila Sabha` — displayName: Andhra Mahila Sabha
- `...topic-05-lesson-15` — officialName: `Adi-Hindu Movements` — displayName: Adi-Hindu Movements
- `...topic-05-lesson-16` — officialName: `Literary and Library Movements` — displayName: Literary and Library Movements
- `...topic-05-lesson-17` — officialName: `Tribal and Peasant Revolts` — displayName: Tribal and Peasant Revolts
- `...topic-05-lesson-18` — officialName: `Ramji Gond` — displayName: Ramji Gond
- `...topic-05-lesson-19` — officialName: `Kumaram Bheemu` — displayName: Kumaram Bheemu
- `...topic-05-lesson-20` — officialName: `Telangana Peasant Armed Struggle` — displayName: Telangana Peasant Armed Struggle
- `...topic-05-lesson-21` — officialName: `Police Action` — displayName: Police Action
- `...topic-05-lesson-22` — officialName: `the End of Nizam Rule` — displayName: End of Nizam Rule

### Section II — Overview of the Indian Constitution and Politics

Section stable ID: `group-ii-paper-ii-section-02`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-ii-section-02-topic-01` | Evolution of the Indian Constitution – Nature and salient features – Preamble. | Evolution and Features |
| `group-ii-paper-ii-section-02-topic-02` | Fundamental Rights – Directive Principles of the State Policy – Fundamental Duties. | Rights, Principles and Duties |
| `group-ii-paper-ii-section-02-topic-03` | Distinctive Features of the Indian Federalism – Distribution of Legislative, Financial and Administrative Powers between the Union and States. | Indian Federalism |
| `group-ii-paper-ii-section-02-topic-04` | Union and State Government – President – Prime Minister and Council of Ministers; Governor, Chief Minister and Council of Ministers – Powers and Functions. | Union and State Government |
| `group-ii-paper-ii-section-02-topic-05` | Indian Constitution; Amendment Procedures and Amendment Acts. | Constitutional Amendments |
| `group-ii-paper-ii-section-02-topic-06` | Rural and Urban Governance with special reference to the 73 rd th and 74 Amendment Acts. | Rural and Urban Governance |
| `group-ii-paper-ii-section-02-topic-07` | Electoral Mechanism: Electoral Laws, Election Commission, Political Parties, Anti defection Law and Electoral Reforms. | Electoral Mechanism |
| `group-ii-paper-ii-section-02-topic-08` | Judicial System in India – Judicial Review; Judicial Activism; Supreme Court and High Courts. | Judicial System |
| `group-ii-paper-ii-section-02-topic-09` | a) Special Constitutional Provisions for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Economically Weaker Sections (EWS). b) National Commissions for the Enforcement – National Commission for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Human Rights. | Special Provisions and Commissions |
| `group-ii-paper-ii-section-02-topic-10` | National Integration issues and challenges: Insurgency; Internal Security; Inter-State Disputes. | National Integration |

#### Section II lesson ledger

Each entry below is `stableId — officialName — displayName`; all have
`sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Evolution of the Indian Constitution — Constitutional Evolution; `...lesson-02` — Nature and salient features — Nature and Features; `...lesson-03` — Preamble — Preamble.
- Topic 02: `...lesson-01` — Fundamental Rights — Fundamental Rights; `...lesson-02` — Directive Principles of the State Policy — Directive Principles; `...lesson-03` — Fundamental Duties — Fundamental Duties.
- Topic 03: `...lesson-01` — Distinctive Features of the Indian Federalism — Federal Features; `...lesson-02` — Distribution of Legislative Powers between the Union and States — Legislative Powers; `...lesson-03` — Distribution of Financial and Administrative Powers between the Union and States — Financial and Administrative Powers.
- Topic 04: `...lesson-01` — President — President; `...lesson-02` — Prime Minister and Council of Ministers — Prime Minister and Council; `...lesson-03` — Governor — Governor; `...lesson-04` — Chief Minister and Council of Ministers — Chief Minister and Council; `...lesson-05` — Powers and Functions — Powers and Functions.
- Topic 05: `...lesson-01` — Indian Constitution — Indian Constitution; `...lesson-02` — Amendment Procedures — Amendment Procedures; `...lesson-03` — Amendment Acts — Amendment Acts.
- Topic 06: `...lesson-01` — Rural and Urban Governance — Local Governance; `...lesson-02` — 73 rd Amendment Acts — 73rd Amendment; `...lesson-03` — 74 Amendment Acts — 74th Amendment.
- Topic 07: `...lesson-01` — Electoral Mechanism — Electoral Mechanism; `...lesson-02` — Electoral Laws — Electoral Laws; `...lesson-03` — Election Commission — Election Commission; `...lesson-04` — Political Parties — Political Parties; `...lesson-05` — Anti defection Law — Anti-Defection Law; `...lesson-06` — Electoral Reforms — Electoral Reforms.
- Topic 08: `...lesson-01` — Judicial System in India — Judicial System; `...lesson-02` — Judicial Review — Judicial Review; `...lesson-03` — Judicial Activism — Judicial Activism; `...lesson-04` — Supreme Court and High Courts — Supreme Court and High Courts.
- Topic 09: `...lesson-01` — Special Constitutional Provisions for Scheduled Castes — Scheduled Castes; `...lesson-02` — Scheduled Tribes — Scheduled Tribes; `...lesson-03` — Backward Classes — Backward Classes; `...lesson-04` — Women — Women; `...lesson-05` — Minorities — Minorities; `...lesson-06` — Economically Weaker Sections (EWS) — EWS; `...lesson-07` — National Commission for Scheduled Castes — NCSC; `...lesson-08` — National Commission for Scheduled Tribes — NCST; `...lesson-09` — National Commission for Backward Classes — NCBC; `...lesson-10` — National Commission for Women — NCW; `...lesson-11` — National Commission for Minorities — NCM; `...lesson-12` — National Human Rights Commission — NHRC.
- Topic 10: `...lesson-01` — National Integration issues and challenges — Integration Issues; `...lesson-02` — Insurgency — Insurgency; `...lesson-03` — Internal Security — Internal Security; `...lesson-04` — Inter-State Disputes — Inter-State Disputes.

### Section III — Social Structure, Issues and Public Policies

Section stable ID: `group-ii-paper-ii-section-03`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-ii-section-03-topic-01` | Indian Social Structure: Salient Features of Indian society: Family, Marriage, Kinship, Caste, Tribe, Ethnicity, Religion and Women. | Indian Social Structure |
| `group-ii-paper-ii-section-03-topic-02` | Social Issues: Inequality and Exclusion: Casteism, Communalism, Regionalism, Violence against Women, Child Labour, Human trafficking, Disability, Aged and Third / Trans-Gender Issues. | Social Issues |
| `group-ii-paper-ii-section-03-topic-03` | Social Movements: Peasant Movement, Tribal movement, Backward Classes Movement, Dalit Movement, Environmental Movement, Women’s Movement, Regional Autonomy Movement, Human Rights / Civil Rights Movement. | Social Movements |
| `group-ii-paper-ii-section-03-topic-04` | Social Policies and Welfare Programmes: Affirmative Policies for SCs, STs, OBC, Women, Minorities, Labour, Disabled and Children; Welfare Programmes: Employment, Poverty Alleviation Programmes; Rural and Urban, Women and Child Welfare, Tribal Welfare. | Social Policies and Welfare |
| `group-ii-paper-ii-section-03-topic-05` | Society in Telangana: Socio- Cultural Features and Issues in Telangana; Vetti, Jogini, Devadasi System, Child Labour, Girl Child, Flourosis, Migration, Farmer’s; Artisanal and Service Communities in Distress. | Society in Telangana |

#### Section III lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Family — Family; `...lesson-02` — Marriage — Marriage; `...lesson-03` — Kinship — Kinship; `...lesson-04` — Caste — Caste; `...lesson-05` — Tribe — Tribe; `...lesson-06` — Ethnicity — Ethnicity; `...lesson-07` — Religion — Religion; `...lesson-08` — Women — Women.
- Topic 02: `...lesson-01` — Inequality and Exclusion — Inequality and Exclusion; `...lesson-02` — Casteism — Casteism; `...lesson-03` — Communalism — Communalism; `...lesson-04` — Regionalism — Regionalism; `...lesson-05` — Violence against Women — Violence against Women; `...lesson-06` — Child Labour — Child Labour; `...lesson-07` — Human trafficking — Human Trafficking; `...lesson-08` — Disability — Disability; `...lesson-09` — Aged — Aged; `...lesson-10` — Third / Trans-Gender Issues — Third / Trans-Gender Issues.
- Topic 03: `...lesson-01` — Peasant Movement — Peasant Movement; `...lesson-02` — Tribal movement — Tribal Movement; `...lesson-03` — Backward Classes Movement — Backward Classes Movement; `...lesson-04` — Dalit Movement — Dalit Movement; `...lesson-05` — Environmental Movement — Environmental Movement; `...lesson-06` — Women’s Movement — Women’s Movement; `...lesson-07` — Regional Autonomy Movement — Regional Autonomy Movement; `...lesson-08` — Human Rights / Civil Rights Movement — Human and Civil Rights.
- Topic 04: `...lesson-01` — Affirmative Policies for SCs — SC Policies; `...lesson-02` — ST — ST Policies; `...lesson-03` — OBC — OBC Policies; `...lesson-04` — Women — Women’s Policies; `...lesson-05` — Minorities — Minority Policies; `...lesson-06` — Labour — Labour Policies; `...lesson-07` — Disabled — Disability Policies; `...lesson-08` — Children — Children’s Policies; `...lesson-09` — Employment — Employment Programmes; `...lesson-10` — Poverty Alleviation Programmes — Poverty Alleviation; `...lesson-11` — Rural and Urban — Rural and Urban Welfare; `...lesson-12` — Women and Child Welfare — Women and Child Welfare; `...lesson-13` — Tribal Welfare — Tribal Welfare.
- Topic 05: `...lesson-01` — Socio- Cultural Features and Issues in Telangana — Telangana Socio-Cultural Features; `...lesson-02` — Vetti — Vetti; `...lesson-03` — Jogini — Jogini; `...lesson-04` — Devadasi System — Devadasi System; `...lesson-05` — Child Labour — Child Labour; `...lesson-06` — Girl Child — Girl Child; `...lesson-07` — Flourosis — Flourosis; `...lesson-08` — Migration — Migration; `...lesson-09` — Farmer’s — Farmers in Distress; `...lesson-10` — Artisanal and Service Communities in Distress — Artisanal and Service Communities.

## Paper III — Economy and Development

### Section I — Indian Economy: Issues and Challenges

Section stable ID: `group-ii-paper-iii-section-01`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iii-section-01-topic-01` | Demography: Demographic Features of Indian Population – Size and Growth Rate of Population – Demographic Dividend – Sectoral Distribution of Population – Population Policies of India | Demography |
| `group-ii-paper-iii-section-01-topic-02` | National Income: Concepts & Components of National Income – Measurement Methods – National Income Estimates in India and its Trends – Sectoral Contribution – Per Capita Income | National Income |
| `group-ii-paper-iii-section-01-topic-03` | Primary and Secondary Sectors: Agriculture and Allied Sectors – Contribution to National Income – Cropping Pattern – Agricultural Production and Productivity – Green Revelation – Irrigation – Agricultural Finance and Marketing – Agricultural Pricing – Agricultural Subsidies and Food Security – Agricultural Labour – Growth and Performance of Allied Sectors | Primary and Secondary Sectors |
| `group-ii-paper-iii-section-01-topic-04` | Industry and Services Sectors: Growth and Structure of Industry in India – Contribution to National Income –Industrial Policies – Large Scale Industries – MSMEs – Industrial Finance – Contribution of Services Sector to National Income – Importance of Services Sector – Sub Sectors of Services – Economic Infrastructure – India’s Foreign Trade | Industry and Services |
| `group-ii-paper-iii-section-01-topic-05` | Planning, NITI Aayog and Public Finance: Objectives of India’s Five Year Plans – Targets, Achievements and Failures of Five Year Plans – NITI Aayog – Budget in India – Concepts of Budget Deficits – FRBM – Recent Union Budgets – Public Revenue, Public Expenditure and Public Debt – Finance Commissions | Planning and Public Finance |

#### Section I lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Demographic Features of Indian Population — Indian Population; `...lesson-02` — Size and Growth Rate of Population — Population Size and Growth; `...lesson-03` — Demographic Dividend — Demographic Dividend; `...lesson-04` — Sectoral Distribution of Population — Population Distribution; `...lesson-05` — Population Policies of India — Population Policies.
- Topic 02: `...lesson-01` — Concepts & Components of National Income — Concepts and Components; `...lesson-02` — Measurement Methods — Measurement Methods; `...lesson-03` — National Income Estimates in India and its Trends — Estimates and Trends; `...lesson-04` — Sectoral Contribution — Sectoral Contribution; `...lesson-05` — Per Capita Income — Per Capita Income.
- Topic 03: `...lesson-01` — Agriculture and Allied Sectors — Agriculture and Allied Sectors; `...lesson-02` — Contribution to National Income — National Income Contribution; `...lesson-03` — Cropping Pattern — Cropping Pattern; `...lesson-04` — Agricultural Production and Productivity — Agricultural Production and Productivity; `...lesson-05` — Green Revelation — Green Revelation; `...lesson-06` — Irrigation — Irrigation; `...lesson-07` — Agricultural Finance and Marketing — Agricultural Finance and Marketing; `...lesson-08` — Agricultural Pricing — Agricultural Pricing; `...lesson-09` — Agricultural Subsidies and Food Security — Subsidies and Food Security; `...lesson-10` — Agricultural Labour — Agricultural Labour; `...lesson-11` — Growth and Performance of Allied Sectors — Allied Sector Performance.
- Topic 04: `...lesson-01` — Growth and Structure of Industry in India — Industry Growth and Structure; `...lesson-02` — Contribution to National Income — Industry National Income Contribution; `...lesson-03` — Industrial Policies — Industrial Policies; `...lesson-04` — Large Scale Industries — Large-Scale Industries; `...lesson-05` — MSMEs — MSMEs; `...lesson-06` — Industrial Finance — Industrial Finance; `...lesson-07` — Contribution of Services Sector to National Income — Services National Income Contribution; `...lesson-08` — Importance of Services Sector — Services Importance; `...lesson-09` — Sub Sectors of Services — Services Subsectors; `...lesson-10` — Economic Infrastructure — Economic Infrastructure; `...lesson-11` — India’s Foreign Trade — Foreign Trade.
- Topic 05: `...lesson-01` — Objectives of India’s Five Year Plans — Plan Objectives; `...lesson-02` — Targets — Plan Targets; `...lesson-03` — Achievements — Plan Achievements; `...lesson-04` — Failures of Five Year Plans — Plan Failures; `...lesson-05` — NITI Aayog — NITI Aayog; `...lesson-06` — Budget in India — Indian Budget; `...lesson-07` — Concepts of Budget Deficits — Budget Deficits; `...lesson-08` — FRBM — FRBM; `...lesson-09` — Recent Union Budgets — Recent Union Budgets; `...lesson-10` — Public Revenue — Public Revenue; `...lesson-11` — Public Expenditure — Public Expenditure; `...lesson-12` — Public Debt — Public Debt; `...lesson-13` — Finance Commissions — Finance Commissions.

### Section II — Economy and Development of Telangana

Section stable ID: `group-ii-paper-iii-section-02`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iii-section-02-topic-01` | Structure and Growth of Telangana Economy: Telangana Economy in Undivided Andhra Pradesh (1956-2014) – State Finances ( Dhar Commission, Wanchu Committee, Lalit Committee, Bhargava Committee) – Land Reforms -Growth and Development of Telangana Economy Since 2014 – Sectoral Contribution to State Income – Per Capita Income | Telangana Economy Structure and Growth |
| `group-ii-paper-iii-section-02-topic-02` | Demography and HRD: Size and Growth Rate of Population – Demographic Features of Telangana Economy – Age Structure of Population – Demographic Dividend. | Telangana Demography and HRD |
| `group-ii-paper-iii-section-02-topic-03` | Agriculture and Allied Sectors: Importance of Agriculture – Trends in Growth Rate of Agriculture – Contribution of Agriculture and Allied Sectors to GSDP/GSVA – Land Use and Land Holdings Pattern – Cropping Pattern – Irrigation – Growth and Development of Allied Sectors – Agricultural Policies and Programmes | Telangana Agriculture and Allied Sectors |
| `group-ii-paper-iii-section-02-topic-04` | Industry and Service Sectors: Structure and Growth of Industry – Contribution of Industry to GSDP/GSVA – MSME – Industrial Policies – Components, Structure and Growth of Services Sector – Its Contribution to GSDP/GSVA – Social and Economic Infrastructure | Telangana Industry and Services |
| `group-ii-paper-iii-section-02-topic-05` | State Finances, Budget and Welfare Policies: State Revenue, Expenditure and Debt – State Budgets – Welfare Policies of the State | Telangana State Finances and Welfare |

#### Section II lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Telangana Economy in Undivided Andhra Pradesh (1956-2014) — Undivided Andhra Pradesh Economy; `...lesson-02` — State Finances — State Finances; `...lesson-03` — Dhar Commission — Dhar Commission; `...lesson-04` — Wanchu Committee — Wanchu Committee; `...lesson-05` — Lalit Committee — Lalit Committee; `...lesson-06` — Bhargava Committee — Bhargava Committee; `...lesson-07` — Land Reforms — Land Reforms; `...lesson-08` — Growth and Development of Telangana Economy Since 2014 — Telangana Economy Since 2014; `...lesson-09` — Sectoral Contribution to State Income — Sectoral State Income; `...lesson-10` — Per Capita Income — Per Capita Income.
- Topic 02: `...lesson-01` — Size and Growth Rate of Population — Population Size and Growth; `...lesson-02` — Demographic Features of Telangana Economy — Telangana Demography; `...lesson-03` — Age Structure of Population — Age Structure; `...lesson-04` — Demographic Dividend — Demographic Dividend.
- Topic 03: `...lesson-01` — Importance of Agriculture — Agriculture Importance; `...lesson-02` — Trends in Growth Rate of Agriculture — Agricultural Growth; `...lesson-03` — Contribution of Agriculture and Allied Sectors to GSDP/GSVA — Agriculture and Allied Contribution; `...lesson-04` — Land Use — Land Use; `...lesson-05` — Land Holdings Pattern — Land Holdings; `...lesson-06` — Cropping Pattern — Cropping Pattern; `...lesson-07` — Irrigation — Irrigation; `...lesson-08` — Growth and Development of Allied Sectors — Allied Sector Development; `...lesson-09` — Agricultural Policies and Programmes — Agricultural Policies and Programmes.
- Topic 04: `...lesson-01` — Structure and Growth of Industry — Industry Structure and Growth; `...lesson-02` — Contribution of Industry to GSDP/GSVA — Industry Contribution; `...lesson-03` — MSME — MSME; `...lesson-04` — Industrial Policies — Industrial Policies; `...lesson-05` — Components, Structure and Growth of Services Sector — Services Structure and Growth; `...lesson-06` — Its Contribution to GSDP/GSVA — Services Contribution; `...lesson-07` — Social and Economic Infrastructure — Social and Economic Infrastructure.
- Topic 05: `...lesson-01` — State Revenue, Expenditure and Debt — State Revenue, Expenditure and Debt; `...lesson-02` — State Budgets — State Budgets; `...lesson-03` — Welfare Policies of the State — State Welfare Policies.

### Section III — Issues of Development and Change

Section stable ID: `group-ii-paper-iii-section-03`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iii-section-03-topic-01` | Growth and Development: Concepts of Growth and Development – Characteristics of Development and Underdevelopment – Measurement of Economic Growth and Development – Human Development – Human Development Indices – Human Development Reports | Growth and Development |
| `group-ii-paper-iii-section-03-topic-02` | Social Development: Social Infrastructure – Health and Education – Social Sector – Social Inequalities – Caste – Gender – Religion – Social Transformation – Social Security | Social Development |
| `group-ii-paper-iii-section-03-topic-03` | Poverty and Unemployment: Concepts of Poverty – Measurement of Poverty – Income Inequalities - Concepts of Unemployment – Poverty, Unemployment and Welfare Programmes | Poverty and Unemployment |
| `group-ii-paper-iii-section-03-topic-04` | Regional Inequalities: Urbanization – Migration – Land Acquisition – Resettlement and Rehabilitation | Regional Inequalities |
| `group-ii-paper-iii-section-03-topic-05` | Concepts of Environment – Environmental Protection and Sustainable Development – Types of Pollution – Pollution Control – Effects of Environment – Environmental Policies of India | Environment and Sustainable Development |

#### Section III lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Concepts of Growth and Development — Growth and Development Concepts; `...lesson-02` — Characteristics of Development and Underdevelopment — Development and Underdevelopment; `...lesson-03` — Measurement of Economic Growth and Development — Growth and Development Measurement; `...lesson-04` — Human Development — Human Development; `...lesson-05` — Human Development Indices — Human Development Indices; `...lesson-06` — Human Development Reports — Human Development Reports.
- Topic 02: `...lesson-01` — Social Infrastructure — Social Infrastructure; `...lesson-02` — Health and Education — Health and Education; `...lesson-03` — Social Sector — Social Sector; `...lesson-04` — Social Inequalities — Social Inequalities; `...lesson-05` — Caste — Caste; `...lesson-06` — Gender — Gender; `...lesson-07` — Religion — Religion; `...lesson-08` — Social Transformation — Social Transformation; `...lesson-09` — Social Security — Social Security.
- Topic 03: `...lesson-01` — Concepts of Poverty — Poverty Concepts; `...lesson-02` — Measurement of Poverty — Poverty Measurement; `...lesson-03` — Income Inequalities — Income Inequalities; `...lesson-04` — Concepts of Unemployment — Unemployment Concepts; `...lesson-05` — Poverty — Poverty; `...lesson-06` — Unemployment — Unemployment; `...lesson-07` — Welfare Programmes — Welfare Programmes.
- Topic 04: `...lesson-01` — Urbanization — Urbanization; `...lesson-02` — Migration — Migration; `...lesson-03` — Land Acquisition — Land Acquisition; `...lesson-04` — Resettlement and Rehabilitation — Resettlement and Rehabilitation.
- Topic 05: `...lesson-01` — Concepts of Environment — Environment Concepts; `...lesson-02` — Environmental Protection — Environmental Protection; `...lesson-03` — Sustainable Development — Sustainable Development; `...lesson-04` — Types of Pollution — Pollution Types; `...lesson-05` — Pollution Control — Pollution Control; `...lesson-06` — Effects of Environment — Environmental Effects; `...lesson-07` — Environmental Policies of India — Indian Environmental Policies.

## Paper IV — Telangana Movement and State Formation

### Section I — The idea of Telangana (1948-1970)

Section stable ID: `group-ii-paper-iv-section-01`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iv-section-01-topic-01` | Historical Background: Telangana as a distinctive cultural unit in Hyderabad Princely State, its geographical, cultural, socio, political and economic features people of Telangana- castes, tribes, religion, arts, crafts, languages, dialects, fairs, festivals and important places in Telangana. Administration in Hyderabad Princely State and Administrative Reforms of Salar Jung and Origins of the Mulki-Non-Mulki issue. Farman of 1919 and Definition of Mulki - Establishment of Nizam’s Subjects League known as the Mulki League 1935 and its Significance; Merger of Hyderabad State into Indian Union in 1948- Employment policies under Military Rule and Vellodi,1948-52; Violation of Mulki-Rules and Its Implications. | Historical Background |
| `group-ii-paper-iv-section-01-topic-02` | Hyderabad State in Independent India- Formation of Popular Ministry under Burgula Ramakrishna Rao and 1952 Mulki-Agitation; Demand for Employment of Local people and City College Incident- Its importance. Justice Jagan Mohan Reddy Committee Report, 1953 – Initial debates and demand for Telangana State Reasons for the Formation of States Reorganization Commission (SRC) under Fazal Ali in 1953-Main Provisions and Recommendations of SRC-Dr. B. R. Ambedkar’s views on SRC and smaller states. | Hyderabad State in Independent India |
| `group-ii-paper-iv-section-01-topic-03` | Formation of Andhra Pradesh, 1956: Gentlemen Agreement - its Provisions and Recommendations; Telangana Regional Committee, Composition and Functions & Performance – Violation of Safeguards-Migration from Coastal Andhra Region and its Consequences-Post-1970 development Scenario in Telangana- Agriculture, Irrigation, Power, Education, Employment, Medical and Health etc. | Formation of Andhra Pradesh |
| `group-ii-paper-iv-section-01-topic-04` | Violation of Employment and Service Rules: Origins of Telangana Agitation- Protest in Kothagudem and other places, Fast unto Death by Ravindranath; 1969 Agitation for Separate Telangana. Role of Intellectuals, Students, Employees in Jai Telangana Movement. | Employment and Service Rules |
| `group-ii-paper-iv-section-01-topic-05` | Formation of Telangana Praja Samithi and Course of Movement and its Major Events, Leaders and Personalities- All Party Accord – G.O. 36 - Suppression of Telangana Movement and its Consequences-The Eight Point and Five-Point Formulas-Implications. | Telangana Praja Samithi and Movement |

#### Section I lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Telangana as a distinctive cultural unit in Hyderabad Princely State — Telangana Cultural Unit; `...lesson-02` — geographical features — Geography; `...lesson-03` — cultural features — Culture; `...lesson-04` — socio features — Society; `...lesson-05` — political features — Politics; `...lesson-06` — economic features — Economy; `...lesson-07` — castes — Castes; `...lesson-08` — tribes — Tribes; `...lesson-09` — religion — Religion; `...lesson-10` — arts — Arts; `...lesson-11` — crafts — Crafts; `...lesson-12` — languages — Languages; `...lesson-13` — dialects — Dialects; `...lesson-14` — fairs — Fairs; `...lesson-15` — festivals — Festivals; `...lesson-16` — important places in Telangana — Important Places; `...lesson-17` — Administration in Hyderabad Princely State — Hyderabad Administration; `...lesson-18` — Administrative Reforms of Salar Jung — Salar Jung Reforms; `...lesson-19` — Origins of the Mulki-Non-Mulki issue — Mulki-Non-Mulki Origins; `...lesson-20` — Farman of 1919 — Farman of 1919; `...lesson-21` — Definition of Mulki — Mulki Definition; `...lesson-22` — Establishment of Nizam’s Subjects League known as the Mulki League 1935 — Mulki League; `...lesson-23` — its Significance — Mulki League Significance; `...lesson-24` — Merger of Hyderabad State into Indian Union in 1948 — Merger into Indian Union; `...lesson-25` — Employment policies under Military Rule — Military Rule Employment; `...lesson-26` — Vellodi,1948-52 — Vellodi Administration; `...lesson-27` — Violation of Mulki-Rules — Mulki-Rules Violation; `...lesson-28` — Its Implications — Implications.
- Topic 02: `...lesson-01` — Formation of Popular Ministry under Burgula Ramakrishna Rao — Popular Ministry; `...lesson-02` — 1952 Mulki-Agitation — 1952 Mulki Agitation; `...lesson-03` — Demand for Employment of Local people — Local Employment; `...lesson-04` — City College Incident — City College Incident; `...lesson-05` — Its importance — Incident Importance; `...lesson-06` — Justice Jagan Mohan Reddy Committee Report, 1953 — Jagan Mohan Reddy Committee; `...lesson-07` — Initial debates — Initial Debates; `...lesson-08` — demand for Telangana State — Telangana State Demand; `...lesson-09` — Reasons for the Formation of States Reorganization Commission (SRC) under Fazal Ali in 1953 — SRC Formation; `...lesson-10` — Main Provisions and Recommendations of SRC — SRC Provisions and Recommendations; `...lesson-11` — Dr. B. R. Ambedkar’s views on SRC — Ambedkar and SRC; `...lesson-12` — smaller states — Smaller States.
- Topic 03: `...lesson-01` — Gentlemen Agreement — Gentlemen Agreement; `...lesson-02` — its Provisions and Recommendations — Agreement Provisions and Recommendations; `...lesson-03` — Telangana Regional Committee — Regional Committee; `...lesson-04` — Composition — Committee Composition; `...lesson-05` — Functions — Committee Functions; `...lesson-06` — Performance — Committee Performance; `...lesson-07` — Violation of Safeguards — Safeguard Violations; `...lesson-08` — Migration from Coastal Andhra Region — Coastal Andhra Migration; `...lesson-09` — its Consequences — Migration Consequences; `...lesson-10` — Post-1970 development Scenario in Telangana — Post-1970 Development; `...lesson-11` — Agriculture — Agriculture; `...lesson-12` — Irrigation — Irrigation; `...lesson-13` — Power — Power; `...lesson-14` — Education — Education; `...lesson-15` — Employment — Employment; `...lesson-16` — Medical and Health — Medical and Health.
- Topic 04: `...lesson-01` — Origins of Telangana Agitation — Agitation Origins; `...lesson-02` — Protest in Kothagudem and other places — Kothagudem and Other Protests; `...lesson-03` — Fast unto Death by Ravindranath — Ravindranath Fast; `...lesson-04` — 1969 Agitation for Separate Telangana — 1969 Agitation; `...lesson-05` — Role of Intellectuals — Intellectuals; `...lesson-06` — Students — Students; `...lesson-07` — Employees — Employees; `...lesson-08` — Jai Telangana Movement — Jai Telangana Movement.
- Topic 05: `...lesson-01` — Formation of Telangana Praja Samithi — Telangana Praja Samithi; `...lesson-02` — Course of Movement — Movement Course; `...lesson-03` — Major Events — Major Events; `...lesson-04` — Leaders — Leaders; `...lesson-05` — Personalities — Personalities; `...lesson-06` — All Party Accord — All Party Accord; `...lesson-07` — G.O. 36 — G.O. 36; `...lesson-08` — Suppression of Telangana Movement — Movement Suppression; `...lesson-09` — its Consequences — Consequences; `...lesson-10` — The Eight Point and Five-Point Formulas — Eight-Point and Five-Point Formulas; `...lesson-11` — Implications — Implications.

### Section II — Mobilisational phase (1971 -1990)

Section stable ID: `group-ii-paper-iv-section-02`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iv-section-02-topic-01` | Court Judgements on Mulki Rules- Jai Andhra Movement and its Consequences- Six Point Formula 1973, and its Provisions; Article 371-D, Presidential Order, 1975- Officers (Jayabharat Reddy) Committee Report- G.O. 610 (1985); its Provisions and Violation- Reaction and Representations of Telangana Employees. | Mulki Rules and Service Safeguards |
| `group-ii-paper-iv-section-02-topic-02` | Rise and Spread of Naxalite Movement, causes and consequences - Anti-Landlord Struggles in Jagityala-Siricilla, Rytu-Cooli Sanghams; Alienation of Tribal Lands and Adivasi Resistance- Jal, Jungle, and Jamin. | Naxalite and Resistance Movements |
| `group-ii-paper-iv-section-02-topic-03` | Rise of Regional Parties in 1980’s and Changes in the Political, Socio-Economic and Cultural fabric of Telangana- Notion of Telugu Jathi and suppression of Telangana identity- Expansion of new economy in Hyderabad and other parts of Telangana; Real Estate, Contracts, Finance Companies; Film, Media and Entertainment Industry; Corporate Education and Hospitals etc; Dominant Culture and its implications for Telangana self respect, Dialect, Language and Culture. | Regional Parties and Social Change |
| `group-ii-paper-iv-section-02-topic-04` | Liberalization and Privatisation policies in 1990’s and their consequences - Emergence of regional disparities and imbalances in political power, administration, education, employment – Growth of Madiga Dandora and Tudum Debba movements – Agrarian crisis and decline of Handicrafts in Telangana and its impact on Telangana Society and economy. | Liberalization and Regional Disparities |
| `group-ii-paper-iv-section-02-topic-05` | Quest for Telangana identity – Intellectual discussions and debates – Political and ideological Efforts – Growth of popular unrest against regional disparities, discrimination and under development of Telangana. | Telangana Identity |

#### Section II lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Court Judgements on Mulki Rules — Mulki Rules Judgements; `...lesson-02` — Jai Andhra Movement and its Consequences — Jai Andhra; `...lesson-03` — Six Point Formula 1973 — Six Point Formula; `...lesson-04` — its Provisions — Six Point Provisions; `...lesson-05` — Article 371-D — Article 371-D; `...lesson-06` — Presidential Order, 1975 — Presidential Order; `...lesson-07` — Officers (Jayabharat Reddy) Committee Report — Jayabharat Reddy Committee; `...lesson-08` — G.O. 610 (1985) — G.O. 610; `...lesson-09` — its Provisions and Violation — G.O. 610 Provisions and Violation; `...lesson-10` — Reaction — Employee Reaction; `...lesson-11` — Representations of Telangana Employees — Employee Representations.
- Topic 02: `...lesson-01` — Rise and Spread of Naxalite Movement — Naxalite Movement; `...lesson-02` — causes and consequences — Causes and Consequences; `...lesson-03` — Anti-Landlord Struggles in Jagityala-Siricilla — Jagityala-Siricilla Struggles; `...lesson-04` — Rytu-Cooli Sanghams — Rytu-Cooli Sanghams; `...lesson-05` — Alienation of Tribal Lands — Tribal Land Alienation; `...lesson-06` — Adivasi Resistance — Adivasi Resistance; `...lesson-07` — Jal, Jungle, and Jamin — Jal, Jungle, Jamin.
- Topic 03: `...lesson-01` — Rise of Regional Parties in 1980’s — Regional Parties; `...lesson-02` — Changes in the Political, Socio-Economic and Cultural fabric of Telangana — Telangana Political, Social, Economic and Cultural Change; `...lesson-03` — Notion of Telugu Jathi — Telugu Jathi; `...lesson-04` — suppression of Telangana identity — Identity Suppression; `...lesson-05` — Expansion of new economy in Hyderabad and other parts of Telangana — New Economy; `...lesson-06` — Real Estate — Real Estate; `...lesson-07` — Contracts — Contracts; `...lesson-08` — Finance Companies — Finance Companies; `...lesson-09` — Film, Media and Entertainment Industry — Film, Media and Entertainment; `...lesson-10` — Corporate Education and Hospitals etc — Corporate Education and Hospitals; `...lesson-11` — Dominant Culture — Dominant Culture; `...lesson-12` — its implications for Telangana self respect — Self-Respect; `...lesson-13` — Dialect — Dialect; `...lesson-14` — Language and Culture — Language and Culture.
- Topic 04: `...lesson-01` — Liberalization and Privatisation policies in 1990’s — Liberalization and Privatisation; `...lesson-02` — their consequences — Policy Consequences; `...lesson-03` — Emergence of regional disparities — Regional Disparities; `...lesson-04` — imbalances in political power — Political Power Imbalances; `...lesson-05` — administration — Administrative Imbalances; `...lesson-06` — education — Education Imbalances; `...lesson-07` — employment — Employment Imbalances; `...lesson-08` — Growth of Madiga Dandora — Madiga Dandora; `...lesson-09` — Tudum Debba movements — Tudum Debba; `...lesson-10` — Agrarian crisis — Agrarian Crisis; `...lesson-11` — decline of Handicrafts in Telangana — Handicrafts Decline; `...lesson-12` — its impact on Telangana Society and economy — Social and Economic Impact.
- Topic 05: `...lesson-01` — Quest for Telangana identity — Telangana Identity; `...lesson-02` — Intellectual discussions and debates — Intellectual Debates; `...lesson-03` — Political and ideological Efforts — Political and Ideological Efforts; `...lesson-04` — Growth of popular unrest — Popular Unrest; `...lesson-05` — regional disparities — Regional Disparities; `...lesson-06` — discrimination — Discrimination; `...lesson-07` — under development of Telangana — Underdevelopment.

### Section III — Towards Formation of Telangana State (1991-2014)

Section stable ID: `group-ii-paper-iv-section-03`

| topic stableId | officialName | displayName |
|---|---|---|
| `group-ii-paper-iv-section-03-topic-01` | Public awakening and Intellectual reaction against discrimination- formation of Civil society organisations, Articulation of separate Telangana Identity; Initial organisations raised the issues of separate Telangana; Telangana Information Trust - Telangana Aikya Vedika, Bhuvanagiri Sabha - Telangana Jana Sabha, Telangana Maha Sabha - Warangal Decleration - Telangana Vidyavanthula Vedika; etc. Role of university and college students - Osmania and Kakatiya Universities | Public Awakening and Civil Society |
| `group-ii-paper-iv-section-03-topic-02` | Establishment of Telangana Rashtra Samithi in 2001, Political Realignment and Electoral Alliances in 2004 and later Phase of Telangana Movement – TRS in UPA Girglani Committee- Telangana Employees Joint Action Committee - Pranab Mukherjee Committee- 2009-Elections-Alliances- Telangana in Election Manifestos- The agitation against Hyderabad as Free-zone - and Demand for separate Statehood- Fast-Unto-Death by K.Chandrashekar Rao – Formation of Political Joint Action Committee (2009) | TRS and Later Movement |
| `group-ii-paper-iv-section-03-topic-03` | Role of Political Parties-TRS, Congress, B.J.P., Left parties, T.D.P., M.I.M and other political parties such as Telangana Praja Front, Telangana United Front etc., Dalit Bahujan Sanghams and Grass root organisations - Other Joint Action Committees and popular protests- Suicides for the cause of Telangana. | Political Parties and Protests |
| `group-ii-paper-iv-section-03-topic-04` | Cultural Revivalism in Telangana and other symbolic expressions in Telangana Movement- Literary forms- performing arts and other cultural expressions- writers, poets, singers, intellectuals, Artists, Journalists, Students, Employees, Advocates, Doctors, NRIs, Women and Civil society groups - organised and unorganised sectors, castes, communities and other social groups in transforming the agitation into a mass movement-Intensification of Movement, Forms of Protest and Major events: Sakalajanula Samme, Non-Cooperation Movement; Million March, etc., | Cultural Revivalism and Mass Movement |
| `group-ii-paper-iv-section-03-topic-05` | Parliamentary Process; UPA Government’s stand on Telangana- All-Party Meeting- Anthony Committee- Statements on Telangana by Central Home Minister - Sri Krishna Committee Report and its Recommendations, AP Assembly and Parliamentary proceedings on Telangana, Declaration of Telangana State in Parliament, Andhra Pradesh State Reorganization Act, 2014- Elections and victory of Telangana Rashtra Samithi and the first Government of Telangana State. | Parliamentary Process and State Formation |

#### Section III lesson ledger

All entries have `sourceType: application_decomposition`.

- Topic 01: `...lesson-01` — Public awakening — Public Awakening; `...lesson-02` — Intellectual reaction against discrimination — Intellectual Reaction; `...lesson-03` — formation of Civil society organisations — Civil Society Organisations; `...lesson-04` — Articulation of separate Telangana Identity — Telangana Identity; `...lesson-05` — Initial organisations raised the issues of separate Telangana — Initial Organisations; `...lesson-06` — Telangana Information Trust — Telangana Information Trust; `...lesson-07` — Telangana Aikya Vedika — Telangana Aikya Vedika; `...lesson-08` — Bhuvanagiri Sabha — Bhuvanagiri Sabha; `...lesson-09` — Telangana Jana Sabha — Telangana Jana Sabha; `...lesson-10` — Telangana Maha Sabha — Telangana Maha Sabha; `...lesson-11` — Warangal Decleration — Warangal Decleration; `...lesson-12` — Telangana Vidyavanthula Vedika — Telangana Vidyavanthula Vedika; `...lesson-13` — Role of university and college students — University and College Students; `...lesson-14` — Osmania — Osmania University; `...lesson-15` — Kakatiya Universities — Kakatiya University.
- Topic 02: `...lesson-01` — Establishment of Telangana Rashtra Samithi in 2001 — TRS Establishment; `...lesson-02` — Political Realignment — Political Realignment; `...lesson-03` — Electoral Alliances in 2004 and later Phase of Telangana Movement — Electoral Alliances; `...lesson-04` — TRS in UPA — TRS in UPA; `...lesson-05` — Girglani Committee — Girglani Committee; `...lesson-06` — Telangana Employees Joint Action Committee — Employees JAC; `...lesson-07` — Pranab Mukherjee Committee — Pranab Mukherjee Committee; `...lesson-08` — 2009-Elections — 2009 Elections; `...lesson-09` — Alliances — Alliances; `...lesson-10` — Telangana in Election Manifestos — Election Manifestos; `...lesson-11` — The agitation against Hyderabad as Free-zone — Hyderabad Free-Zone Agitation; `...lesson-12` — Demand for separate Statehood — Separate Statehood; `...lesson-13` — Fast-Unto-Death by K.Chandrashekar Rao — K. Chandrashekar Rao Fast; `...lesson-14` — Formation of Political Joint Action Committee (2009) — Political JAC.
- Topic 03: `...lesson-01` — Role of Political Parties — Political Parties; `...lesson-02` — TRS — TRS; `...lesson-03` — Congress — Congress; `...lesson-04` — B.J.P. — BJP; `...lesson-05` — Left parties — Left Parties; `...lesson-06` — T.D.P. — TDP; `...lesson-07` — M.I.M — MIM; `...lesson-08` — Telangana Praja Front — Telangana Praja Front; `...lesson-09` — Telangana United Front — Telangana United Front; `...lesson-10` — Dalit Bahujan Sanghams — Dalit Bahujan Sanghams; `...lesson-11` — Grass root organisations — Grassroot Organisations; `...lesson-12` — Other Joint Action Committees — Other JACs; `...lesson-13` — popular protests — Popular Protests; `...lesson-14` — Suicides for the cause of Telangana — Sacrifices for Telangana.
- Topic 04: `...lesson-01` — Cultural Revivalism in Telangana — Cultural Revivalism; `...lesson-02` — other symbolic expressions in Telangana Movement — Symbolic Expressions; `...lesson-03` — Literary forms — Literary Forms; `...lesson-04` — performing arts — Performing Arts; `...lesson-05` — other cultural expressions — Cultural Expressions; `...lesson-06` — writers — Writers; `...lesson-07` — poets — Poets; `...lesson-08` — singers — Singers; `...lesson-09` — intellectuals — Intellectuals; `...lesson-10` — Artists — Artists; `...lesson-11` — Journalists — Journalists; `...lesson-12` — Students — Students; `...lesson-13` — Employees — Employees; `...lesson-14` — Advocates — Advocates; `...lesson-15` — Doctors — Doctors; `...lesson-16` — NRIs — NRIs; `...lesson-17` — Women — Women; `...lesson-18` — Civil society groups — Civil Society Groups; `...lesson-19` — organised and unorganised sectors — Organised and Unorganised Sectors; `...lesson-20` — castes — Castes; `...lesson-21` — communities — Communities; `...lesson-22` — other social groups — Other Social Groups; `...lesson-23` — transforming the agitation into a mass movement — Mass Movement; `...lesson-24` — Intensification of Movement — Movement Intensification; `...lesson-25` — Forms of Protest — Forms of Protest; `...lesson-26` — Sakalajanula Samme — Sakalajanula Samme; `...lesson-27` — Non-Cooperation Movement — Non-Cooperation Movement; `...lesson-28` — Million March — Million March.
- Topic 05: `...lesson-01` — Parliamentary Process — Parliamentary Process; `...lesson-02` — UPA Government’s stand on Telangana — UPA Stand; `...lesson-03` — All-Party Meeting — All-Party Meeting; `...lesson-04` — Anthony Committee — Anthony Committee; `...lesson-05` — Statements on Telangana by Central Home Minister — Home Minister Statements; `...lesson-06` — Sri Krishna Committee Report — Sri Krishna Committee; `...lesson-07` — its Recommendations — Sri Krishna Recommendations; `...lesson-08` — AP Assembly and Parliamentary proceedings on Telangana — Assembly and Parliamentary Proceedings; `...lesson-09` — Declaration of Telangana State in Parliament — Parliamentary Declaration; `...lesson-10` — Andhra Pradesh State Reorganization Act, 2014 — Reorganization Act; `...lesson-11` — Elections — Elections; `...lesson-12` — victory of Telangana Rashtra Samithi — TRS Victory; `...lesson-13` — the first Government of Telangana State — First Telangana Government.

## Audit tables

The audit counts treat each numbered source Topic as one official Topic and
each separately listed source fragment above as one official syllabus item.
Paper I has no decomposed Lesson rows.

### Topic coverage

| Paper | Section | Official Topics | Mapped Topics | Missing | Extra |
|---|---|---:|---:|---:|---:|
| Paper I | none | 11 | 11 | 0 | 0 |
| Paper II | Section I | 5 | 5 | 0 | 0 |
| Paper II | Section II | 10 | 10 | 0 | 0 |
| Paper II | Section III | 5 | 5 | 0 | 0 |
| Paper III | Section I | 5 | 5 | 0 | 0 |
| Paper III | Section II | 5 | 5 | 0 | 0 |
| Paper III | Section III | 5 | 5 | 0 | 0 |
| Paper IV | Section I | 5 | 5 | 0 | 0 |
| Paper IV | Section II | 5 | 5 | 0 | 0 |
| Paper IV | Section III | 5 | 5 | 0 | 0 |
| **Total** |  | **61** | **61** | **0** | **0** |

### Explicit-item coverage

| Paper | Topic group | Explicit syllabus items | Mapped lessons | Missing | Extra |
|---|---|---:|---:|---:|---:|
| Paper I | 11 top-level items | 0 subordinate | 0 | 0 | 0 |
| Paper II | Section I, Topics 1–5 | 78 | 78 | 0 | 0 |
| Paper II | Section II, Topics 1–10 | 46 | 46 | 0 | 0 |
| Paper II | Section III, Topics 1–5 | 49 | 49 | 0 | 0 |
| Paper III | Section I, Topics 1–5 | 45 | 45 | 0 | 0 |
| Paper III | Section II, Topics 1–5 | 33 | 33 | 0 | 0 |
| Paper III | Section III, Topics 1–5 | 33 | 33 | 0 | 0 |
| Paper IV | Section I, Topics 1–5 | 75 | 75 | 0 | 0 |
| Paper IV | Section II, Topics 1–5 | 51 | 51 | 0 | 0 |
| Paper IV | Section III, Topics 1–5 | 84 | 84 | 0 | 0 |
| **Total** |  | **494** | **494** | **0** | **0** |

### Global validation

| Measure | Result |
|---|---:|
| Total official top-level Topics | 61 |
| Total mapped Topic nodes | 61 |
| Total explicit source items represented as Lessons | 494 |
| Total mapped Lesson nodes | 494 |
| Total official syllabus items represented | 555 |
| Total mapped items | 555 |
| Missing items | 0 |
| Invented/extra items | 0 |
| Duplicate stable IDs | 0 |
| Paper I artificial Sections | 0 |
| Topic-wise marks assigned | 0 |

## Boundary status and human approval

The source explicitly lists the content fragments, but it does not formally
number application Lessons. The following boundaries therefore require
content-owner confirmation before UI/content production:

1. Whether a named person, committee, organisation, event, or consequence
   should be independently testable or grouped with its surrounding sentence.
2. Whether the source's `etc.` fragments should receive an additional
   catch-all Lesson. No catch-all Lesson has been invented here.
3. Whether `Jotiba and Savithribai Phule` should remain one Lesson or become
   two Lessons. It is retained as one source-named item.
4. Whether `Socio, Cultural and Economic Contribution during Mauryas, Guptas,
   Pallavas, Chalukyas and Cholas` should be one contribution Lesson or one
   Lesson per dynasty. The mapping preserves the named dynasties separately
   while retaining the source phrase.
5. The source's unusual spellings and punctuation, including `Green
   Revelation`, `Flourosis`, `Decleration`, `Osaman`, and `Girglani`, must be
   confirmed against the authoritative PDF during content ingestion.

These are boundary approvals, not missing or invented syllabus items.

## Phase 4.4.1 result

- Files changed: `docs/group_ii_syllabus_mapping.md` only
- Flutter/lib code changed: no
- Firestore rules changed: no
- Questions or progress data changed: no
- Migrations created: no
- Deployment performed: no
- Commit or push performed: no
- Missing items: 0
- Invented/extra items: 0
- Duplicate stable IDs: 0
