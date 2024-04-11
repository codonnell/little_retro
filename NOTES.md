# Notes

## Goal

Be a simple, fast, reactive, and easy to use retro platform.

## Design

We use Phoenix PubSub to distribute live updates to all users actively on the retro.

### Create Retro

* When creating the retro, determine the number of columns and their names. One user is designated as the moderator.

### Card Creation Phase

* Each user adds cards to columns
* Users can edit and delete their own cards
* Users can see that other users have created cards, but not what's written on them

### Grouping Phase

* Users can drag cards onto other cards to group them together

### Voting Phase

* Users can allocate a certain number of votes on cards
* Users cannot see what votes other users have cast

### Discussion Phase

* Users go through the cards in order from most votes to least votes
* Users can create action items
* Could we allow users to write notes for a group of cards to capture non-action item discussion?

## Code

* Unsure how much value the `LittleRetro.Retros` context module provides.
* Business logic almost all lives in the aggregate module; this doesn't feel sustainable over the long haul, but it's unclear how to effectively break it up given the pattern matching requirements. Perhaps we could nest related [command handler](https://hexdocs.pm/commanded/Commanded.Commands.Handler.html) and [event handler](https://hexdocs.pm/commanded/Commanded.Event.Handler.html) modules in a parent module? (Eg. commands and events per phase are grouped together.) Really want to keep phase implementations colocated in the same file. We could potentially also put the command and event module definitions there, too for improved cohesion.
