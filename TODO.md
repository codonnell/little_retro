# TODO

- [x] Figure out why event store is failing to init
- [x] Get create retro command working
- [x] Allow passing in an ID to create retro, and check types
- [x] Check that moderator id is a real user before starting
- [x] Create UI for starting retro
- [x] Add commands and events for managing users
- [x] Create modal for managing retro participants
  - [x] Make modal open/closable
- [x] Add page for card creation (hard-coding start/stop/continue)
- [x] Authz for create cards page
- [x] Users can create cards
  - [ ] Tests for card creation in liveview
- [x] Users can write text in a card
  - [ ] Tests for card editing domain
  - [ ] Tests for card editing in liveview
- [ ] Users can delete cards
- [x] Other users' cards are hidden

## Later

- [ ] Make real header
- [ ] Make styling consistent between tailwind-ui and generated phoenix components

## Questions

Should user invites exist outside of the aggregate? It's somewhat orthogonal, even in the UI.
