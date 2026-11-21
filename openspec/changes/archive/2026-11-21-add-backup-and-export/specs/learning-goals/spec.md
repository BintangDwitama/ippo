## ADDED Requirements

### Requirement: Reminder follows the stored setting
When the app starts, and after learning data is restored from a backup, the system SHALL make the daily reminder match the stored setting. If a reminder time is stored and notifications are allowed, the reminder SHALL be scheduled for that time. If a reminder time is stored and notifications are not allowed, the reminder SHALL be shown as off. The system SHALL NOT ask for notification permission at start-up or during a restore.

#### Scenario: Restored on a phone that allows notifications
- **WHEN** a backup with the reminder set to 19:00 is restored on a phone where notifications are allowed for the app
- **THEN** a notification is delivered at 19:00 each day and settings shows the reminder on at 19:00

#### Scenario: Restored on a phone that does not allow notifications
- **WHEN** a backup with the reminder set to 19:00 is restored on a phone where notifications are not allowed for the app
- **THEN** settings shows the reminder as off and no permission request appears

#### Scenario: Backup without a reminder
- **WHEN** a backup with the reminder off is restored on a phone that had a reminder scheduled
- **THEN** no reminder notification is delivered and settings shows the reminder as off
