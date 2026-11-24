# Security Policy

## Reporting a vulnerability

Please do not disclose vulnerabilities publicly before maintainers can assess
and address them. Open a private security report through GitHub's security
advisories for this repository once it is published, or contact the repository
owner through their public GitHub profile.

Include:

- Affected component and version
- Reproduction steps
- Impact assessment
- Suggested mitigation, if available

Do not include API keys, passwords, private keys, personal data, or production
database contents in the report.

## Sensitive configuration

- Copy `.env.example` to `.env` for local configuration.
- Never commit `.env`, database files, bearer tokens, API keys, or keystores.
- Production Android signing credentials must be supplied outside the repository.
- Do not attach passwords or personal data to issues or pull requests.

## Scope considerations

AI Guardian provides security assistance, not guaranteed detection or a
confirmed malware verdict. Report issues involving credential exposure,
authentication bypass, SSRF, unsafe URL fetching, data leakage, signing
secrets, or unintended persistence as security findings.
