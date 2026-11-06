# Changelog

All notable changes to Altverse (AU Reader) are documented here. This changelog
was reconstructed from the repository commit history; entries are grouped by
the month the work actually landed.

## 2026-07

- Added `.env.example` and a full project backup pass so the project can be
  set up from a clean checkout.

## 2026-06

- Ported backend services to Go: core foundation, config and database
  connection, migrations and models for all domains, core API services,
  controllers and routes, plus background workers and WebSockets.
- Hardened the wallet: money flows are now atomic, idempotent and race-safe,
  and mission rewards can no longer be double-claimed or lost on update.
- Verified the Midtrans webhook signature to block forged coin credit
  callbacks.
- Issued a JWT pair on register so clients can log in automatically.
- Frontend: premium episode unlock, gamification UI, and reader updates.
- Updated the legacy Laravel components and migrations alongside the port.

## 2026-04

- Author analytics and tier system, with database integrity refinements.
- Notification system and reader UI updates.

## 2026-03

- Initial full build: Laravel 12 backend (configuration, database schemas and
  migrations, core API controllers, route registration) and the Flutter app
  (dependencies, routing, theme, network services, authentication flow,
  reader discovery and library interfaces, author dashboard and publishing
  UI, platform folders and assets).
- Project description and ignore rules.
