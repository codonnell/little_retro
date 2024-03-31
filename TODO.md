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
  - [x] Tests for card creation in liveview
- [x] Users can write text in a card
  - [x] Tests for card editing domain
  - [x] Tests for card editing in liveview
- [x] Users can delete cards
  - [x] Tests for card deletion domain
  - [x] Tests for card deletion in liveview
- [x] Other users' cards are hidden
- [x] Fix "Attempting to reconnect" in liveview tests
- [x] Transition to grouping phase
- [ ] Grouping cards
  - [x] Grouping domain functions
  - [ ] Grouping UI
    - [x] Drag cards to group into a tight stack
    - [x] Make stacks expandable client-side (probably alpine.js, but maybe LiveView.JS)
    - [x] Drag cards out of an expanded stack OR click to remove a card from an expanded stack
    - [ ] Label stacks
- [x] Voting for cards
  - [x] Write voting domain functions
  - [x] Write voting UI
- [ ] Discussion
  - [ ] Write discussion domain functions
  - [ ] Write discussion UI
- [ ] Action items
  - [ ] Write action item domain functions
  - [ ] Write action item UI
- [ ] See currently active retros on homepage
- [ ] Delete unused header entries
- [ ] Deploy


## Later

- [x] Write README
- [ ] List completed retros (show action items?)
- [ ] Navigate to completed retros (ready only mode?)
- [ ] After a user is removed, they are redirected from the liveview if they try to do an action
- [ ] Make styling consistent between tailwind-ui and generated phoenix components

## Questions

Should user invites exist outside of the aggregate? It's somewhat orthogonal, even in the UI.
