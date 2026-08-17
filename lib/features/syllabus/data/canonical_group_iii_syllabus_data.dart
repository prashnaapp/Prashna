import 'models/syllabus_models.dart';

/// Canonical Group-III syllabus from `docs/group_iii_syllabus_mapping.md`.
///
/// Source: official Group-III Scheme and Syllabus PDF.
/// Does not reuse Group-II IDs or Lesson hierarchy.
abstract final class CanonicalGroupIIISyllabusData {
  static SyllabusUnit _unit({
    required String id,
    required String officialName,
    required String displayName,
  }) {
    return SyllabusUnit(
      id: id,
      officialName: officialName,
      displayName: displayName,
    );
  }

  /// Paper-I: 11 syllabus units directly under the paper (no Parts).
  static final List<SyllabusUnit> paperIUnits = [
    _unit(
      id: 'group-iii-paper-i-unit-01',
      officialName: 'Current Affairs – Regional, National & International.',
      displayName: 'Current Affairs – Regional, National & International',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-02',
      officialName: 'International Relations and Events.',
      displayName: 'International Relations and Events',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-03',
      officialName:
          'General Science; India’s Achievements in Science and Technology.',
      displayName:
          'General Science; India’s Achievements in Science and Technology',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-04',
      officialName:
          'Environmental Issues; Disaster Management- Prevention and Mitigation Strategies.',
      displayName:
          'Environmental Issues; Disaster Management- Prevention and Mitigation Strategies',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-05',
      officialName:
          'World Geography, Indian Geography and Geography of Telangana State.',
      displayName:
          'World Geography, Indian Geography and Geography of Telangana State',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-06',
      officialName: 'History and Cultural Heritage of India.',
      displayName: 'History and Cultural Heritage of India',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-07',
      officialName:
          'Society, Culture, Heritage, Arts and Literature of Telangana.',
      displayName:
          'Society, Culture, Heritage, Arts and Literature of Telangana',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-08',
      officialName: 'Policies of Telangana State.',
      displayName: 'Policies of Telangana State',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-09',
      officialName: 'Social Exclusion, Rights Issues and Inclusive Policies.',
      displayName: 'Social Exclusion, Rights Issues and Inclusive Policies',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-10',
      officialName:
          'Logical Reasoning; Analytical Ability and Data Interpretation.',
      displayName:
          'Logical Reasoning; Analytical Ability and Data Interpretation',
    ),
    _unit(
      id: 'group-iii-paper-i-unit-11',
      officialName: 'Basic English. (8th Class Standard)',
      displayName: 'Basic English. (8th Class Standard)',
    ),
  ];

  static final List<SyllabusPart> paperIIParts = [
    SyllabusPart(
      id: 'group-iii-paper-ii-part-i',
      officialName:
          'Socio-Cultural History of Telangana and Formation of Telangana State',
      displayName: 'Part-I',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-ii-part-i-unit-01',
          officialName:
              'Satavahanas, Ikshvakus, Vishnukundins, Mudigonda and Vemulawada Chalukyas and their contribution to culture; Social and Religious conditions; Buddhism and Jainism in Ancient Telangana; Growth of Language and Literature, Art and Architecture.',
          displayName: 'Ancient Telangana Dynasties and Culture',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-i-unit-02',
          officialName:
              'The establishment of Kakatiya kingdom and their contribution to socio-cultural development. Growth of Language and Literature under the Kakatiyas; Popular protest against Kakatiyas: Sammakka - Sarakka Revolt; Art, Architecture and Fine Arts. Rachakonda and Deverakonda Velamas, Social and Religious Conditions; Growth of Language and Literature, Socio- Cultural contribution of Qutubshahis - Growth of Language, Literature, Art, Architecture, Festivals, Dance, and Music. Emergence of Composite Culture.',
          displayName: 'Kakatiyas and Medieval Telangana',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-i-unit-03',
          officialName:
              'Asaf Jahi Dynasty; Nizam-British Relations: Salarjung Reforms and their impact; Socio - Cultural- Religious Conditions under the Nizams: Educational Reforms, Establishment of Osmania University; Growth of Employment and the Rise of Middle Classes.',
          displayName: 'Asaf Jahi Dynasty and the Nizams',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-i-unit-04',
          officialName:
              'Socio-cultural and Political Awakening in Telangana: Role of Arya Samaj- Andhra Mahasabha; Andhra Saraswatha Parishat, Literary and Library movements, Adi- Hindu movement, Andhra Mahila Sabha and the growth of Women’s movement; Tribal Revolts, Ramji Gond and Kumaram Bheem, -The Telangana Peasant Armed Struggle ; Causes and Consequences.',
          displayName: 'Socio-cultural and Political Awakening in Telangana',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-i-unit-05',
          officialName:
              'Integration of Hyderabad State into Indian Union and formation of Andhra Pradesh. Gentlemen Agreement; Mulki Movement 1952-56; Violation of Safeguards – Regional imbalances - Assertion of Telangana identity; Agitation for Separate Telangana State 1969- 70 - Growth of popular protest against discrimination and movements towards the formation of Telangana State 1971-2014.',
          displayName:
              'Integration, Safeguards and Formation of Telangana State',
        ),
      ],
    ),
    SyllabusPart(
      id: 'group-iii-paper-ii-part-ii',
      officialName: 'Overview of the Indian Constitution and Politics',
      displayName: 'Part-II',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-01',
          officialName:
              'Evolution of the Indian Constitution – Nature and salient features – Preamble.',
          displayName: 'Evolution of the Indian Constitution',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-02',
          officialName:
              'Fundamental Rights – Directive Principles of the State Policy – Fundamental Duties.',
          displayName: 'Fundamental Rights, Directive Principles and Duties',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-03',
          officialName:
              'Distinctive Features of the Indian Federalism – Distribution of Legislative, Financial and Administrative Powers between the Union and States.',
          displayName: 'Indian Federalism and Distribution of Powers',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-04',
          officialName:
              'Union and State Government – President – Prime Minister and Council of Ministers; Governor, Chief Minister and Council of Ministers – Powers and Functions.',
          displayName: 'Union and State Government',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-05',
          officialName:
              'Indian Constitution; Amendment Procedures and Amendment Acts.',
          displayName: 'Constitutional Amendments',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-06',
          officialName:
              'Rural and Urban Governance with special reference to the 73 rd and 74 th Amendment Acts.',
          displayName: 'Rural and Urban Governance',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-07',
          officialName:
              'Electoral Mechanism: Electoral Laws, Election Commission, Political Parties, Anti defection Law and Electoral Reforms.',
          displayName: 'Electoral Mechanism',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-08',
          officialName:
              'Judicial System in India – Judicial Review; Judicial Activism; Supreme Court and High Courts.',
          displayName: 'Judicial System in India',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-09',
          officialName:
              'a) Special Constitutional Provisions for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Economically Weaker Sections (EWS). b) National Commissions for the Enforcement – National Commission for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Human Rights.',
          displayName:
              'Special Constitutional Provisions and National Commissions',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-ii-unit-10',
          officialName:
              'National Integration issues and challenges: Insurgency; Internal Security; Inter-State Disputes.',
          displayName: 'National Integration Issues and Challenges',
        ),
      ],
    ),
    SyllabusPart(
      id: 'group-iii-paper-ii-part-iii',
      officialName: 'Social Structure, Issues and Public Policies',
      displayName: 'Part-III',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-ii-part-iii-unit-01',
          officialName:
              'Indian Social Structure: Salient Features of Indian society: Family, Marriage, Kinship, Caste, Tribe, Ethnicity, Religion and Women.',
          displayName: 'Indian Social Structure',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-iii-unit-02',
          officialName:
              'Social Issues: Inequality and Exclusion: Casteism, Communalism, Regionalism, Violence against Women, Child Labour, Human trafficking, Disability, Aged and Third / Trans-Gender Issues.',
          displayName: 'Social Issues',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-iii-unit-03',
          officialName:
              'Social Movements: Peasant Movement, Tribal movement, Backward Classes Movement, Dalit Movement, Environmental Movement, Women’s Movement, Regional Autonomy Movement, Human Rights / Civil Rights Movement.',
          displayName: 'Social Movements',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-iii-unit-04',
          officialName:
              'Social Policies and Welfare Programmes: Affirmative Policies for SCs, STs, OBC, Women, Minorities, Labour, Disabled and Children; Welfare Programmes: Employment, Poverty Alleviation Programmes; Rural and Urban, Women and Child Welfare, Tribal Welfare.',
          displayName: 'Social Policies and Welfare Programmes',
        ),
        _unit(
          id: 'group-iii-paper-ii-part-iii-unit-05',
          officialName:
              'Society in Telangana: Socio- Cultural Features and Issues in Telangana; Vetti, Jogini, Devadasi System, Child Labour, Girl Child, Flourosis, Migration, Farmer’s; Artisanal and Service Communities in Distress.',
          displayName: 'Society in Telangana',
        ),
      ],
    ),
  ];

  static final List<SyllabusPart> paperIIIParts = [
    SyllabusPart(
      id: 'group-iii-paper-iii-part-i',
      officialName: 'Indian Economy: Issues and Challenges',
      displayName: 'Part-I',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-iii-part-i-unit-01',
          officialName:
              'Demography: Demographic Features of Indian Population – Size and Growth Rate of Population – Demographic Dividend – Sectoral Distribution of Population – Population Policies of India',
          displayName: 'Demography',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-i-unit-02',
          officialName:
              'National Income: Concepts & Components of National Income – Measurement Methods – National Income Estimates in India and its Trends – Sectoral Contribution – Per Capita Income',
          displayName: 'National Income',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-i-unit-03',
          officialName:
              'Primary and Secondary Sectors: Agriculture and Allied Sectors – Contribution to National Income – Cropping Pattern – Agricultural Production and Productivity – Green Revelation – Irrigation – Agricultural Finance and Marketing – Agricultural Pricing – Agricultural Subsidies and Food Security – Agricultural Labour – Growth and Performance of Allied Sectors',
          displayName: 'Agriculture and Allied Sectors',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-i-unit-04',
          officialName:
              'Industry and Services Sectors: Growth and Structure of Industry in India – Contribution to National Income – Industrial Policies – Large Scale Industries – MSMEs – Industrial Finance – Contribution of Services Sector to National Income – Importance of Services Sector – Sub Sectors of Services – Economic Infrastructure – India’s Foreign Trade',
          displayName: 'Industry and Services Sectors',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-i-unit-05',
          officialName:
              'Planning, NITI Aayog and Public Finance: Objectives of India’s Five Year Plans – Targets, Achievements and Failures of Five Year Plans – NITI Aayog – Budget in India – Concepts of Budget Deficits – FRBM – Recent Union Budgets – Public Revenue, Public Expenditure and Public Debt – Finance Commissions',
          displayName: 'Planning, NITI Aayog and Public Finance',
        ),
      ],
    ),
    SyllabusPart(
      id: 'group-iii-paper-iii-part-ii',
      officialName: 'Economy and Development of Telangana',
      displayName: 'Part-II',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-iii-part-ii-unit-01',
          officialName:
              'Structure and Growth of Telangana Economy: Telangana Economy in Undivided Andhra Pradesh (1956-2014) – State Finances ( Dhar Commission, Wanchu Committee, Lalit Committee, Bhargava Committee) – Land Reforms - Growth and Development of Telangana Economy Since 2014 – Sectoral Contribution to State Income – Per Capita Income',
          displayName: 'Structure and Growth of Telangana Economy',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-ii-unit-02',
          officialName:
              'Demography and HRD: Size and Growth Rate of Population – Demographic Features of Telangana Economy – Age Structure of Population – Demographic Dividend.',
          displayName: 'Demography and HRD',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-ii-unit-03',
          officialName:
              'Agriculture and Allied Sectors: Importance of Agriculture – Trends in Growth Rate of Agriculture – Contribution of Agriculture and Allied Sectors to GSDP/GSVA – Land Use and Land Holdings Pattern – Cropping Pattern – Irrigation – Growth and Development of Allied Sectors – Agricultural Policies and Programmes',
          displayName: 'Agriculture and Allied Sectors',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-ii-unit-04',
          officialName:
              'Industry and Service Sectors: Structure and Growth of Industry – Contribution of Industry to GSDP/GSVA – MSME – Industrial Policies – Components, Structure and Growth of Services Sector – Its Contribution to GSDP/GSVA – Social and Economic Infrastructure',
          displayName: 'Industry and Service Sectors',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-ii-unit-05',
          officialName:
              'State Finances, Budget and Welfare Policies: State Revenue, Expenditure and Debt – State Budgets – Welfare Policies of the State',
          displayName: 'State Finances, Budget and Welfare Policies',
        ),
      ],
    ),
    SyllabusPart(
      id: 'group-iii-paper-iii-part-iii',
      officialName: 'Issues of Development and Change',
      displayName: 'Part-III',
      syllabusUnits: [
        _unit(
          id: 'group-iii-paper-iii-part-iii-unit-01',
          officialName:
              'Growth and Development: Concepts of Growth and Development – Characteristics of Development and Underdevelopment – Measurement of Economic Growth and Development – Human Development – Human Development Indices – Human Development Reports',
          displayName: 'Growth and Development',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-iii-unit-02',
          officialName:
              'Social Development: Social Infrastructure – Health and Education – Social Sector – Social Inequalities – Caste – Gender – Religion – Social Transformation – Social Security',
          displayName: 'Social Development',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-iii-unit-03',
          officialName:
              'Poverty and Unemployment: Concepts of Poverty – Measurement of Poverty – Income Inequalities - Concepts of Unemployment – Poverty, Unemployment and Welfare Programmes',
          displayName: 'Poverty and Unemployment',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-iii-unit-04',
          officialName:
              'Regional Inequalities: Urbanization – Migration – Land Acquisition – Resettlement and Rehabilitation',
          displayName: 'Regional Inequalities',
        ),
        _unit(
          id: 'group-iii-paper-iii-part-iii-unit-05',
          officialName:
              'Environment and Sustainable Development: Concepts of Environment – Environmental Protection and Sustainable Development – Types of Pollution – Pollution Control – Effects of Environment – Environmental Policies of India',
          displayName: 'Environment and Sustainable Development',
        ),
      ],
    ),
  ];

  static final List<SyllabusPaper> papers = [
    SyllabusPaper(
      id: 'group-iii-paper-i',
      title: 'Paper-I',
      syllabusUnits: paperIUnits,
    ),
    SyllabusPaper(
      id: 'group-iii-paper-ii',
      title: 'Paper-II',
      parts: paperIIParts,
    ),
    SyllabusPaper(
      id: 'group-iii-paper-iii',
      title: 'Paper-III',
      parts: paperIIIParts,
    ),
  ];
}
