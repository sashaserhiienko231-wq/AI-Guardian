const BACKEND_URL_PROPERTY = 'AI_GUARDIAN_API_BASE_URL';
const MAX_EMAIL_BODY_LENGTH = 100000;

function onGmailMessageOpen(event) {
  const messageId = event && event.gmail && event.gmail.messageId;
  if (!messageId) {
    return [buildNoticeCard(
      'Open a Gmail message to scan it.',
      'AI Guardian only reads the currently open message after you choose Analyze this email.'
    )];
  }

  return [buildMessageCard(messageId)];
}

function analyzeCurrentMessage(event) {
  const messageId = event && event.parameters && event.parameters.messageId;
  const accessToken = event && event.gmail && event.gmail.accessToken;
  if (!messageId || !accessToken) {
    return showNotice(
      'Could not access the current message. Close and reopen it, then try again.'
    );
  }

  let message;
  try {
    GmailApp.setCurrentMessageAccessToken(accessToken);
    message = GmailApp.getMessageById(messageId);
  } catch (error) {
    return showNotice(
      'Gmail did not grant access to this message. Reopen it and approve the requested Gmail permission.'
    );
  }
  if (!message) {
    return showNotice('The currently open message is no longer available.');
  }

  const body = message.getPlainBody();
  const truncated = body.length > MAX_EMAIL_BODY_LENGTH;
  const headers = {};
  ['Authentication-Results', 'Reply-To', 'Return-Path'].forEach(function (name) {
    const value = message.getHeader(name);
    if (value) {
      headers[name] = value.substring(0, 5000);
    }
  });

  const payload = {
    sender: message.getFrom().substring(0, 500),
    subject: message.getSubject().substring(0, 1000),
    body: body.substring(0, MAX_EMAIL_BODY_LENGTH),
    headers: headers
  };

  const baseUrl = PropertiesService.getScriptProperties()
    .getProperty(BACKEND_URL_PROPERTY);
  if (!baseUrl || !/^https:\/\/[^/?#]+(?:\/[^?#]*)?$/i.test(baseUrl)) {
    return showNotice(
      'AI Guardian is not configured. Set the script property AI_GUARDIAN_API_BASE_URL to your HTTPS backend URL.'
    );
  }

  const url = baseUrl.replace(/\/+$/, '') + '/api/v1/scanner/email';
  let response;
  try {
    response = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      payload: JSON.stringify(payload),
      followRedirects: false,
      muteHttpExceptions: true
    });
  } catch (error) {
    return showNotice(
      'Could not reach the configured AI Guardian backend. Check its HTTPS URL and availability.'
    );
  }

  if (response.getResponseCode() !== 200) {
    return showNotice(
      'The AI Guardian backend could not analyze this message (HTTP ' +
      response.getResponseCode() + ').'
    );
  }

  let result;
  try {
    result = JSON.parse(response.getContentText());
  } catch (error) {
    return showNotice('The AI Guardian backend returned an unreadable response.');
  }

  return showResult(result, truncated);
}

function buildMessageCard(messageId) {
  const section = CardService.newCardSection()
    .addWidget(CardService.newTextParagraph().setText(
      'Scan this message for common phishing indicators using AI Guardian.'
    ))
    .addWidget(CardService.newTextParagraph().setText(
      '<b>Privacy:</b> When you click Analyze, the sender, subject, message text, and selected mail headers are sent to your configured AI Guardian backend. The backend stores scan findings, not the email content.'
    ))
    .addWidget(CardService.newTextButton()
      .setText('Analyze this email')
      .setOnClickAction(CardService.newAction()
        .setFunctionName('analyzeCurrentMessage')
        .setParameters({ messageId: messageId })));

  return CardService.newCardBuilder()
    .setHeader(CardService.newCardHeader()
      .setTitle('AI Guardian')
      .setSubtitle('Review this email for phishing'))
    .addSection(section)
    .build();
}

function showResult(result, truncated) {
  if (typeof result.risk_score !== 'number' ||
      typeof result.risk_category !== 'string') {
    return showNotice('The AI Guardian backend returned an incomplete scan result.');
  }

  const suspicious = result.risk_score >= 40;
  const section = CardService.newCardSection()
    .addWidget(CardService.newDecoratedText()
      .setTopLabel(suspicious ? 'Review carefully' : 'No strong indicators found')
      .setText(result.risk_category + ' risk · ' + result.risk_score + '/100'))
    .addWidget(CardService.newTextParagraph().setText(
      'This automated analysis can be wrong. A low score does not prove that an email is safe.'
    ));

  const indicators = Array.isArray(result.indicators) ? result.indicators : [];
  indicators.slice(0, 8).forEach(function (indicator) {
    if (indicator && typeof indicator.title === 'string') {
      section.addWidget(CardService.newTextParagraph().setText(
        '• ' + indicator.title
      ));
    }
  });

  const explanations = Array.isArray(result.explanations) ? result.explanations : [];
  explanations.slice(0, 5).forEach(function (explanation) {
    if (typeof explanation === 'string') {
      section.addWidget(CardService.newTextParagraph().setText(explanation));
    }
  });

  if (truncated) {
    section.addWidget(CardService.newTextParagraph().setText(
      'Only the first 100,000 characters were analyzed.'
    ));
  }

  section.addWidget(CardService.newTextParagraph().setText(
    '<b>Do not follow links or share credentials based only on this result. Verify unexpected requests through an official channel.</b>'
  ));

  const card = CardService.newCardBuilder()
    .setHeader(CardService.newCardHeader().setTitle('Email scan result'))
    .addSection(section)
    .build();
  return CardService.newActionResponseBuilder()
    .setNavigation(CardService.newNavigation().pushCard(card))
    .build();
}

function showNotice(message) {
  const card = buildNoticeCard('Email scan unavailable', message);
  return CardService.newActionResponseBuilder()
    .setNavigation(CardService.newNavigation().pushCard(card))
    .build();
}

function buildNoticeCard(title, message) {
  return CardService.newCardBuilder()
    .setHeader(CardService.newCardHeader().setTitle(title))
    .addSection(CardService.newCardSection()
      .addWidget(CardService.newTextParagraph().setText(message)))
    .build();
}
