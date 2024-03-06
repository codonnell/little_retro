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
* Users cannot see what votes have been cast

### Discussion Phase

* Users go through the cards in order from most votes to least votes
* Users can create action items
