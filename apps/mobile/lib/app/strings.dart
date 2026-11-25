class AppStrings {
  const AppStrings(this.uk);

  final bool uk;

  String _text(String english, String ukrainian) => uk ? ukrainian : english;

  String get appName => 'AI Guardian';
  String get navigation => _text('Navigation', 'Навігація');
  String get protection => _text('PROTECTION', 'ЗАХИСТ');
  String get intelligence => _text('INTELLIGENCE', 'АНАЛІТИКА');
  String get system => _text('SYSTEM', 'СИСТЕМА');
  String get overview => _text('Overview', 'Огляд');
  String get linkScanner => _text('Link scanner', 'Сканер посилань');
  String get emailProtection => _text('Email protection', 'Захист пошти');
  String get qrScanner => _text('QR scanner', 'QR-сканер');
  String get passwordCenter => _text('Password center', 'Центр паролів');
  String get assistant => _text('AI assistant', 'AI-помічник');
  String get threatHistory => _text('Threat history', 'Історія загроз');
  String get learningCenter => _text('Learning center', 'Навчальний центр');
  String get settings => _text('Settings', 'Налаштування');
  String get processSafety => _text('Process safety', 'Перевірка процесів');
  String get collapseSidebar =>
      _text('Collapse sidebar', 'Згорнути бічну панель');
  String get expandSidebar =>
      _text('Expand sidebar', 'Розгорнути бічну панель');
  String get openNavigation => _text('Open navigation', 'Відкрити навігацію');
  String get workspace => _text('Workspace', 'Робочий простір');
  String get applicationMenu => _text('Application menu', 'Меню застосунку');
  String get aboutApplication => _text('About AI Guardian', 'Про AI Guardian');
  String get aboutDescription => _text(
    'AI Guardian brings your security tools together. Results depend on the configured services and local checks.',
    'AI Guardian об’єднує інструменти безпеки. Результати залежать від налаштованих сервісів і локальних перевірок.',
  );
  String get dashboardSubtitle => _text(
    'A clear view of your latest security activity.',
    'Актуальна інформація про стан вашої безпеки.',
  );
  String get linkSubtitle => _text(
    'Check a web address before you open it.',
    'Перевірте вебадресу, перш ніж відкривати її.',
  );
  String get emailSubtitle => _text(
    'Review a message for phishing signals.',
    'Перевірте лист на ознаки фішингу.',
  );
  String get qrSubtitle => _text(
    'Inspect a QR code before following its content.',
    'Перевірте вміст QR-коду, перш ніж переходити за посиланням.',
  );
  String get passwordSubtitle => _text(
    'Check password patterns locally on this device.',
    'Перевірте пароль локально на цьому пристрої.',
  );
  String get assistantSubtitle => _text(
    'Ask questions about everyday digital safety.',
    'Поставте запитання про цифрову безпеку.',
  );
  String get historySubtitle => _text(
    'Search and review results returned by your security scans.',
    'Шукайте та переглядайте результати перевірок.',
  );
  String get learningSubtitle => _text(
    'Practical lessons from the learning service.',
    'Практичні уроки навчального сервісу.',
  );
  String get settingsSubtitle => _text(
    'Personalize the app and review privacy information.',
    'Налаштуйте застосунок і перегляньте інформацію про приватність.',
  );
  String get processSubtitle => _text(
    'A local, read-only review of selected Windows process paths.',
    'Локальна перевірка шляхів процесів Windows лише для читання.',
  );
  String get apiConnected => _text('API connected', 'API підключено');
  String get apiUnavailable => _text('API unavailable', 'API недоступний');
  String get apiNotChecked => _text('API not checked', 'API ще не перевірено');
  String get apiStatus => _text('API status', 'Стан API');
  String get retry => _text('Try again', 'Спробувати ще');
  String get loading => _text('Loading…', 'Завантаження…');
  String get connectApi => _text(
    'Connect to the configured API to load live security data.',
    'Підключіться до налаштованого API, щоб завантажити актуальні дані.',
  );
  String get noDashboardData => _text(
    'No security statistics are available yet.',
    'Статистика безпеки поки недоступна.',
  );
  String get noScansYet => _text(
    'No scans recorded yet. Run a check to start building your security history.',
    'Перевірок ще немає. Запустіть сканування, щоб почати вести історію безпеки.',
  );
  String get securityScore => _text('Security score', 'Оцінка безпеки');
  String get totalScans => _text('Total scans', 'Усього перевірок');
  String get threatsDetected =>
      _text('High-risk scans', 'Перевірки з високим ризиком');
  String get safeScans =>
      _text('Low-risk scans', 'Перевірки з низьким ризиком');
  String get scoreFormula => _text(
    'Calculated by the security service from recorded scans. It is not a guarantee that this device is safe.',
    'Оцінку розраховує сервіс на основі перевірок. Вона не гарантує безпеку пристрою.',
  );
  String get riskProfile =>
      _text('Recorded risk profile', 'Розподіл зафіксованих ризиків');
  String get lowRisk => _text('Low · 0–19', 'Низький · 0–19');
  String get elevatedRisk => _text('Elevated · 20–39', 'Підвищений · 20–39');
  String get highRisk => _text('High · 40–100', 'Високий · 40–100');
  String get recentActivity => _text('Recent activity', 'Остання активність');
  String get viewAll => _text('View all', 'Переглянути все');
  String get quickActions => _text('Quick actions', 'Швидкі дії');
  String get apiOfflineTitle => _text(
    'Live dashboard data is unavailable',
    'Актуальні дані дашборда недоступні',
  );
  String get apiOfflineDescription => _text(
    'The dashboard could not load its API-backed data. Password pattern checks and read-only Windows process review remain available locally.',
    'Дашборду не вдалося завантажити дані API. Перевірка шаблонів паролів і перегляд процесів Windows лише для читання доступні локально.',
  );
  String get localProtection =>
      _text('Available on this device', 'Доступно на цьому пристрої');
  String get localProtectionDescription => _text(
    'These checks run locally and do not require the security API.',
    'Ці перевірки виконуються локально й не потребують API безпеки.',
  );
  String get passwordCheckDescription => _text(
    'Review password patterns without sending the password.',
    'Перевірте шаблони пароля, не надсилаючи його.',
  );
  String get processCheckDescription => _text(
    'Read-only review of selected Windows process paths.',
    'Перегляд шляхів вибраних процесів Windows лише для читання.',
  );
  String get scanLink => _text('Scan a link', 'Перевірити посилання');
  String get reviewEmail => _text('Review an email', 'Перевірити лист');
  String get checkProcesses => _text('Check processes', 'Перевірити процеси');
  String get scanUrlLabel => _text('Website address', 'Адреса вебсайту');
  String get scanUrlHint => _text('https://example.com', 'https://example.com');
  String get scanUrlAction => _text('Scan address', 'Перевірити адресу');
  String get pasteFromClipboard =>
      _text('Paste from clipboard', 'Вставити з буфера обміну');
  String get clipboardEmpty =>
      _text('Clipboard has no text to paste.', 'У буфері обміну немає тексту.');
  String get clipboardReadError => _text(
    'Could not read the clipboard. Paste the address manually.',
    'Не вдалося прочитати буфер обміну. Вставте адресу вручну.',
  );
  String get invalidUrl => _text(
    'Enter a valid HTTP or HTTPS web address.',
    'Введіть коректну вебадресу з HTTP або HTTPS.',
  );
  String get scanProgress =>
      _text('Checking the address…', 'Перевіряємо адресу…');
  String get scanResult => _text('Scan result', 'Результат перевірки');
  String get scanAgain =>
      _text('Scan another address', 'Перевірити іншу адресу');
  String get sender => _text('Sender', 'Відправник');
  String get subject => _text('Subject', 'Тема');
  String get message => _text('Message', 'Текст листа');
  String get senderHint => _text('name@example.com', 'name@example.com');
  String get emailBodyHint => _text(
    'Paste the message text. Avoid including private information.',
    'Вставте текст листа. Не додавайте приватну інформацію.',
  );
  String get analyzeEmail => _text('Analyze message', 'Проаналізувати лист');
  String get emailInputRequired => _text(
    'Add at least a sender, subject, or message to analyze.',
    'Додайте відправника, тему або текст листа для аналізу.',
  );
  String get emailPrivacy => _text(
    'The message text is sent to the configured security API for analysis.',
    'Текст листа надсилається до налаштованого API безпеки для аналізу.',
  );
  String get characters => _text('characters', 'символів');
  String get emailWorkspaceHint => _text(
    'Add any available details. The service will analyze the information you provide.',
    'Додайте доступні відомості. Сервіс проаналізує надану інформацію.',
  );
  String get scannerCameraUnavailable => _text(
    'Camera preview is unavailable. You can still inspect a QR image or paste decoded content.',
    'Попередній перегляд камери недоступний. Ви можете перевірити зображення QR-коду або вставити його вміст.',
  );
  String get chooseQrImage => _text('Choose an image', 'Вибрати зображення');
  String get dropQrImage => _text(
    'Drop a QR image here or choose a file',
    'Перетягніть сюди зображення QR-коду або виберіть файл',
  );
  String get switchCamera => _text('Switch camera', 'Змінити камеру');
  String get toggleFlash => _text('Toggle flash', 'Увімкнути спалах');
  String get decodedContent => _text('Decoded content', 'Розпізнаний вміст');
  String get qrResultPreviewTitle =>
      _text('QR content captured', 'Вміст QR-коду отримано');
  String get qrResultPreviewNotice => _text(
    'The decoded content is shown for review and has not been opened.',
    'Розпізнаний вміст показано для перегляду; його не відкривали.',
  );
  String get qrContentHint => _text(
    'Paste text or a web address from a QR code',
    'Вставте текст або вебадресу з QR-коду',
  );
  String get analyzeQr => _text('Inspect content', 'Перевірити вміст');
  String get qrImageNotFound => _text(
    'No QR code was found in that image.',
    'У цьому зображенні QR-код не знайдено.',
  );
  String get qrImageReadError => _text(
    'The selected image could not be read.',
    'Не вдалося прочитати вибране зображення.',
  );
  String get passwordLabel =>
      _text('Password to check', 'Пароль для перевірки');
  String get showPassword => _text('Show password', 'Показати пароль');
  String get hidePassword => _text('Hide password', 'Приховати пароль');
  String get analyzeLocally =>
      _text('Analyze on this device', 'Перевірити на пристрої');
  String get passwordStrength =>
      _text('Pattern strength', 'Складність шаблону');
  String get strong => _text('Strong pattern', 'Надійний шаблон');
  String get moderate => _text('Fair pattern', 'Середній шаблон');
  String get weak => _text('Weak pattern', 'Слабкий шаблон');
  String get passwordEmpty =>
      _text('Enter a password to analyze.', 'Введіть пароль для перевірки.');
  String get passwordLength => _text('Length', 'Довжина');
  String get characterGroups => _text('Character groups', 'Групи символів');
  String get lowercase => _text('Lowercase', 'Малі літери');
  String get uppercase => _text('Uppercase', 'Великі літери');
  String get digits => _text('Digits', 'Цифри');
  String get symbols => _text('Symbols', 'Символи');
  String get localOnly => _text('Local analysis only', 'Лише локальний аналіз');
  String get passwordPrivacy => _text(
    'Your password stays on this device. It is never sent to or stored by the backend.',
    'Пароль залишається на цьому пристрої. Він не надсилається на сервер і не зберігається.',
  );
  String get heuristicDisclosure => _text(
    'This is a local pattern heuristic, not an entropy or crack-time estimate.',
    'Це локальна евристична оцінка шаблону, а не розрахунок ентропії чи часу зламу.',
  );
  String get passwordStrongTip => _text(
    'Use a unique passphrase and store it in a reputable password manager.',
    'Використовуйте унікальну парольну фразу та зберігайте її в надійному менеджері паролів.',
  );
  String get passwordWeakTip => _text(
    'Prefer at least 16 characters, avoid common phrases, and use a unique password for every account.',
    'Використовуйте щонайменше 16 символів, уникайте поширених фраз і створюйте окремий пароль для кожного облікового запису.',
  );
  String get aiDisclosureTitle =>
      _text('AI assistant disclosure', 'Про AI-помічника');
  String get aiDisclosure => _text(
    'Responses are AI-generated and educational. Verify important advice; they are not confirmed security findings.',
    'Відповіді створює AI для навчальних цілей. Перевіряйте важливі поради — це не підтверджені висновки про загрози.',
  );
  String get localConversation => _text(
    'Conversation is kept in this window only.',
    'Переписка зберігається лише у цьому вікні.',
  );
  String get conversationHistory => _text('Conversation', 'Розмова');
  String get assistantHint =>
      _text('Ask a security question…', 'Поставте запитання про безпеку…');
  String get send => _text('Send', 'Надіслати');
  String get retryMessage => _text('Retry message', 'Повторити надсилання');
  String get assistantThinking =>
      _text('The assistant is responding…', 'Помічник готує відповідь…');
  String get assistantEmpty => _text(
    'Ask about suspicious messages, safe browsing, or account protection.',
    'Запитайте про підозрілі листи, безпечний перегляд або захист облікового запису.',
  );
  String get userIdentity => _text('You', 'Ви');
  String get assistantIdentity => _text('AI Guardian', 'AI Guardian');
  String get examplePrompts => _text('Try asking', 'Спробуйте запитати');
  String get examplePromptPhishing => _text(
    'What are common signs of a phishing email?',
    'Які типові ознаки фішингового листа?',
  );
  String get examplePromptLinks => _text(
    'How can I check a suspicious link safely?',
    'Як безпечно перевірити підозріле посилання?',
  );
  String get examplePromptPasswords => _text(
    'How do I create a stronger passphrase?',
    'Як створити надійнішу парольну фразу?',
  );
  String get clearConversation =>
      _text('Clear conversation', 'Очистити розмову');
  String get searchHistory => _text('Search results', 'Пошук результатів');
  String get scanType => _text('Scan type', 'Тип перевірки');
  String get allTypes => _text('All types', 'Усі типи');
  String get severity => _text('Risk level', 'Рівень ризику');
  String get allLevels => _text('All levels', 'Усі рівні');
  String get dateRange => _text('Date range', 'Період');
  String get sortBy => _text('Sort by', 'Сортувати за');
  String get newestFirst => _text('Newest first', 'Спочатку новіші');
  String get oldestFirst => _text('Oldest first', 'Спочатку старіші');
  String get highestRiskFirst =>
      _text('Highest risk first', 'Спочатку найвищий ризик');
  String get lowestRiskFirst =>
      _text('Lowest risk first', 'Спочатку найнижчий ризик');
  String get anyDate => _text('Any time', 'За весь час');
  String get lastDay => _text('Last 24 hours', 'Останні 24 години');
  String get lastWeek => _text('Last 7 days', 'Останні 7 днів');
  String get lastMonth => _text('Last 30 days', 'Останні 30 днів');
  String get noHistory => _text('No scans yet', 'Перевірок ще немає');
  String get noHistoryMatching => _text(
    'No scans match these filters.',
    'За цими фільтрами перевірок не знайдено.',
  );
  String get deleteScan => _text('Delete scan', 'Видалити перевірку');
  String get deleteScanConfirm => _text(
    'This scan will be permanently removed from server history.',
    'Цю перевірку буде остаточно видалено з історії на сервері.',
  );
  String get cancel => _text('Cancel', 'Скасувати');
  String get delete => _text('Delete', 'Видалити');
  String get previousPage => _text('Previous', 'Назад');
  String get nextPage => _text('Next', 'Далі');
  String get lessonLevel => _text('Level', 'Рівень');
  String get allCategories => _text('All lessons', 'Усі уроки');
  String get beginner => _text('Beginner', 'Початковий');
  String get intermediate => _text('Intermediate', 'Середній');
  String get noLessons => _text('No lessons found', 'Уроків не знайдено');
  String get openLesson => _text('Read lesson', 'Читати урок');
  String get completeLesson =>
      _text('Mark as complete', 'Позначити завершеним');
  String get lessonCompleted => _text('Completed', 'Завершено');
  String get lessonProgressUnavailable => _text(
    'Reading progress could not be saved.',
    'Не вдалося зберегти прогрес читання.',
  );
  String get progressUnavailable => _text(
    'Reading progress is currently unavailable.',
    'Прогрес читання наразі недоступний.',
  );
  String get noLessonsMatching => _text(
    'No lessons match your search and category.',
    'За цим пошуком і категорією уроків не знайдено.',
  );
  String get preferences => _text('Preferences', 'Налаштування');
  String get appearance => _text('Appearance', 'Вигляд');
  String get darkTheme => _text('Dark appearance', 'Темне оформлення');
  String get darkThemeDescription => _text(
    'Use the low-light cybersecurity workspace.',
    'Використовувати темне оформлення інтерфейсу.',
  );
  String get language => _text('Language', 'Мова');
  String get ukrainian => _text('Ukrainian', 'Українська');
  String get english => _text('English', 'Англійська');
  String get appInformation =>
      _text('Application information', 'Відомості про застосунок');
  String get appVersion => _text('Version', 'Версія');
  String get privacy => _text('Privacy', 'Приватність');
  String get guestMode => _text(
    'No account is required. Scan history is handled by the configured API.',
    'Обліковий запис не потрібен. Історією перевірок керує налаштований API.',
  );
  String get retention => _text(
    'Scan history retention is configured by the backend service.',
    'Строк зберігання історії перевірок налаштовує сервер.',
  );
  String get processSafetyDescription => _text(
    'Manually review processes running from risky locations.',
    'Перевірте процеси, запущені з потенційно ризикованих папок.',
  );
  String get windowsOnly => _text(
    'Windows only · manual · read-only',
    'Лише Windows · вручну · тільки читання',
  );
  String get processSafetyDisclosure => _text(
    'This check flags processes running from Temp or Downloads. That location can be a warning sign, but legitimate apps may run there too. Windows may restrict access to some processes. A clean result is not a full malware scan or a guarantee that the device is safe. Process details stay on this device.',
    'Перевірка позначає процеси з папок Temp або Downloads. Це може бути приводом для уваги, але легальні програми також можуть запускатися звідти. Windows може обмежити доступ до частини процесів. Чистий результат не є повною перевіркою на шкідливе ПЗ і не гарантує безпеку пристрою. Дані процесів залишаються на цьому пристрої.',
  );
  String get platformUnavailable => _text(
    'Process inspection is not available on this platform.',
    'Перевірка процесів недоступна на цій платформі.',
  );
  String get runProcessCheck =>
      _text('Scan running processes', 'Перевірити запущені процеси');
  String get scanningProcesses =>
      _text('Reviewing process paths…', 'Перевіряємо шляхи процесів…');
  String get noProcessesMatched => _text(
    'No processes matched this check.',
    'Процесів, що відповідають критеріям, не знайдено.',
  );
  String get processNoGuarantee => _text(
    'Some processes may not be readable. This result is not a full malware scan.',
    'Деякі процеси можуть бути недоступні для читання. Це не повна перевірка на шкідливе ПЗ.',
  );
  String get processesNeedReview =>
      _text('process(es) need review', 'процес(и) потребують перевірки');
  String get processReviewAdvice => _text(
    'Check whether you recognize these programs and where they came from.',
    'Переконайтеся, що ви впізнаєте ці програми та знаєте їхнє походження.',
  );
  String get processFindingReason => _text(
    'This process is running from a user-writable Temp or Downloads folder. This is a risk signal, not proof of malware.',
    'Процес запущено з доступної для запису папки Temp або Downloads. Це сигнал ризику, а не підтвердження шкідливого ПЗ.',
  );
  String get processReadError => _text(
    'Windows could not read the running process information.',
    'Windows не вдалося прочитати інформацію про запущені процеси.',
  );
  String get unreadableProcesses => _text(
    'process(es) could not be inspected.',
    'процес(и) не вдалося перевірити.',
  );
  String get indicatorTitle => _text('Detected indicators', 'Виявлені ознаки');
  String get explanations => _text('Why this result', 'Пояснення результату');
  String get recommendedActions =>
      _text('Recommended actions', 'Рекомендовані дії');
  String get modelPrediction => _text('Model estimate', 'Оцінка моделі');
  String get probabilisticPrediction =>
      _text('Probabilistic classification', 'Імовірнісна класифікація');
  String get confidence => _text('Confidence', 'Впевненість');
  String get notConfirmedThreat =>
      _text('This is not a confirmed threat.', 'Це не підтверджена загроза.');
  String get openLink => _text('Open link', 'Відкрити посилання');
  String get reviewAndOpen =>
      _text('Review and open link', 'Перевірити й відкрити посилання');
  String get suspiciousLinkTitle =>
      _text('Suspicious link detected', 'Виявлено підозріле посилання');
  String get suspiciousLinkPrompt => _text(
    'The scan found risk indicators. Are you sure you want to continue?',
    'Сканування виявило ознаки ризику. Ви впевнені, що хочете продовжити?',
  );
  String get uncertainLinkPrompt => _text(
    'The scan did not return a usable risk score. Continue only if you trust this destination.',
    'Сканування не повернуло коректну оцінку ризику. Продовжуйте, лише якщо довіряєте цій адресі.',
  );
  String get unsafeLink => _text(
    'This result does not contain a valid HTTP or HTTPS link.',
    'У результаті немає коректного посилання HTTP або HTTPS.',
  );
  String get couldNotOpenLink =>
      _text('Could not open the link.', 'Не вдалося відкрити посилання.');
  String get scanDetails => _text('Scan details', 'Деталі перевірки');
  String get scanSummary => _text('Summary', 'Підсумок');
  String get pageOf => _text('Page', 'Сторінка');
  String get of => _text('of', 'з');
  String get all => _text('All', 'Усі');
  String get urlType => 'URL';
  String get emailType => _text('Email', 'Електронна пошта');
  String get qrType => 'QR';
  String scanTypeLabel(Object? value) =>
      switch (value?.toString().toLowerCase()) {
        'url' => urlType,
        'email' => emailType,
        'qr' => qrType,
        _ => value?.toString() ?? unknownType,
      };
  String get unknownType => _text('Other', 'Інше');
  String get riskSafe => _text('Low risk', 'Низький ризик');
  String get riskSuspicious => _text('Suspicious', 'Підозріло');
  String get riskMalicious => _text('High risk', 'Високий ризик');
  String get riskUnknown => _text('Unknown', 'Невідомо');
  String get invalidInput => _text(
    'The input is invalid or incomplete.',
    'Дані некоректні або неповні.',
  );
  String get apiUnavailableError => _text(
    'The security service is unavailable or the request timed out.',
    'Сервіс безпеки недоступний або час очікування запиту вичерпано.',
  );
  String get serviceBusy => _text(
    'The service is busy. Please wait a moment and retry.',
    'Сервіс зайнятий. Зачекайте трохи й повторіть спробу.',
  );
  String get serviceMisconfigured => _text(
    'The requested service is not currently configured.',
    'Запитаний сервіс наразі не налаштовано.',
  );
  String get unexpectedError => _text(
    'Something unexpected happened. Please retry.',
    'Сталася неочікувана помилка. Спробуйте ще раз.',
  );
  String get noLearningContent => _text(
    'The learning service returned no lessons.',
    'Навчальний сервіс не повернув уроків.',
  );
  String get articleNotProvided => _text(
    'The learning service provides lesson titles and levels, but no article text yet.',
    'Навчальний сервіс надає назви уроків і рівні складності, але поки не надає текст статей.',
  );
  String get lessonIntro => _text('Learning notes', 'Навчальні матеріали');
  String get lessonPhishing => _text(
    'Check the sender and destination before acting. Unexpected urgency, requests for credentials, and mismatched link destinations deserve extra scrutiny. Verify unusual requests through a separate, trusted channel.',
    'Перевіряйте відправника й адресу переходу, перш ніж діяти. Особливо уважно ставтеся до термінових вимог, запитів облікових даних і невідповідності адреси посилання. Незвичні прохання перевіряйте через окремий надійний канал.',
  );
  String get lessonPasswords => _text(
    'Use a different, long password for every account. A reputable password manager can create and remember unique passwords. Turn on multi-factor authentication where available, and never share a one-time code with someone who contacted you unexpectedly.',
    'Використовуйте довгий унікальний пароль для кожного облікового запису. Надійний менеджер паролів допоможе створювати й зберігати різні паролі. Увімкніть багатофакторну автентифікацію, якщо вона доступна, і нікому не повідомляйте одноразові коди.',
  );
  String get lessonBrowsing => _text(
    'Use bookmarks or type an address you already trust for sensitive accounts. Check the full hostname and be cautious of unexpected downloads, pop-ups, and requests to install software. HTTPS protects a connection but does not prove a site is trustworthy.',
    'Для важливих облікових записів використовуйте закладки або самостійно введіть відому адресу. Перевіряйте повне ім’я сайту та будьте обережні з неочікуваними завантаженнями, спливаючими вікнами й вимогами встановити програму. HTTPS захищає з’єднання, але не гарантує надійність сайту.',
  );
  String get lessonQr => _text(
    'A QR code can hide its destination. Preview the decoded address, inspect its domain, and avoid entering passwords or payment details after scanning an unexpected code. When in doubt, navigate to the organization through a trusted route instead.',
    'QR-код може приховувати адресу переходу. Перегляньте розпізнану адресу та домен; не вводьте паролі чи платіжні дані після сканування неочікуваного коду. Якщо сумніваєтеся, відкрийте сайт організації перевіреним способом.',
  );
}
