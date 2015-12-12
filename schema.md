# Overview

Croupier uses Syncbase to store game data and player settings. It is the primary
means of communication between players. Since Syncbase Mojo only allows storage
of bytes, the schema for Croupier assumes only string keys and values.

# Game Table

This table stores information about all the games that the player has ever
participated in. The schema is as follows:

```
For advertising and setting up the game:
<game_id>/game_sg = <game_syncgroup_name>
<game_id>/type = <game_type>
<game_id>/owner = <user_id>
<game_id>/status = [null|RUNNING]
<game_id>/players/<user_id>/player_number = <player_number>
<game_id>/players/<user_id>/settings_sg = <settings_syncgroup_name>

For the game log writer:
<game_id>/log/<timestamp>-<player_id> = <command_string>
<game_id>/log/proposals/<player_number> = <JSON-encoded Proposal>
```

The game log writer is a protocol where all players in the same game write their
moves to a game log. Games are structured such that replay of the log in key
order will lead to the exact same UI state.

When player actions are turn-based or independent from each other, players
writes can occur to the log in an order enforced by the application. However, if
the actions are dependent, then the proposals protocol is followed.

Proposals are described below. Since the proposal system is not efficient with
the current implementation of Syncbase, it has been avoided as much as possible.

```
// Proposals are used to obtain consensus between all players when a game allows
// users to make actions simultaneously that conflict with each other. When a
// proposal is made, players will agree with the proposal with the lowest
// timestamp (and player_number, if there are ties). Once all players are in
// agreement, no further changes can be made, so the command proposed can be
// safely executed. This protocol ensures that only one of these conflicting
// actions can proceed.
struct Proposal {
  timestamp int         // When the proposal was created.
  command_string string // What ought to be run if the proposal goes through.
  player_number int     // Original player that proposed this command.
}
```

# Settings Table

This table stores information about the player and every user they have ever
interacted with. The schema is as follows:

```
users/<user_id>/settings = <JSON-encoded Settings>
users/personal = <user_id>
```

The settings table will inform the user of their random, unique `<user_id>`.
When a user id is found, the relevant settings data can be retrieved and
displayed. The user is allowed to personalize their profile.

```
// Settings contains the personal settings for a Croupier player.
// This consists of fake identifying information that helps them differentiate
// themselves from each other during the game.
// Note: This is NOT tied to the user's blessing, so it should never be used for
// authentication or authorization purposes.
struct Settings {
  userID int    // Cannot be changed by the user.
  avatar string // Must point to an avatar asset bundled into the app.
  name string   // The user's display name in-game. Usually a pseudonym.
  color int     // An 8 digit hex-encoded integer. 0x{alpha}{red}{green}{blue}
}
```

## Syncgroups

Croupier has two types of Syncgroups: one for games and one for settings.
* Game Syncgroups
  * Table: The Games table, Prefix: `<game_id>`
    * ACLs are not implemented, but in theory, it would be like this:
    * ACL: Owner: RWA, Players: RW, NonPlayers: RW ==> R (after game starts)
* Settings Syncgroups are based on the `<user_id>` prefix.
  * Table: The Settings table, Prefix: `<user_id>`
    * ACLs are not implemented, but in theory, it would be like this:
    * ACL: Owner: RWA, Other Players: R

When a game is created, the owner will advertise both the game Syncgroup as well
as their own settings Syncgroup. Players can discover the owner's `<game_id>`
and `<user_id>` and decide if they wish to join that game.
