# sig_quart_bot

**General purpose Discord bot for individual guilds.**

## Installation

1. Install [Luvit](https://luvit.io/install.html).
2. Clone this repository.
3. Install the following packages with the Lit package manager.\
``lit install AntwanR924/Discordia``\
``lit install SinisterRectus/sqlite3``\
``lit install creationix/coro-spawn``.
4. Download a static build of [youtube-dl](https://github.com/ytdl-org/youtube-dl/releases).
5. Place the ``youtube-dl.exe`` in your bot directory.
6. Repeat steps 4 and 5 for [FFmpeg](https://github.com/BtbN/FFmpeg-Builds/releases).
7. Repeat steps 4 and 5 for both of the required audio encorder Dynamic Link Libraries (``.dll``) ``sodium`` and ``opus``, both can be found [here](https://github.com/SinisterRectus/Discordia/tree/master/bin).
8. Repeat steps 4 and 5 for the required [sqlite3](https://sqlite.org/download.html) Dynamic Link Library ``sqlite3``.
9. Create a Discord bot via the [Discord Developer Portal](https://discord.com/developers/applications) and add the Bot user to your guild.
10. Create a file ``.token`` and place your bot's token inside.
11. Create a valid [configuration](#configuration) file.
12. Start the bot with ``luvit main.lua``

## Configuration

Included in the repository is an example config (``config.json.example``) which contains the following hierarchy. When ready to use rename to ``config.json``.
```json
config.json
└───colours // decimal colours for various embeds.
│   │   default
│   │   ...
│   
└───keys // various API keys are stored here.
|   │   rapid // RapidAPI key for the ud command.
|   |   ...
|
│   prefix // command prefix. (default: ".")
│   debug // debug mode. (default: "false")
```

## Commands

| Command    | Description                                                                                          |
|------------|------------------------------------------------------------------------------------------------------|
| help       | Display all available commands with a description if available, proceeded by the configured prefix.  |
| ping       | *Pong!*                                                                                              |
| triggered  | Applies a triggered overlay to your Discord avatar.                                                  |
| lgbt       | Applies a LGBT flag overlay to your Discord avatar.                                                  |
| wasted     | Applies a Grand Theft Auto themed wasted overlay to your Discord avatar.                             |
| jail       | Applies a jail cell overlay to your Discord avatrar.                                                 |
| whois      | View various details about a guild member such as roles, date joined and status.                     |
| coin       | Flip a coin, heads or tails?                                                                         |
|            |                                                                                                      |
| play       | Play audio from a URL or search query. Some streaming services may not be supported.                 |
| summon     | Instruct bot to join your voice channel.                                                             |
| dc         | Disconnect bot from your current voice channel.                                                      |
| skip       | Skips the currently playing audio. If queue is not empty the next entry will be played.              |
| pause      | Pauses the currently playing audio.                                                                  |
| resume     | Resumes the currently playing audio.                                                                 |
| seek       | Set the position within the currently playing audio stream. Precise from hour to the second.         |
| volume     | Adjust volume of audio stream. Value is clamped from 0.1 to 100.0.                                   |
| time       | View position within the currently playing audio stream.                                             |
| queue      | View all queue entries. Includes title and duration.                                                 |
| clearqueue | Clear all entries within queue.                                                                      |