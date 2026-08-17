import 'models/syllabus_models.dart';

/// Canonical Group-II syllabus data generated from the approved mapping document.
abstract final class CanonicalGroupIISyllabusData {
  static const sourceType = 'application_decomposition';

  /// Copies official Topic nodes onto [SyllabusPart.syllabusUnits] without
  /// dropping the existing Topic → Lesson tree (needed by old progress,
  /// bookmarks, revision, questions, and tests).
  static List<SyllabusPart> _withPartSyllabusUnits(List<SyllabusPart> parts) {
    return [
      for (final part in parts)
        SyllabusPart(
          id: part.id,
          officialName: part.officialName,
          displayName: part.displayName,
          topics: part.topics,
          syllabusUnits: [
            for (final topic in part.topics)
              SyllabusUnit(
                id: topic.id,
                officialName: topic.resolvedOfficialName,
                displayName: topic.resolvedDisplayName,
              ),
          ],
        ),
    ];
  }

  static final List<SyllabusMajorStudyArea> paperIMajorStudyAreas = [
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-01",
      officialName: "Current Affairs – Regional, National & International.",
      displayName: "Current Affairs",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-01-topic-01",
          officialName: "Current Affairs – Regional, National & International.",
          displayName: "Current Affairs",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-02",
      officialName: "International Relations and Events.",
      displayName: "International Relations",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-02-topic-01",
          officialName: "International Relations and Events.",
          displayName: "International Relations",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-03",
      officialName:
          "General Science; India’s Achievements in Science and Technology",
      displayName: "General Science and Technology",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-03-topic-01",
          officialName:
              "General Science; India’s Achievements in Science and Technology",
          displayName: "General Science and Technology",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-04",
      officialName:
          "Environmental Issues; Disaster Management - Prevention and Mitigation Strategies.",
      displayName: "Environment and Disaster Management",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-04-topic-01",
          officialName:
              "Environmental Issues; Disaster Management - Prevention and Mitigation Strategies.",
          displayName: "Environment and Disaster Management",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-05",
      officialName:
          "World Geography, Indian Geography and Geography of Telangana State.",
      displayName: "Geography",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-05-topic-01",
          officialName:
              "World Geography, Indian Geography and Geography of Telangana State.",
          displayName: "Geography",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-06",
      officialName: "History and Cultural Heritage of India.",
      displayName: "Indian History and Heritage",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-06-topic-01",
          officialName: "History and Cultural Heritage of India.",
          displayName: "Indian History and Heritage",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-07",
      officialName:
          "Society, Culture, Heritage, Arts and Literature of Telangana.",
      displayName: "Telangana Society and Culture",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-07-topic-01",
          officialName:
              "Society, Culture, Heritage, Arts and Literature of Telangana.",
          displayName: "Telangana Society and Culture",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-08",
      officialName: "Policies of Telangana State.",
      displayName: "Telangana State Policies",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-08-topic-01",
          officialName: "Policies of Telangana State.",
          displayName: "Telangana State Policies",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-09",
      officialName: "Social Exclusion, Rights Issues and Inclusive Policies.",
      displayName: "Social Inclusion and Rights",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-09-topic-01",
          officialName:
              "Social Exclusion, Rights Issues and Inclusive Policies.",
          displayName: "Social Inclusion and Rights",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-10",
      officialName:
          "Logical Reasoning; Analytical Ability and Data Interpretation.",
      displayName: "Reasoning and Data Interpretation",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-10-topic-01",
          officialName:
              "Logical Reasoning; Analytical Ability and Data Interpretation.",
          displayName: "Reasoning and Data Interpretation",
        ),
      ],
    ),
    SyllabusMajorStudyArea(
      id: "group-ii-paper-i-area-11",
      officialName: "Basic English. ( 10th Class Standard)",
      displayName: "Basic English",
      contentTopics: [
        SyllabusContentTopic(
          id: "group-ii-paper-i-area-11-topic-01",
          officialName: "Basic English. ( 10th Class Standard)",
          displayName: "Basic English",
        ),
      ],
    ),
  ];

  /// Paper-I student units: one official Topic per Major Study Area.
  ///
  /// Uses the area ID (`group-ii-paper-i-area-NN`), not the duplicate
  /// `area-NN-topic-01` content-topic ID.
  static final List<SyllabusUnit> paperIUnits = [
    for (final area in paperIMajorStudyAreas)
      SyllabusUnit(
        id: area.id,
        officialName: area.officialName,
        displayName: area.displayName,
      ),
  ];

  static final List<SyllabusPart> paperIIParts = _withPartSyllabusUnits([
    SyllabusPart(
      id: "group-ii-paper-ii-part-01",
      officialName: "Socio-Cultural History of India and Telangana",
      displayName: "Socio-Cultural History of India and Telangana",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-ii-part-01-topic-01",
          title: "Ancient India and Early Empires",
          officialName:
              "Salient features of Indus Valley Civilization: Society and Culture. -Early and Later Vedic Culture; Religious Movements in Sixth Century B.C. – Jainism and Buddhism. Socio, Cultural and Economic Contribution during Mauryas, Guptas, Pallavas, Chalukyas and Cholas – Administrative System. Art and Architecture - Harsha and the Rajput Age.",
          displayName: "Ancient India and Early Empires",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-01",
              officialName:
                  "Salient features of Indus Valley Civilization: Society and Culture.",
              displayName: "Indus Valley Society and Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-02",
              officialName: "Early and Later Vedic Culture",
              displayName: "Vedic Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-03",
              officialName: "Religious Movements in Sixth Century B.C.",
              displayName: "Religious Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-04",
              officialName: "Jainism and Buddhism.",
              displayName: "Jainism and Buddhism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-05",
              officialName:
                  "Socio, Cultural and Economic Contribution during Mauryas",
              displayName: "Mauryan Contributions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-06",
              officialName: "Guptas",
              displayName: "Gupta Contributions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-07",
              officialName: "Pallavas",
              displayName: "Pallava Contributions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-08",
              officialName: "Chalukyas",
              displayName: "Chalukya Contributions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-09",
              officialName: "Cholas",
              displayName: "Chola Contributions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-10",
              officialName: "Administrative System.",
              displayName: "Administrative Systems",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-11",
              officialName: "Art and Architecture",
              displayName: "Art and Architecture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-01-lesson-12",
              officialName: "Harsha and the Rajput Age.",
              displayName: "Harsha and Rajput Age",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-01-topic-02",
          title: "Medieval India",
          officialName:
              "The Establishment of Delhi Sultanate-Socio-Economic, Cultural Conditions and Administrative System under the Sultanate –Sufi and Bhakti Movements. The Mughals: Socio-Economic and Cultural Conditions; Language, Literature, Art and Architecture. Rise of Marathas and their contribution to Culture; Socio-Economic, Cultural conditions in the Deccan under the Bahamani’s and Vijayanagara -Literature, Art and Architecture.",
          displayName: "Medieval India",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-01",
              officialName: "The Establishment of Delhi Sultanate",
              displayName: "Delhi Sultanate",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-02",
              officialName:
                  "Socio-Economic, Cultural Conditions and Administrative System under the Sultanate",
              displayName: "Sultanate Society and Administration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-03",
              officialName: "Sufi and Bhakti Movements.",
              displayName: "Sufi and Bhakti Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-04",
              officialName:
                  "The Mughals: Socio-Economic and Cultural Conditions",
              displayName: "Mughal Society and Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-05",
              officialName: "Language, Literature, Art and Architecture.",
              displayName: "Mughal Language, Literature and Arts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-06",
              officialName:
                  "Rise of Marathas and their contribution to Culture",
              displayName: "Marathas and Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-07",
              officialName:
                  "Socio-Economic, Cultural conditions in the Deccan under the Bahamani’s and Vijayanagara",
              displayName: "Bahamani and Vijayanagara Deccan",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-02-lesson-08",
              officialName: "Literature, Art and Architecture.",
              displayName: "Deccan Literature, Art and Architecture",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-01-topic-03",
          title: "Colonial Rule and Freedom Movement",
          officialName:
              "Advent of Europeans: Rise and Expansion of British Rule: Socio-Economic and Cultural Policies - Cornwallis, Wellesley, William Bentinck, Dalhousie and others. The Rise of Socio-Religious Reform Movements in the Nineteenth Century. Social Protest Movements in India –Jotiba and Savithribai Phule, Ayyankali, Narayana Guru, Periyar Ramaswamy Naicker, Gandhi, Ambedkar etc. Indian Freedom Movement – 1885-1947.",
          displayName: "Colonial Rule and Freedom Movement",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-01",
              officialName: "Advent of Europeans",
              displayName: "European Advent",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-02",
              officialName: "Rise and Expansion of British Rule",
              displayName: "British Rule",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-03",
              officialName: "Socio-Economic and Cultural Policies",
              displayName: "British Socio-Economic Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-04",
              officialName: "Cornwallis",
              displayName: "Cornwallis",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-05",
              officialName: "Wellesley",
              displayName: "Wellesley",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-06",
              officialName: "William Bentinck",
              displayName: "William Bentinck",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-07",
              officialName: "Dalhousie and others",
              displayName: "Dalhousie and Others",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-08",
              officialName:
                  "The Rise of Socio-Religious Reform Movements in the Nineteenth Century.",
              displayName: "Socio-Religious Reform",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-09",
              officialName: "Social Protest Movements in India",
              displayName: "Social Protest Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-10",
              officialName: "Jotiba and Savithribai Phule",
              displayName: "Phule Reformers",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-11",
              officialName: "Ayyankali",
              displayName: "Ayyankali",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-12",
              officialName: "Narayana Guru",
              displayName: "Narayana Guru",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-13",
              officialName: "Periyar Ramaswamy Naicker",
              displayName: "Periyar Ramaswamy Naicker",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-14",
              officialName: "Gandhi",
              displayName: "Gandhi",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-15",
              officialName: "Ambedkar etc.",
              displayName: "Ambedkar and Others",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-03-lesson-16",
              officialName: "Indian Freedom Movement – 1885-1947.",
              displayName: "Indian Freedom Movement",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-01-topic-04",
          title: "Ancient and Medieval Telangana",
          officialName:
              "Socio-Economic and Cultural conditions in Ancient Telangana Satavahanas, Ikshvakus, Vishnukundins, Mudigonda and Vemulawada Chalukyas. Religion, Language, Literature, Art and Architecture; Medieval Telangana - Contribution of Kakatiyas, Rachakonda and Devarakonda Velamas, Qutub Shahis; Socio – Economic and Cultural developments: Emergence of Composite Culture. Fairs, Festivals, Moharram, Urs, Jataras etc.",
          displayName: "Ancient and Medieval Telangana",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-01",
              officialName:
                  "Socio-Economic and Cultural conditions in Ancient Telangana",
              displayName: "Ancient Telangana Society",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-02",
              officialName: "Satavahanas",
              displayName: "Satavahanas",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-03",
              officialName: "Ikshvakus",
              displayName: "Ikshvakus",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-04",
              officialName: "Vishnukundins",
              displayName: "Vishnukundins",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-05",
              officialName: "Mudigonda and Vemulawada Chalukyas",
              displayName: "Telangana Chalukyas",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-06",
              officialName: "Religion",
              displayName: "Religion",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-07",
              officialName: "Language",
              displayName: "Language",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-08",
              officialName: "Literature",
              displayName: "Literature",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-09",
              officialName: "Art and Architecture",
              displayName: "Art and Architecture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-10",
              officialName: "Medieval Telangana",
              displayName: "Medieval Telangana",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-11",
              officialName: "Contribution of Kakatiyas",
              displayName: "Kakatiyas",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-12",
              officialName: "Rachakonda and Devarakonda Velamas",
              displayName: "Rachakonda and Devarakonda Velamas",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-13",
              officialName: "Qutub Shahis",
              displayName: "Qutub Shahis",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-14",
              officialName: "Socio – Economic and Cultural developments",
              displayName: "Socio-Economic and Cultural Development",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-15",
              officialName: "Emergence of Composite Culture",
              displayName: "Composite Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-16",
              officialName: "Fairs",
              displayName: "Fairs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-17",
              officialName: "Festivals",
              displayName: "Festivals",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-18",
              officialName: "Moharram",
              displayName: "Moharram",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-19",
              officialName: "Urs",
              displayName: "Urs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-04-lesson-20",
              officialName: "Jataras etc.",
              displayName: "Jataras and Others",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-01-topic-05",
          title: "Asaf Jahi Telangana",
          officialName:
              "Foundation of AsafJahi Dynasty- from Nizam –ul- Mulk to Mir Osaman Ali Khan - SalarJung Reforms; Social and Economic conditions-Jagirdars, Zamindars, Deshmuks, and Doras- Vetti and Bhagela system and position of Women. Rise of Socio-Cultural Movements in Telangana: Arya Samaj, Andhra Maha Sabha, Andhra Mahila Sabha, Adi-Hindu Movements, Literary and Library Movements. Tribal and Peasant Revolts: Ramji Gond, Kumaram Bheemu, and Telangana Peasant Armed Struggle – Police Action and the End of Nizam Rule.",
          displayName: "Asaf Jahi Telangana",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-01",
              officialName: "Foundation of AsafJahi Dynasty",
              displayName: "Asaf Jahi Dynasty",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-02",
              officialName: "from Nizam –ul- Mulk to Mir Osaman Ali Khan",
              displayName: "Nizam-ul-Mulk to Mir Osman Ali Khan",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-03",
              officialName: "SalarJung Reforms",
              displayName: "Salar Jung Reforms",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-04",
              officialName: "Social and Economic conditions",
              displayName: "Social and Economic Conditions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-05",
              officialName: "Jagirdars",
              displayName: "Jagirdars",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-06",
              officialName: "Zamindars",
              displayName: "Zamindars",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-07",
              officialName: "Deshmuks",
              displayName: "Deshmuks",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-08",
              officialName: "Doras",
              displayName: "Doras",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-09",
              officialName: "Vetti and Bhagela system",
              displayName: "Vetti and Bhagela",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-10",
              officialName: "position of Women",
              displayName: "Women",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-11",
              officialName: "Rise of Socio-Cultural Movements in Telangana",
              displayName: "Telangana Socio-Cultural Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-12",
              officialName: "Arya Samaj",
              displayName: "Arya Samaj",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-13",
              officialName: "Andhra Maha Sabha",
              displayName: "Andhra Maha Sabha",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-14",
              officialName: "Andhra Mahila Sabha",
              displayName: "Andhra Mahila Sabha",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-15",
              officialName: "Adi-Hindu Movements",
              displayName: "Adi-Hindu Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-16",
              officialName: "Literary and Library Movements",
              displayName: "Literary and Library Movements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-17",
              officialName: "Tribal and Peasant Revolts",
              displayName: "Tribal and Peasant Revolts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-18",
              officialName: "Ramji Gond",
              displayName: "Ramji Gond",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-19",
              officialName: "Kumaram Bheemu",
              displayName: "Kumaram Bheemu",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-20",
              officialName: "Telangana Peasant Armed Struggle",
              displayName: "Telangana Peasant Armed Struggle",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-21",
              officialName: "Police Action",
              displayName: "Police Action",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-01-topic-05-lesson-22",
              officialName: "the End of Nizam Rule",
              displayName: "End of Nizam Rule",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-ii-part-02",
      officialName: "Overview of the Indian Constitution and Politics",
      displayName: "Overview of the Indian Constitution and Politics",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-01",
          title: "Evolution and Features",
          officialName:
              "Evolution of the Indian Constitution – Nature and salient features – Preamble.",
          displayName: "Evolution and Features",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-01-lesson-01",
              officialName: "Evolution of the Indian Constitution",
              displayName: "Constitutional Evolution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-01-lesson-02",
              officialName: "Nature and salient features",
              displayName: "Nature and Features",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-01-lesson-03",
              officialName: "Preamble",
              displayName: "Preamble",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-02",
          title: "Rights, Principles and Duties",
          officialName:
              "Fundamental Rights – Directive Principles of the State Policy – Fundamental Duties.",
          displayName: "Rights, Principles and Duties",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-02-lesson-01",
              officialName: "Fundamental Rights",
              displayName: "Fundamental Rights",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-02-lesson-02",
              officialName: "Directive Principles of the State Policy",
              displayName: "Directive Principles",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-02-lesson-03",
              officialName: "Fundamental Duties",
              displayName: "Fundamental Duties",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-03",
          title: "Indian Federalism",
          officialName:
              "Distinctive Features of the Indian Federalism – Distribution of Legislative, Financial and Administrative Powers between the Union and States.",
          displayName: "Indian Federalism",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-03-lesson-01",
              officialName: "Distinctive Features of the Indian Federalism",
              displayName: "Federal Features",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-03-lesson-02",
              officialName:
                  "Distribution of Legislative Powers between the Union and States",
              displayName: "Legislative Powers",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-03-lesson-03",
              officialName:
                  "Distribution of Financial and Administrative Powers between the Union and States",
              displayName: "Financial and Administrative Powers",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-04",
          title: "Union and State Government",
          officialName:
              "Union and State Government – President – Prime Minister and Council of Ministers; Governor, Chief Minister and Council of Ministers – Powers and Functions.",
          displayName: "Union and State Government",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-04-lesson-01",
              officialName: "President",
              displayName: "President",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-04-lesson-02",
              officialName: "Prime Minister and Council of Ministers",
              displayName: "Prime Minister and Council",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-04-lesson-03",
              officialName: "Governor",
              displayName: "Governor",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-04-lesson-04",
              officialName: "Chief Minister and Council of Ministers",
              displayName: "Chief Minister and Council",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-04-lesson-05",
              officialName: "Powers and Functions",
              displayName: "Powers and Functions",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-05",
          title: "Constitutional Amendments",
          officialName:
              "Indian Constitution; Amendment Procedures and Amendment Acts.",
          displayName: "Constitutional Amendments",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-05-lesson-01",
              officialName: "Indian Constitution",
              displayName: "Indian Constitution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-05-lesson-02",
              officialName: "Amendment Procedures",
              displayName: "Amendment Procedures",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-05-lesson-03",
              officialName: "Amendment Acts",
              displayName: "Amendment Acts",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-06",
          title: "Rural and Urban Governance",
          officialName:
              "Rural and Urban Governance with special reference to the 73 rd th and 74 Amendment Acts.",
          displayName: "Rural and Urban Governance",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-06-lesson-01",
              officialName: "Rural and Urban Governance",
              displayName: "Local Governance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-06-lesson-02",
              officialName: "73 rd Amendment Acts",
              displayName: "73rd Amendment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-06-lesson-03",
              officialName: "74 Amendment Acts",
              displayName: "74th Amendment",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-07",
          title: "Electoral Mechanism",
          officialName:
              "Electoral Mechanism: Electoral Laws, Election Commission, Political Parties, Anti defection Law and Electoral Reforms.",
          displayName: "Electoral Mechanism",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-01",
              officialName: "Electoral Mechanism",
              displayName: "Electoral Mechanism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-02",
              officialName: "Electoral Laws",
              displayName: "Electoral Laws",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-03",
              officialName: "Election Commission",
              displayName: "Election Commission",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-04",
              officialName: "Political Parties",
              displayName: "Political Parties",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-05",
              officialName: "Anti defection Law",
              displayName: "Anti-Defection Law",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-07-lesson-06",
              officialName: "Electoral Reforms",
              displayName: "Electoral Reforms",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-08",
          title: "Judicial System",
          officialName:
              "Judicial System in India – Judicial Review; Judicial Activism; Supreme Court and High Courts.",
          displayName: "Judicial System",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-08-lesson-01",
              officialName: "Judicial System in India",
              displayName: "Judicial System",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-08-lesson-02",
              officialName: "Judicial Review",
              displayName: "Judicial Review",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-08-lesson-03",
              officialName: "Judicial Activism",
              displayName: "Judicial Activism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-08-lesson-04",
              officialName: "Supreme Court and High Courts",
              displayName: "Supreme Court and High Courts",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-09",
          title: "Special Provisions and Commissions",
          officialName:
              "a) Special Constitutional Provisions for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Economically Weaker Sections (EWS). b) National Commissions for the Enforcement – National Commission for Scheduled Castes, Scheduled Tribes, Backward Classes, Women, Minorities and Human Rights.",
          displayName: "Special Provisions and Commissions",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-01",
              officialName:
                  "Special Constitutional Provisions for Scheduled Castes",
              displayName: "Scheduled Castes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-02",
              officialName: "Scheduled Tribes",
              displayName: "Scheduled Tribes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-03",
              officialName: "Backward Classes",
              displayName: "Backward Classes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-04",
              officialName: "Women",
              displayName: "Women",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-05",
              officialName: "Minorities",
              displayName: "Minorities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-06",
              officialName: "Economically Weaker Sections (EWS)",
              displayName: "EWS",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-07",
              officialName: "National Commission for Scheduled Castes",
              displayName: "NCSC",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-08",
              officialName: "National Commission for Scheduled Tribes",
              displayName: "NCST",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-09",
              officialName: "National Commission for Backward Classes",
              displayName: "NCBC",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-10",
              officialName: "National Commission for Women",
              displayName: "NCW",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-11",
              officialName: "National Commission for Minorities",
              displayName: "NCM",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-09-lesson-12",
              officialName: "National Human Rights Commission",
              displayName: "NHRC",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-02-topic-10",
          title: "National Integration",
          officialName:
              "National Integration issues and challenges: Insurgency; Internal Security; Inter-State Disputes.",
          displayName: "National Integration",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-10-lesson-01",
              officialName: "National Integration issues and challenges",
              displayName: "Integration Issues",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-10-lesson-02",
              officialName: "Insurgency",
              displayName: "Insurgency",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-10-lesson-03",
              officialName: "Internal Security",
              displayName: "Internal Security",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-02-topic-10-lesson-04",
              officialName: "Inter-State Disputes",
              displayName: "Inter-State Disputes",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-ii-part-03",
      officialName: "Social Structure, Issues and Public Policies",
      displayName: "Social Structure, Issues and Public Policies",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-ii-part-03-topic-01",
          title: "Indian Social Structure",
          officialName:
              "Indian Social Structure: Salient Features of Indian society: Family, Marriage, Kinship, Caste, Tribe, Ethnicity, Religion and Women.",
          displayName: "Indian Social Structure",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-01",
              officialName: "Family",
              displayName: "Family",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-02",
              officialName: "Marriage",
              displayName: "Marriage",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-03",
              officialName: "Kinship",
              displayName: "Kinship",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-04",
              officialName: "Caste",
              displayName: "Caste",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-05",
              officialName: "Tribe",
              displayName: "Tribe",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-06",
              officialName: "Ethnicity",
              displayName: "Ethnicity",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-07",
              officialName: "Religion",
              displayName: "Religion",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-01-lesson-08",
              officialName: "Women",
              displayName: "Women",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-03-topic-02",
          title: "Social Issues",
          officialName:
              "Social Issues: Inequality and Exclusion: Casteism, Communalism, Regionalism, Violence against Women, Child Labour, Human trafficking, Disability, Aged and Third / Trans-Gender Issues.",
          displayName: "Social Issues",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-01",
              officialName: "Inequality and Exclusion",
              displayName: "Inequality and Exclusion",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-02",
              officialName: "Casteism",
              displayName: "Casteism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-03",
              officialName: "Communalism",
              displayName: "Communalism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-04",
              officialName: "Regionalism",
              displayName: "Regionalism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-05",
              officialName: "Violence against Women",
              displayName: "Violence against Women",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-06",
              officialName: "Child Labour",
              displayName: "Child Labour",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-07",
              officialName: "Human trafficking",
              displayName: "Human Trafficking",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-08",
              officialName: "Disability",
              displayName: "Disability",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-09",
              officialName: "Aged",
              displayName: "Aged",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-02-lesson-10",
              officialName: "Third / Trans-Gender Issues",
              displayName: "Third / Trans-Gender Issues",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-03-topic-03",
          title: "Social Movements",
          officialName:
              "Social Movements: Peasant Movement, Tribal movement, Backward Classes Movement, Dalit Movement, Environmental Movement, Women’s Movement, Regional Autonomy Movement, Human Rights / Civil Rights Movement.",
          displayName: "Social Movements",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-01",
              officialName: "Peasant Movement",
              displayName: "Peasant Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-02",
              officialName: "Tribal movement",
              displayName: "Tribal Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-03",
              officialName: "Backward Classes Movement",
              displayName: "Backward Classes Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-04",
              officialName: "Dalit Movement",
              displayName: "Dalit Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-05",
              officialName: "Environmental Movement",
              displayName: "Environmental Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-06",
              officialName: "Women’s Movement",
              displayName: "Women’s Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-07",
              officialName: "Regional Autonomy Movement",
              displayName: "Regional Autonomy Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-03-lesson-08",
              officialName: "Human Rights / Civil Rights Movement",
              displayName: "Human and Civil Rights",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-03-topic-04",
          title: "Social Policies and Welfare",
          officialName:
              "Social Policies and Welfare Programmes: Affirmative Policies for SCs, STs, OBC, Women, Minorities, Labour, Disabled and Children; Welfare Programmes: Employment, Poverty Alleviation Programmes; Rural and Urban, Women and Child Welfare, Tribal Welfare.",
          displayName: "Social Policies and Welfare",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-01",
              officialName: "Affirmative Policies for SCs",
              displayName: "SC Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-02",
              officialName: "ST",
              displayName: "ST Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-03",
              officialName: "OBC",
              displayName: "OBC Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-04",
              officialName: "Women",
              displayName: "Women’s Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-05",
              officialName: "Minorities",
              displayName: "Minority Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-06",
              officialName: "Labour",
              displayName: "Labour Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-07",
              officialName: "Disabled",
              displayName: "Disability Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-08",
              officialName: "Children",
              displayName: "Children’s Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-09",
              officialName: "Employment",
              displayName: "Employment Programmes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-10",
              officialName: "Poverty Alleviation Programmes",
              displayName: "Poverty Alleviation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-11",
              officialName: "Rural and Urban",
              displayName: "Rural and Urban Welfare",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-12",
              officialName: "Women and Child Welfare",
              displayName: "Women and Child Welfare",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-04-lesson-13",
              officialName: "Tribal Welfare",
              displayName: "Tribal Welfare",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-ii-part-03-topic-05",
          title: "Society in Telangana",
          officialName:
              "Society in Telangana: Socio- Cultural Features and Issues in Telangana; Vetti, Jogini, Devadasi System, Child Labour, Girl Child, Flourosis, Migration, Farmer’s; Artisanal and Service Communities in Distress.",
          displayName: "Society in Telangana",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-01",
              officialName: "Socio- Cultural Features and Issues in Telangana",
              displayName: "Telangana Socio-Cultural Features",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-02",
              officialName: "Vetti",
              displayName: "Vetti",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-03",
              officialName: "Jogini",
              displayName: "Jogini",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-04",
              officialName: "Devadasi System",
              displayName: "Devadasi System",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-05",
              officialName: "Child Labour",
              displayName: "Child Labour",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-06",
              officialName: "Girl Child",
              displayName: "Girl Child",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-07",
              officialName: "Flourosis",
              displayName: "Flourosis",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-08",
              officialName: "Migration",
              displayName: "Migration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-09",
              officialName: "Farmer’s",
              displayName: "Farmers in Distress",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-ii-part-03-topic-05-lesson-10",
              officialName: "Artisanal and Service Communities in Distress",
              displayName: "Artisanal and Service Communities",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
  ]);

  static final List<SyllabusPart> paperIIIParts = _withPartSyllabusUnits([
    SyllabusPart(
      id: "group-ii-paper-iii-part-01",
      officialName: "Indian Economy: Issues and Challenges",
      displayName: "Indian Economy: Issues and Challenges",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iii-part-01-topic-01",
          title: "Demography",
          officialName:
              "Demography: Demographic Features of Indian Population – Size and Growth Rate of Population – Demographic Dividend – Sectoral Distribution of Population – Population Policies of India",
          displayName: "Demography",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-01-lesson-01",
              officialName: "Demographic Features of Indian Population",
              displayName: "Indian Population",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-01-lesson-02",
              officialName: "Size and Growth Rate of Population",
              displayName: "Population Size and Growth",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-01-lesson-03",
              officialName: "Demographic Dividend",
              displayName: "Demographic Dividend",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-01-lesson-04",
              officialName: "Sectoral Distribution of Population",
              displayName: "Population Distribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-01-lesson-05",
              officialName: "Population Policies of India",
              displayName: "Population Policies",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-01-topic-02",
          title: "National Income",
          officialName:
              "National Income: Concepts & Components of National Income – Measurement Methods – National Income Estimates in India and its Trends – Sectoral Contribution – Per Capita Income",
          displayName: "National Income",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-02-lesson-01",
              officialName: "Concepts & Components of National Income",
              displayName: "Concepts and Components",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-02-lesson-02",
              officialName: "Measurement Methods",
              displayName: "Measurement Methods",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-02-lesson-03",
              officialName: "National Income Estimates in India and its Trends",
              displayName: "Estimates and Trends",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-02-lesson-04",
              officialName: "Sectoral Contribution",
              displayName: "Sectoral Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-02-lesson-05",
              officialName: "Per Capita Income",
              displayName: "Per Capita Income",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-01-topic-03",
          title: "Primary and Secondary Sectors",
          officialName:
              "Primary and Secondary Sectors: Agriculture and Allied Sectors – Contribution to National Income – Cropping Pattern – Agricultural Production and Productivity – Green Revelation – Irrigation – Agricultural Finance and Marketing – Agricultural Pricing – Agricultural Subsidies and Food Security – Agricultural Labour – Growth and Performance of Allied Sectors",
          displayName: "Primary and Secondary Sectors",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-01",
              officialName: "Agriculture and Allied Sectors",
              displayName: "Agriculture and Allied Sectors",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-02",
              officialName: "Contribution to National Income",
              displayName: "National Income Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-03",
              officialName: "Cropping Pattern",
              displayName: "Cropping Pattern",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-04",
              officialName: "Agricultural Production and Productivity",
              displayName: "Agricultural Production and Productivity",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-05",
              officialName: "Green Revelation",
              displayName: "Green Revelation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-06",
              officialName: "Irrigation",
              displayName: "Irrigation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-07",
              officialName: "Agricultural Finance and Marketing",
              displayName: "Agricultural Finance and Marketing",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-08",
              officialName: "Agricultural Pricing",
              displayName: "Agricultural Pricing",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-09",
              officialName: "Agricultural Subsidies and Food Security",
              displayName: "Subsidies and Food Security",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-10",
              officialName: "Agricultural Labour",
              displayName: "Agricultural Labour",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-03-lesson-11",
              officialName: "Growth and Performance of Allied Sectors",
              displayName: "Allied Sector Performance",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-01-topic-04",
          title: "Industry and Services",
          officialName:
              "Industry and Services Sectors: Growth and Structure of Industry in India – Contribution to National Income –Industrial Policies – Large Scale Industries – MSMEs – Industrial Finance – Contribution of Services Sector to National Income – Importance of Services Sector – Sub Sectors of Services – Economic Infrastructure – India’s Foreign Trade",
          displayName: "Industry and Services",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-01",
              officialName: "Growth and Structure of Industry in India",
              displayName: "Industry Growth and Structure",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-02",
              officialName: "Contribution to National Income",
              displayName: "Industry National Income Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-03",
              officialName: "Industrial Policies",
              displayName: "Industrial Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-04",
              officialName: "Large Scale Industries",
              displayName: "Large-Scale Industries",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-05",
              officialName: "MSMEs",
              displayName: "MSMEs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-06",
              officialName: "Industrial Finance",
              displayName: "Industrial Finance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-07",
              officialName:
                  "Contribution of Services Sector to National Income",
              displayName: "Services National Income Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-08",
              officialName: "Importance of Services Sector",
              displayName: "Services Importance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-09",
              officialName: "Sub Sectors of Services",
              displayName: "Services Subsectors",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-10",
              officialName: "Economic Infrastructure",
              displayName: "Economic Infrastructure",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-04-lesson-11",
              officialName: "India’s Foreign Trade",
              displayName: "Foreign Trade",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-01-topic-05",
          title: "Planning and Public Finance",
          officialName:
              "Planning, NITI Aayog and Public Finance: Objectives of India’s Five Year Plans – Targets, Achievements and Failures of Five Year Plans – NITI Aayog – Budget in India – Concepts of Budget Deficits – FRBM – Recent Union Budgets – Public Revenue, Public Expenditure and Public Debt – Finance Commissions",
          displayName: "Planning and Public Finance",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-01",
              officialName: "Objectives of India’s Five Year Plans",
              displayName: "Plan Objectives",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-02",
              officialName: "Targets",
              displayName: "Plan Targets",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-03",
              officialName: "Achievements",
              displayName: "Plan Achievements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-04",
              officialName: "Failures of Five Year Plans",
              displayName: "Plan Failures",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-05",
              officialName: "NITI Aayog",
              displayName: "NITI Aayog",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-06",
              officialName: "Budget in India",
              displayName: "Indian Budget",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-07",
              officialName: "Concepts of Budget Deficits",
              displayName: "Budget Deficits",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-08",
              officialName: "FRBM",
              displayName: "FRBM",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-09",
              officialName: "Recent Union Budgets",
              displayName: "Recent Union Budgets",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-10",
              officialName: "Public Revenue",
              displayName: "Public Revenue",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-11",
              officialName: "Public Expenditure",
              displayName: "Public Expenditure",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-12",
              officialName: "Public Debt",
              displayName: "Public Debt",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-01-topic-05-lesson-13",
              officialName: "Finance Commissions",
              displayName: "Finance Commissions",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-iii-part-02",
      officialName: "Economy and Development of Telangana",
      displayName: "Economy and Development of Telangana",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iii-part-02-topic-01",
          title: "Telangana Economy Structure and Growth",
          officialName:
              "Structure and Growth of Telangana Economy: Telangana Economy in Undivided Andhra Pradesh (1956-2014) – State Finances ( Dhar Commission, Wanchu Committee, Lalit Committee, Bhargava Committee) – Land Reforms -Growth and Development of Telangana Economy Since 2014 – Sectoral Contribution to State Income – Per Capita Income",
          displayName: "Telangana Economy Structure and Growth",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-01",
              officialName:
                  "Telangana Economy in Undivided Andhra Pradesh (1956-2014)",
              displayName: "Undivided Andhra Pradesh Economy",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-02",
              officialName: "State Finances",
              displayName: "State Finances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-03",
              officialName: "Dhar Commission",
              displayName: "Dhar Commission",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-04",
              officialName: "Wanchu Committee",
              displayName: "Wanchu Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-05",
              officialName: "Lalit Committee",
              displayName: "Lalit Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-06",
              officialName: "Bhargava Committee",
              displayName: "Bhargava Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-07",
              officialName: "Land Reforms",
              displayName: "Land Reforms",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-08",
              officialName:
                  "Growth and Development of Telangana Economy Since 2014",
              displayName: "Telangana Economy Since 2014",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-09",
              officialName: "Sectoral Contribution to State Income",
              displayName: "Sectoral State Income",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-01-lesson-10",
              officialName: "Per Capita Income",
              displayName: "Per Capita Income",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-02-topic-02",
          title: "Telangana Demography and HRD",
          officialName:
              "Demography and HRD: Size and Growth Rate of Population – Demographic Features of Telangana Economy – Age Structure of Population – Demographic Dividend.",
          displayName: "Telangana Demography and HRD",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-02-lesson-01",
              officialName: "Size and Growth Rate of Population",
              displayName: "Population Size and Growth",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-02-lesson-02",
              officialName: "Demographic Features of Telangana Economy",
              displayName: "Telangana Demography",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-02-lesson-03",
              officialName: "Age Structure of Population",
              displayName: "Age Structure",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-02-lesson-04",
              officialName: "Demographic Dividend",
              displayName: "Demographic Dividend",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-02-topic-03",
          title: "Telangana Agriculture and Allied Sectors",
          officialName:
              "Agriculture and Allied Sectors: Importance of Agriculture – Trends in Growth Rate of Agriculture – Contribution of Agriculture and Allied Sectors to GSDP/GSVA – Land Use and Land Holdings Pattern – Cropping Pattern – Irrigation – Growth and Development of Allied Sectors – Agricultural Policies and Programmes",
          displayName: "Telangana Agriculture and Allied Sectors",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-01",
              officialName: "Importance of Agriculture",
              displayName: "Agriculture Importance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-02",
              officialName: "Trends in Growth Rate of Agriculture",
              displayName: "Agricultural Growth",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-03",
              officialName:
                  "Contribution of Agriculture and Allied Sectors to GSDP/GSVA",
              displayName: "Agriculture and Allied Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-04",
              officialName: "Land Use",
              displayName: "Land Use",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-05",
              officialName: "Land Holdings Pattern",
              displayName: "Land Holdings",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-06",
              officialName: "Cropping Pattern",
              displayName: "Cropping Pattern",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-07",
              officialName: "Irrigation",
              displayName: "Irrigation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-08",
              officialName: "Growth and Development of Allied Sectors",
              displayName: "Allied Sector Development",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-03-lesson-09",
              officialName: "Agricultural Policies and Programmes",
              displayName: "Agricultural Policies and Programmes",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-02-topic-04",
          title: "Telangana Industry and Services",
          officialName:
              "Industry and Service Sectors: Structure and Growth of Industry – Contribution of Industry to GSDP/GSVA – MSME – Industrial Policies – Components, Structure and Growth of Services Sector – Its Contribution to GSDP/GSVA – Social and Economic Infrastructure",
          displayName: "Telangana Industry and Services",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-01",
              officialName: "Structure and Growth of Industry",
              displayName: "Industry Structure and Growth",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-02",
              officialName: "Contribution of Industry to GSDP/GSVA",
              displayName: "Industry Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-03",
              officialName: "MSME",
              displayName: "MSME",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-04",
              officialName: "Industrial Policies",
              displayName: "Industrial Policies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-05",
              officialName:
                  "Components, Structure and Growth of Services Sector",
              displayName: "Services Structure and Growth",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-06",
              officialName: "Its Contribution to GSDP/GSVA",
              displayName: "Services Contribution",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-04-lesson-07",
              officialName: "Social and Economic Infrastructure",
              displayName: "Social and Economic Infrastructure",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-02-topic-05",
          title: "Telangana State Finances and Welfare",
          officialName:
              "State Finances, Budget and Welfare Policies: State Revenue, Expenditure and Debt – State Budgets – Welfare Policies of the State",
          displayName: "Telangana State Finances and Welfare",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-05-lesson-01",
              officialName: "State Revenue, Expenditure and Debt",
              displayName: "State Revenue, Expenditure and Debt",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-05-lesson-02",
              officialName: "State Budgets",
              displayName: "State Budgets",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-02-topic-05-lesson-03",
              officialName: "Welfare Policies of the State",
              displayName: "State Welfare Policies",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-iii-part-03",
      officialName: "Issues of Development and Change",
      displayName: "Issues of Development and Change",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iii-part-03-topic-01",
          title: "Growth and Development",
          officialName:
              "Growth and Development: Concepts of Growth and Development – Characteristics of Development and Underdevelopment – Measurement of Economic Growth and Development – Human Development – Human Development Indices – Human Development Reports",
          displayName: "Growth and Development",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-01",
              officialName: "Concepts of Growth and Development",
              displayName: "Growth and Development Concepts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-02",
              officialName:
                  "Characteristics of Development and Underdevelopment",
              displayName: "Development and Underdevelopment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-03",
              officialName: "Measurement of Economic Growth and Development",
              displayName: "Growth and Development Measurement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-04",
              officialName: "Human Development",
              displayName: "Human Development",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-05",
              officialName: "Human Development Indices",
              displayName: "Human Development Indices",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-01-lesson-06",
              officialName: "Human Development Reports",
              displayName: "Human Development Reports",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-03-topic-02",
          title: "Social Development",
          officialName:
              "Social Development: Social Infrastructure – Health and Education – Social Sector – Social Inequalities – Caste – Gender – Religion – Social Transformation – Social Security",
          displayName: "Social Development",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-01",
              officialName: "Social Infrastructure",
              displayName: "Social Infrastructure",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-02",
              officialName: "Health and Education",
              displayName: "Health and Education",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-03",
              officialName: "Social Sector",
              displayName: "Social Sector",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-04",
              officialName: "Social Inequalities",
              displayName: "Social Inequalities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-05",
              officialName: "Caste",
              displayName: "Caste",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-06",
              officialName: "Gender",
              displayName: "Gender",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-07",
              officialName: "Religion",
              displayName: "Religion",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-08",
              officialName: "Social Transformation",
              displayName: "Social Transformation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-02-lesson-09",
              officialName: "Social Security",
              displayName: "Social Security",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-03-topic-03",
          title: "Poverty and Unemployment",
          officialName:
              "Poverty and Unemployment: Concepts of Poverty – Measurement of Poverty – Income Inequalities - Concepts of Unemployment – Poverty, Unemployment and Welfare Programmes",
          displayName: "Poverty and Unemployment",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-01",
              officialName: "Concepts of Poverty",
              displayName: "Poverty Concepts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-02",
              officialName: "Measurement of Poverty",
              displayName: "Poverty Measurement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-03",
              officialName: "Income Inequalities",
              displayName: "Income Inequalities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-04",
              officialName: "Concepts of Unemployment",
              displayName: "Unemployment Concepts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-05",
              officialName: "Poverty",
              displayName: "Poverty",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-06",
              officialName: "Unemployment",
              displayName: "Unemployment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-03-lesson-07",
              officialName: "Welfare Programmes",
              displayName: "Welfare Programmes",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-03-topic-04",
          title: "Regional Inequalities",
          officialName:
              "Regional Inequalities: Urbanization – Migration – Land Acquisition – Resettlement and Rehabilitation",
          displayName: "Regional Inequalities",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-04-lesson-01",
              officialName: "Urbanization",
              displayName: "Urbanization",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-04-lesson-02",
              officialName: "Migration",
              displayName: "Migration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-04-lesson-03",
              officialName: "Land Acquisition",
              displayName: "Land Acquisition",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-04-lesson-04",
              officialName: "Resettlement and Rehabilitation",
              displayName: "Resettlement and Rehabilitation",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iii-part-03-topic-05",
          title: "Environment and Sustainable Development",
          officialName:
              "Concepts of Environment – Environmental Protection and Sustainable Development – Types of Pollution – Pollution Control – Effects of Environment – Environmental Policies of India",
          displayName: "Environment and Sustainable Development",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-01",
              officialName: "Concepts of Environment",
              displayName: "Environment Concepts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-02",
              officialName: "Environmental Protection",
              displayName: "Environmental Protection",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-03",
              officialName: "Sustainable Development",
              displayName: "Sustainable Development",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-04",
              officialName: "Types of Pollution",
              displayName: "Pollution Types",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-05",
              officialName: "Pollution Control",
              displayName: "Pollution Control",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-06",
              officialName: "Effects of Environment",
              displayName: "Environmental Effects",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iii-part-03-topic-05-lesson-07",
              officialName: "Environmental Policies of India",
              displayName: "Indian Environmental Policies",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
  ]);

  static final List<SyllabusPart> paperIVParts = _withPartSyllabusUnits([
    SyllabusPart(
      id: "group-ii-paper-iv-part-01",
      officialName: "The idea of Telangana (1948-1970)",
      displayName: "The idea of Telangana (1948-1970)",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iv-part-01-topic-01",
          title: "Historical Background",
          officialName:
              "Historical Background: Telangana as a distinctive cultural unit in Hyderabad Princely State, its geographical, cultural, socio, political and economic features people of Telangana- castes, tribes, religion, arts, crafts, languages, dialects, fairs, festivals and important places in Telangana. Administration in Hyderabad Princely State and Administrative Reforms of Salar Jung and Origins of the Mulki-Non-Mulki issue. Farman of 1919 and Definition of Mulki - Establishment of Nizam’s Subjects League known as the Mulki League 1935 and its Significance; Merger of Hyderabad State into Indian Union in 1948- Employment policies under Military Rule and Vellodi,1948-52; Violation of Mulki-Rules and Its Implications.",
          displayName: "Historical Background",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-01",
              officialName:
                  "Telangana as a distinctive cultural unit in Hyderabad Princely State",
              displayName: "Telangana Cultural Unit",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-02",
              officialName: "geographical features",
              displayName: "Geography",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-03",
              officialName: "cultural features",
              displayName: "Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-04",
              officialName: "socio features",
              displayName: "Society",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-05",
              officialName: "political features",
              displayName: "Politics",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-06",
              officialName: "economic features",
              displayName: "Economy",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-07",
              officialName: "castes",
              displayName: "Castes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-08",
              officialName: "tribes",
              displayName: "Tribes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-09",
              officialName: "religion",
              displayName: "Religion",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-10",
              officialName: "arts",
              displayName: "Arts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-11",
              officialName: "crafts",
              displayName: "Crafts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-12",
              officialName: "languages",
              displayName: "Languages",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-13",
              officialName: "dialects",
              displayName: "Dialects",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-14",
              officialName: "fairs",
              displayName: "Fairs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-15",
              officialName: "festivals",
              displayName: "Festivals",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-16",
              officialName: "important places in Telangana",
              displayName: "Important Places",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-17",
              officialName: "Administration in Hyderabad Princely State",
              displayName: "Hyderabad Administration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-18",
              officialName: "Administrative Reforms of Salar Jung",
              displayName: "Salar Jung Reforms",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-19",
              officialName: "Origins of the Mulki-Non-Mulki issue",
              displayName: "Mulki-Non-Mulki Origins",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-20",
              officialName: "Farman of 1919",
              displayName: "Farman of 1919",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-21",
              officialName: "Definition of Mulki",
              displayName: "Mulki Definition",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-22",
              officialName:
                  "Establishment of Nizam’s Subjects League known as the Mulki League 1935",
              displayName: "Mulki League",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-23",
              officialName: "its Significance",
              displayName: "Mulki League Significance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-24",
              officialName:
                  "Merger of Hyderabad State into Indian Union in 1948",
              displayName: "Merger into Indian Union",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-25",
              officialName: "Employment policies under Military Rule",
              displayName: "Military Rule Employment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-26",
              officialName: "Vellodi,1948-52",
              displayName: "Vellodi Administration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-27",
              officialName: "Violation of Mulki-Rules",
              displayName: "Mulki-Rules Violation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-01-lesson-28",
              officialName: "Its Implications",
              displayName: "Implications",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-01-topic-02",
          title: "Hyderabad State in Independent India",
          officialName:
              "Hyderabad State in Independent India- Formation of Popular Ministry under Burgula Ramakrishna Rao and 1952 Mulki-Agitation; Demand for Employment of Local people and City College Incident- Its importance. Justice Jagan Mohan Reddy Committee Report, 1953 – Initial debates and demand for Telangana State Reasons for the Formation of States Reorganization Commission (SRC) under Fazal Ali in 1953-Main Provisions and Recommendations of SRC-Dr. B. R. Ambedkar’s views on SRC and smaller states.",
          displayName: "Hyderabad State in Independent India",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-01",
              officialName:
                  "Formation of Popular Ministry under Burgula Ramakrishna Rao",
              displayName: "Popular Ministry",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-02",
              officialName: "1952 Mulki-Agitation",
              displayName: "1952 Mulki Agitation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-03",
              officialName: "Demand for Employment of Local people",
              displayName: "Local Employment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-04",
              officialName: "City College Incident",
              displayName: "City College Incident",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-05",
              officialName: "Its importance",
              displayName: "Incident Importance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-06",
              officialName: "Justice Jagan Mohan Reddy Committee Report, 1953",
              displayName: "Jagan Mohan Reddy Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-07",
              officialName: "Initial debates",
              displayName: "Initial Debates",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-08",
              officialName: "demand for Telangana State",
              displayName: "Telangana State Demand",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-09",
              officialName:
                  "Reasons for the Formation of States Reorganization Commission (SRC) under Fazal Ali in 1953",
              displayName: "SRC Formation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-10",
              officialName: "Main Provisions and Recommendations of SRC",
              displayName: "SRC Provisions and Recommendations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-11",
              officialName: "Dr. B. R. Ambedkar’s views on SRC",
              displayName: "Ambedkar and SRC",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-02-lesson-12",
              officialName: "smaller states",
              displayName: "Smaller States",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-01-topic-03",
          title: "Formation of Andhra Pradesh",
          officialName:
              "Formation of Andhra Pradesh, 1956: Gentlemen Agreement - its Provisions and Recommendations; Telangana Regional Committee, Composition and Functions & Performance – Violation of Safeguards-Migration from Coastal Andhra Region and its Consequences-Post-1970 development Scenario in Telangana- Agriculture, Irrigation, Power, Education, Employment, Medical and Health etc.",
          displayName: "Formation of Andhra Pradesh",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-01",
              officialName: "Gentlemen Agreement",
              displayName: "Gentlemen Agreement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-02",
              officialName: "its Provisions and Recommendations",
              displayName: "Agreement Provisions and Recommendations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-03",
              officialName: "Telangana Regional Committee",
              displayName: "Regional Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-04",
              officialName: "Composition",
              displayName: "Committee Composition",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-05",
              officialName: "Functions",
              displayName: "Committee Functions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-06",
              officialName: "Performance",
              displayName: "Committee Performance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-07",
              officialName: "Violation of Safeguards",
              displayName: "Safeguard Violations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-08",
              officialName: "Migration from Coastal Andhra Region",
              displayName: "Coastal Andhra Migration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-09",
              officialName: "its Consequences",
              displayName: "Migration Consequences",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-10",
              officialName: "Post-1970 development Scenario in Telangana",
              displayName: "Post-1970 Development",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-11",
              officialName: "Agriculture",
              displayName: "Agriculture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-12",
              officialName: "Irrigation",
              displayName: "Irrigation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-13",
              officialName: "Power",
              displayName: "Power",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-14",
              officialName: "Education",
              displayName: "Education",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-15",
              officialName: "Employment",
              displayName: "Employment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-03-lesson-16",
              officialName: "Medical and Health",
              displayName: "Medical and Health",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-01-topic-04",
          title: "Employment and Service Rules",
          officialName:
              "Violation of Employment and Service Rules: Origins of Telangana Agitation- Protest in Kothagudem and other places, Fast unto Death by Ravindranath; 1969 Agitation for Separate Telangana. Role of Intellectuals, Students, Employees in Jai Telangana Movement.",
          displayName: "Employment and Service Rules",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-01",
              officialName: "Origins of Telangana Agitation",
              displayName: "Agitation Origins",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-02",
              officialName: "Protest in Kothagudem and other places",
              displayName: "Kothagudem and Other Protests",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-03",
              officialName: "Fast unto Death by Ravindranath",
              displayName: "Ravindranath Fast",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-04",
              officialName: "1969 Agitation for Separate Telangana",
              displayName: "1969 Agitation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-05",
              officialName: "Role of Intellectuals",
              displayName: "Intellectuals",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-06",
              officialName: "Students",
              displayName: "Students",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-07",
              officialName: "Employees",
              displayName: "Employees",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-04-lesson-08",
              officialName: "Jai Telangana Movement",
              displayName: "Jai Telangana Movement",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-01-topic-05",
          title: "Telangana Praja Samithi and Movement",
          officialName:
              "Formation of Telangana Praja Samithi and Course of Movement and its Major Events, Leaders and Personalities- All Party Accord – G.O. 36 - Suppression of Telangana Movement and its Consequences-The Eight Point and Five-Point Formulas-Implications.",
          displayName: "Telangana Praja Samithi and Movement",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-01",
              officialName: "Formation of Telangana Praja Samithi",
              displayName: "Telangana Praja Samithi",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-02",
              officialName: "Course of Movement",
              displayName: "Movement Course",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-03",
              officialName: "Major Events",
              displayName: "Major Events",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-04",
              officialName: "Leaders",
              displayName: "Leaders",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-05",
              officialName: "Personalities",
              displayName: "Personalities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-06",
              officialName: "All Party Accord",
              displayName: "All Party Accord",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-07",
              officialName: "G.O. 36",
              displayName: "G.O. 36",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-08",
              officialName: "Suppression of Telangana Movement",
              displayName: "Movement Suppression",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-09",
              officialName: "its Consequences",
              displayName: "Consequences",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-10",
              officialName: "The Eight Point and Five-Point Formulas",
              displayName: "Eight-Point and Five-Point Formulas",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-01-topic-05-lesson-11",
              officialName: "Implications",
              displayName: "Implications",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-iv-part-02",
      officialName: "Mobilisational phase (1971 -1990)",
      displayName: "Mobilisational phase (1971 -1990)",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iv-part-02-topic-01",
          title: "Mulki Rules and Service Safeguards",
          officialName:
              "Court Judgements on Mulki Rules- Jai Andhra Movement and its Consequences- Six Point Formula 1973, and its Provisions; Article 371-D, Presidential Order, 1975- Officers (Jayabharat Reddy) Committee Report- G.O. 610 (1985); its Provisions and Violation- Reaction and Representations of Telangana Employees.",
          displayName: "Mulki Rules and Service Safeguards",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-01",
              officialName: "Court Judgements on Mulki Rules",
              displayName: "Mulki Rules Judgements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-02",
              officialName: "Jai Andhra Movement and its Consequences",
              displayName: "Jai Andhra",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-03",
              officialName: "Six Point Formula 1973",
              displayName: "Six Point Formula",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-04",
              officialName: "its Provisions",
              displayName: "Six Point Provisions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-05",
              officialName: "Article 371-D",
              displayName: "Article 371-D",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-06",
              officialName: "Presidential Order, 1975",
              displayName: "Presidential Order",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-07",
              officialName: "Officers (Jayabharat Reddy) Committee Report",
              displayName: "Jayabharat Reddy Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-08",
              officialName: "G.O. 610 (1985)",
              displayName: "G.O. 610",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-09",
              officialName: "its Provisions and Violation",
              displayName: "G.O. 610 Provisions and Violation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-10",
              officialName: "Reaction",
              displayName: "Employee Reaction",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-01-lesson-11",
              officialName: "Representations of Telangana Employees",
              displayName: "Employee Representations",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-02-topic-02",
          title: "Naxalite and Resistance Movements",
          officialName:
              "Rise and Spread of Naxalite Movement, causes and consequences - Anti-Landlord Struggles in Jagityala-Siricilla, Rytu-Cooli Sanghams; Alienation of Tribal Lands and Adivasi Resistance- Jal, Jungle, and Jamin.",
          displayName: "Naxalite and Resistance Movements",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-01",
              officialName: "Rise and Spread of Naxalite Movement",
              displayName: "Naxalite Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-02",
              officialName: "causes and consequences",
              displayName: "Causes and Consequences",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-03",
              officialName: "Anti-Landlord Struggles in Jagityala-Siricilla",
              displayName: "Jagityala-Siricilla Struggles",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-04",
              officialName: "Rytu-Cooli Sanghams",
              displayName: "Rytu-Cooli Sanghams",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-05",
              officialName: "Alienation of Tribal Lands",
              displayName: "Tribal Land Alienation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-06",
              officialName: "Adivasi Resistance",
              displayName: "Adivasi Resistance",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-02-lesson-07",
              officialName: "Jal, Jungle, and Jamin",
              displayName: "Jal, Jungle, Jamin",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-02-topic-03",
          title: "Regional Parties and Social Change",
          officialName:
              "Rise of Regional Parties in 1980’s and Changes in the Political, Socio-Economic and Cultural fabric of Telangana- Notion of Telugu Jathi and suppression of Telangana identity- Expansion of new economy in Hyderabad and other parts of Telangana; Real Estate, Contracts, Finance Companies; Film, Media and Entertainment Industry; Corporate Education and Hospitals etc; Dominant Culture and its implications for Telangana self respect, Dialect, Language and Culture.",
          displayName: "Regional Parties and Social Change",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-01",
              officialName: "Rise of Regional Parties in 1980’s",
              displayName: "Regional Parties",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-02",
              officialName:
                  "Changes in the Political, Socio-Economic and Cultural fabric of Telangana",
              displayName:
                  "Telangana Political, Social, Economic and Cultural Change",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-03",
              officialName: "Notion of Telugu Jathi",
              displayName: "Telugu Jathi",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-04",
              officialName: "suppression of Telangana identity",
              displayName: "Identity Suppression",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-05",
              officialName:
                  "Expansion of new economy in Hyderabad and other parts of Telangana",
              displayName: "New Economy",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-06",
              officialName: "Real Estate",
              displayName: "Real Estate",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-07",
              officialName: "Contracts",
              displayName: "Contracts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-08",
              officialName: "Finance Companies",
              displayName: "Finance Companies",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-09",
              officialName: "Film, Media and Entertainment Industry",
              displayName: "Film, Media and Entertainment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-10",
              officialName: "Corporate Education and Hospitals etc",
              displayName: "Corporate Education and Hospitals",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-11",
              officialName: "Dominant Culture",
              displayName: "Dominant Culture",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-12",
              officialName: "its implications for Telangana self respect",
              displayName: "Self-Respect",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-13",
              officialName: "Dialect",
              displayName: "Dialect",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-03-lesson-14",
              officialName: "Language and Culture",
              displayName: "Language and Culture",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-02-topic-04",
          title: "Liberalization and Regional Disparities",
          officialName:
              "Liberalization and Privatisation policies in 1990’s and their consequences - Emergence of regional disparities and imbalances in political power, administration, education, employment – Growth of Madiga Dandora and Tudum Debba movements – Agrarian crisis and decline of Handicrafts in Telangana and its impact on Telangana Society and economy.",
          displayName: "Liberalization and Regional Disparities",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-01",
              officialName:
                  "Liberalization and Privatisation policies in 1990’s",
              displayName: "Liberalization and Privatisation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-02",
              officialName: "their consequences",
              displayName: "Policy Consequences",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-03",
              officialName: "Emergence of regional disparities",
              displayName: "Regional Disparities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-04",
              officialName: "imbalances in political power",
              displayName: "Political Power Imbalances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-05",
              officialName: "administration",
              displayName: "Administrative Imbalances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-06",
              officialName: "education",
              displayName: "Education Imbalances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-07",
              officialName: "employment",
              displayName: "Employment Imbalances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-08",
              officialName: "Growth of Madiga Dandora",
              displayName: "Madiga Dandora",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-09",
              officialName: "Tudum Debba movements",
              displayName: "Tudum Debba",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-10",
              officialName: "Agrarian crisis",
              displayName: "Agrarian Crisis",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-11",
              officialName: "decline of Handicrafts in Telangana",
              displayName: "Handicrafts Decline",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-04-lesson-12",
              officialName: "its impact on Telangana Society and economy",
              displayName: "Social and Economic Impact",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-02-topic-05",
          title: "Telangana Identity",
          officialName:
              "Quest for Telangana identity – Intellectual discussions and debates – Political and ideological Efforts – Growth of popular unrest against regional disparities, discrimination and under development of Telangana.",
          displayName: "Telangana Identity",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-01",
              officialName: "Quest for Telangana identity",
              displayName: "Telangana Identity",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-02",
              officialName: "Intellectual discussions and debates",
              displayName: "Intellectual Debates",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-03",
              officialName: "Political and ideological Efforts",
              displayName: "Political and Ideological Efforts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-04",
              officialName: "Growth of popular unrest",
              displayName: "Popular Unrest",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-05",
              officialName: "regional disparities",
              displayName: "Regional Disparities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-06",
              officialName: "discrimination",
              displayName: "Discrimination",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-02-topic-05-lesson-07",
              officialName: "under development of Telangana",
              displayName: "Underdevelopment",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
    SyllabusPart(
      id: "group-ii-paper-iv-part-03",
      officialName: "Towards Formation of Telangana State (1991-2014)",
      displayName: "Towards Formation of Telangana State (1991-2014)",
      topics: [
        SyllabusTopic(
          id: "group-ii-paper-iv-part-03-topic-01",
          title: "Public Awakening and Civil Society",
          officialName:
              "Public awakening and Intellectual reaction against discrimination- formation of Civil society organisations, Articulation of separate Telangana Identity; Initial organisations raised the issues of separate Telangana; Telangana Information Trust - Telangana Aikya Vedika, Bhuvanagiri Sabha - Telangana Jana Sabha, Telangana Maha Sabha - Warangal Decleration - Telangana Vidyavanthula Vedika; etc. Role of university and college students - Osmania and Kakatiya Universities",
          displayName: "Public Awakening and Civil Society",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-01",
              officialName: "Public awakening",
              displayName: "Public Awakening",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-02",
              officialName: "Intellectual reaction against discrimination",
              displayName: "Intellectual Reaction",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-03",
              officialName: "formation of Civil society organisations",
              displayName: "Civil Society Organisations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-04",
              officialName: "Articulation of separate Telangana Identity",
              displayName: "Telangana Identity",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-05",
              officialName:
                  "Initial organisations raised the issues of separate Telangana",
              displayName: "Initial Organisations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-06",
              officialName: "Telangana Information Trust",
              displayName: "Telangana Information Trust",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-07",
              officialName: "Telangana Aikya Vedika",
              displayName: "Telangana Aikya Vedika",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-08",
              officialName: "Bhuvanagiri Sabha",
              displayName: "Bhuvanagiri Sabha",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-09",
              officialName: "Telangana Jana Sabha",
              displayName: "Telangana Jana Sabha",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-10",
              officialName: "Telangana Maha Sabha",
              displayName: "Telangana Maha Sabha",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-11",
              officialName: "Warangal Decleration",
              displayName: "Warangal Decleration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-12",
              officialName: "Telangana Vidyavanthula Vedika",
              displayName: "Telangana Vidyavanthula Vedika",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-13",
              officialName: "Role of university and college students",
              displayName: "University and College Students",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-14",
              officialName: "Osmania",
              displayName: "Osmania University",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-01-lesson-15",
              officialName: "Kakatiya Universities",
              displayName: "Kakatiya University",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-03-topic-02",
          title: "TRS and Later Movement",
          officialName:
              "Establishment of Telangana Rashtra Samithi in 2001, Political Realignment and Electoral Alliances in 2004 and later Phase of Telangana Movement – TRS in UPA Girglani Committee- Telangana Employees Joint Action Committee - Pranab Mukherjee Committee- 2009-Elections-Alliances- Telangana in Election Manifestos- The agitation against Hyderabad as Free-zone - and Demand for separate Statehood- Fast-Unto-Death by K.Chandrashekar Rao – Formation of Political Joint Action Committee (2009)",
          displayName: "TRS and Later Movement",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-01",
              officialName:
                  "Establishment of Telangana Rashtra Samithi in 2001",
              displayName: "TRS Establishment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-02",
              officialName: "Political Realignment",
              displayName: "Political Realignment",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-03",
              officialName:
                  "Electoral Alliances in 2004 and later Phase of Telangana Movement",
              displayName: "Electoral Alliances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-04",
              officialName: "TRS in UPA",
              displayName: "TRS in UPA",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-05",
              officialName: "Girglani Committee",
              displayName: "Girglani Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-06",
              officialName: "Telangana Employees Joint Action Committee",
              displayName: "Employees JAC",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-07",
              officialName: "Pranab Mukherjee Committee",
              displayName: "Pranab Mukherjee Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-08",
              officialName: "2009-Elections",
              displayName: "2009 Elections",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-09",
              officialName: "Alliances",
              displayName: "Alliances",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-10",
              officialName: "Telangana in Election Manifestos",
              displayName: "Election Manifestos",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-11",
              officialName: "The agitation against Hyderabad as Free-zone",
              displayName: "Hyderabad Free-Zone Agitation",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-12",
              officialName: "Demand for separate Statehood",
              displayName: "Separate Statehood",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-13",
              officialName: "Fast-Unto-Death by K.Chandrashekar Rao",
              displayName: "K. Chandrashekar Rao Fast",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-02-lesson-14",
              officialName:
                  "Formation of Political Joint Action Committee (2009)",
              displayName: "Political JAC",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-03-topic-03",
          title: "Political Parties and Protests",
          officialName:
              "Role of Political Parties-TRS, Congress, B.J.P., Left parties, T.D.P., M.I.M and other political parties such as Telangana Praja Front, Telangana United Front etc., Dalit Bahujan Sanghams and Grass root organisations - Other Joint Action Committees and popular protests- Suicides for the cause of Telangana.",
          displayName: "Political Parties and Protests",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-01",
              officialName: "Role of Political Parties",
              displayName: "Political Parties",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-02",
              officialName: "TRS",
              displayName: "TRS",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-03",
              officialName: "Congress",
              displayName: "Congress",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-04",
              officialName: "B.J.P.",
              displayName: "BJP",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-05",
              officialName: "Left parties",
              displayName: "Left Parties",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-06",
              officialName: "T.D.P.",
              displayName: "TDP",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-07",
              officialName: "M.I.M",
              displayName: "MIM",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-08",
              officialName: "Telangana Praja Front",
              displayName: "Telangana Praja Front",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-09",
              officialName: "Telangana United Front",
              displayName: "Telangana United Front",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-10",
              officialName: "Dalit Bahujan Sanghams",
              displayName: "Dalit Bahujan Sanghams",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-11",
              officialName: "Grass root organisations",
              displayName: "Grassroot Organisations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-12",
              officialName: "Other Joint Action Committees",
              displayName: "Other JACs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-13",
              officialName: "popular protests",
              displayName: "Popular Protests",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-03-lesson-14",
              officialName: "Suicides for the cause of Telangana",
              displayName: "Sacrifices for Telangana",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-03-topic-04",
          title: "Cultural Revivalism and Mass Movement",
          officialName:
              "Cultural Revivalism in Telangana and other symbolic expressions in Telangana Movement- Literary forms- performing arts and other cultural expressions- writers, poets, singers, intellectuals, Artists, Journalists, Students, Employees, Advocates, Doctors, NRIs, Women and Civil society groups - organised and unorganised sectors, castes, communities and other social groups in transforming the agitation into a mass movement-Intensification of Movement, Forms of Protest and Major events: Sakalajanula Samme, Non-Cooperation Movement; Million March, etc.,",
          displayName: "Cultural Revivalism and Mass Movement",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-01",
              officialName: "Cultural Revivalism in Telangana",
              displayName: "Cultural Revivalism",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-02",
              officialName: "other symbolic expressions in Telangana Movement",
              displayName: "Symbolic Expressions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-03",
              officialName: "Literary forms",
              displayName: "Literary Forms",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-04",
              officialName: "performing arts",
              displayName: "Performing Arts",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-05",
              officialName: "other cultural expressions",
              displayName: "Cultural Expressions",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-06",
              officialName: "writers",
              displayName: "Writers",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-07",
              officialName: "poets",
              displayName: "Poets",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-08",
              officialName: "singers",
              displayName: "Singers",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-09",
              officialName: "intellectuals",
              displayName: "Intellectuals",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-10",
              officialName: "Artists",
              displayName: "Artists",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-11",
              officialName: "Journalists",
              displayName: "Journalists",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-12",
              officialName: "Students",
              displayName: "Students",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-13",
              officialName: "Employees",
              displayName: "Employees",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-14",
              officialName: "Advocates",
              displayName: "Advocates",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-15",
              officialName: "Doctors",
              displayName: "Doctors",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-16",
              officialName: "NRIs",
              displayName: "NRIs",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-17",
              officialName: "Women",
              displayName: "Women",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-18",
              officialName: "Civil society groups",
              displayName: "Civil Society Groups",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-19",
              officialName: "organised and unorganised sectors",
              displayName: "Organised and Unorganised Sectors",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-20",
              officialName: "castes",
              displayName: "Castes",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-21",
              officialName: "communities",
              displayName: "Communities",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-22",
              officialName: "other social groups",
              displayName: "Other Social Groups",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-23",
              officialName: "transforming the agitation into a mass movement",
              displayName: "Mass Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-24",
              officialName: "Intensification of Movement",
              displayName: "Movement Intensification",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-25",
              officialName: "Forms of Protest",
              displayName: "Forms of Protest",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-26",
              officialName: "Sakalajanula Samme",
              displayName: "Sakalajanula Samme",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-27",
              officialName: "Non-Cooperation Movement",
              displayName: "Non-Cooperation Movement",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-04-lesson-28",
              officialName: "Million March",
              displayName: "Million March",
              sourceType: sourceType,
            ),
          ],
        ),
        SyllabusTopic(
          id: "group-ii-paper-iv-part-03-topic-05",
          title: "Parliamentary Process and State Formation",
          officialName:
              "Parliamentary Process; UPA Government’s stand on Telangana- All-Party Meeting- Anthony Committee- Statements on Telangana by Central Home Minister - Sri Krishna Committee Report and its Recommendations, AP Assembly and Parliamentary proceedings on Telangana, Declaration of Telangana State in Parliament, Andhra Pradesh State Reorganization Act, 2014- Elections and victory of Telangana Rashtra Samithi and the first Government of Telangana State.",
          displayName: "Parliamentary Process and State Formation",
          lessons: [
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-01",
              officialName: "Parliamentary Process",
              displayName: "Parliamentary Process",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-02",
              officialName: "UPA Government’s stand on Telangana",
              displayName: "UPA Stand",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-03",
              officialName: "All-Party Meeting",
              displayName: "All-Party Meeting",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-04",
              officialName: "Anthony Committee",
              displayName: "Anthony Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-05",
              officialName: "Statements on Telangana by Central Home Minister",
              displayName: "Home Minister Statements",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-06",
              officialName: "Sri Krishna Committee Report",
              displayName: "Sri Krishna Committee",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-07",
              officialName: "its Recommendations",
              displayName: "Sri Krishna Recommendations",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-08",
              officialName:
                  "AP Assembly and Parliamentary proceedings on Telangana",
              displayName: "Assembly and Parliamentary Proceedings",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-09",
              officialName: "Declaration of Telangana State in Parliament",
              displayName: "Parliamentary Declaration",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-10",
              officialName: "Andhra Pradesh State Reorganization Act, 2014",
              displayName: "Reorganization Act",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-11",
              officialName: "Elections",
              displayName: "Elections",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-12",
              officialName: "victory of Telangana Rashtra Samithi",
              displayName: "TRS Victory",
              sourceType: sourceType,
            ),
            SyllabusLesson(
              id: "group-ii-paper-iv-part-03-topic-05-lesson-13",
              officialName: "the first Government of Telangana State",
              displayName: "First Telangana Government",
              sourceType: sourceType,
            ),
          ],
        ),
      ],
    ),
  ]);
}
