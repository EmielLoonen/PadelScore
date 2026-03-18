# Match Result API

## `POST /api/matches`

Submits a completed (or stopped) match result from the PadelScore watch app.

---

## Request

**Content-Type:** `application/json`

### Top-level fields

| Field | Type | Required | Description |
|---|---|---|---|
| `watchCode` | string | yes | Court code that links the watch to a court |
| `matchId` | string (UUID) | yes | Unique match identifier generated on-device |
| `startDate` | string (ISO 8601) | yes | Match start time |
| `endDate` | string (ISO 8601) | no | Match end time (null if stopped mid-match) |
| `durationSeconds` | integer | no | Duration in seconds (null if match not ended) |
| `winner` | integer (1 or 2) | no | Winning team number (null if match not completed) |
| `teams` | array[Team] | yes | Two team objects |
| `sets` | array[Set] | yes | All sets where at least one game was played |
| `stats` | Stats | yes | Computed match statistics |
| `pointLog` | array[PointEntry] | yes | Ordered log of every point played |

---

### Team object

| Field | Type | Description |
|---|---|---|
| `team` | integer (1 or 2) | Team number |
| `name` | string | Team display name |
| `players` | array[Player] | Two players |

### Player object

| Field | Type | Description |
|---|---|---|
| `code` | string | Court position: `A` or `B` (team 1), `C` or `D` (team 2) |
| `id` | string | Player ID from the coordinator system, or player name for guests |
| `type` | string | `"user"` (registered) or `"guest"` |
| `name` | string | Display name |

---

### Set object

| Field | Type | Description |
|---|---|---|
| `setNumber` | integer | 1-indexed set number |
| `team1Games` | integer | Games won by team 1 |
| `team2Games` | integer | Games won by team 2 |
| `winner` | integer (1 or 2) | Set winner (null if set was not completed) |
| `wasTiebreak` | boolean | Whether this set ended in a tiebreak |
| `tiebreakScore` | TiebreakScore \| null | Final tiebreak score if applicable |

### TiebreakScore object

| Field | Type | Description |
|---|---|---|
| `team1` | integer | Tiebreak points scored by team 1 |
| `team2` | integer | Tiebreak points scored by team 2 |

---

### Stats object

| Field | Type | Description |
|---|---|---|
| `team1` | TeamStats | Aggregated stats for team 1 |
| `team2` | TeamStats | Aggregated stats for team 2 |
| `players` | object | Map of player code → PlayerStats (`"A"`, `"B"`, `"C"`, `"D"`) |

### TeamStats object

| Field | Type | Description |
|---|---|---|
| `pointsWon` | integer | Total points won |
| `gamesWon` | integer | Total games won across all sets |
| `setsWon` | integer | Sets won |
| `serveWinPct` | float \| null | % of points won while serving (0.0–1.0) |
| `returnWinPct` | float \| null | % of points won while receiving (0.0–1.0) |
| `breakPointOpportunities` | integer | Number of break point opportunities |
| `breakPointsConverted` | integer | Break points actually won |
| `breakConversionPct` | float \| null | Break conversion rate (0.0–1.0) |
| `longestWinStreak` | integer | Longest consecutive points won |
| `clutchPointsWon` | integer | Points won at deuce, advantage, or in tiebreaks |

### PlayerStats object

| Field | Type | Description |
|---|---|---|
| `code` | string | Player code (`A`–`D`) |
| `name` | string | Display name |
| `team` | integer (1 or 2) | Team number |
| `pointsWon` | integer | Points credited to this player |
| `contributionPct` | float \| null | Share of team's total points won (0.0–1.0) |
| `onServeWinPct` | float \| null | % won when their team was serving (0.0–1.0) |
| `onReturnWinPct` | float \| null | % won when their team was receiving (0.0–1.0) |
| `serverWinPct` | float \| null | % won when this specific player was the server (0.0–1.0) |
| `gameWinningPoints` | integer | Number of game-winning points scored |
| `setWinningPoints` | integer | Number of set-winning points scored |
| `clutchPoints` | integer | Points scored at deuce, advantage, or in tiebreaks |
| `pointsBySet` | object | Map of set number string → points won, e.g. `{"1": 14, "2": 9}` |

---

### PointEntry object

One entry per point played, in chronological order.

| Field | Type | Description |
|---|---|---|
| `playerCode` | string \| null | Player who scored (`A`–`D`), null if not tracked |
| `team` | integer (1 or 2) | Team that won the point |
| `timestamp` | string (ISO 8601) | When the point was recorded |
| `servingPlayer` | string \| null | Player serving this point (`A`–`D`) |
| `servingTeam` | integer \| null | Team serving this point |
| `isTiebreak` | boolean | Whether this point was part of a tiebreak |
| `gameTeam1PointsBefore` | string \| null | Team 1 game score before point (`"0"`, `"15"`, `"30"`, `"40"`, `"AD"`) — null in tiebreaks |
| `gameTeam2PointsBefore` | string \| null | Team 2 game score before point — null in tiebreaks |
| `tiebreakTeam1Before` | integer \| null | Team 1 tiebreak score before point — null outside tiebreaks |
| `tiebreakTeam2Before` | integer \| null | Team 2 tiebreak score before point — null outside tiebreaks |
| `setTeam1GamesBefore` | integer | Team 1 games in current set before this point |
| `setTeam2GamesBefore` | integer | Team 2 games in current set before this point |
| `setNumber` | integer | 0-indexed set number |
| `matchTeam1SetsBefore` | integer | Sets won by team 1 before this point |
| `matchTeam2SetsBefore` | integer | Sets won by team 2 before this point |

---

## Response

### Success — `200 OK` or `201 Created`

No response body required. The watch app does not read the response body.

### Error — `4xx` / `5xx`

Any non-2xx status code is treated as a submission failure. The watch app will surface a generic error to the user.

---

## Example payload

```json
{
  "watchCode": "COURT-A1",
  "matchId": "550e8400-e29b-41d4-a716-446655440000",
  "startDate": "2026-03-17T10:00:00Z",
  "endDate": "2026-03-17T11:12:00Z",
  "durationSeconds": 4320,
  "winner": 1,
  "teams": [
    {
      "team": 1,
      "name": "Team 1",
      "players": [
        { "code": "A", "id": "user-123", "type": "user", "name": "Alex" },
        { "code": "B", "id": "user-456", "type": "user", "name": "Ben" }
      ]
    },
    {
      "team": 2,
      "name": "Team 2",
      "players": [
        { "code": "C", "id": "Carlos",  "type": "guest", "name": "Carlos" },
        { "code": "D", "id": "Diana",   "type": "guest", "name": "Diana" }
      ]
    }
  ],
  "sets": [
    {
      "setNumber": 1,
      "team1Games": 6,
      "team2Games": 3,
      "winner": 1,
      "wasTiebreak": false,
      "tiebreakScore": null
    },
    {
      "setNumber": 2,
      "team1Games": 7,
      "team2Games": 6,
      "winner": 1,
      "wasTiebreak": true,
      "tiebreakScore": { "team1": 7, "team2": 4 }
    }
  ],
  "stats": {
    "team1": {
      "pointsWon": 94,
      "gamesWon": 13,
      "setsWon": 2,
      "serveWinPct": 0.68,
      "returnWinPct": 0.44,
      "breakPointOpportunities": 7,
      "breakPointsConverted": 4,
      "breakConversionPct": 0.57,
      "longestWinStreak": 8,
      "clutchPointsWon": 18
    },
    "team2": {
      "pointsWon": 71,
      "gamesWon": 9,
      "setsWon": 0,
      "serveWinPct": 0.56,
      "returnWinPct": 0.32,
      "breakPointOpportunities": 3,
      "breakPointsConverted": 1,
      "breakConversionPct": 0.33,
      "longestWinStreak": 5,
      "clutchPointsWon": 11
    },
    "players": {
      "A": {
        "code": "A",
        "name": "Alex",
        "team": 1,
        "pointsWon": 52,
        "contributionPct": 0.55,
        "onServeWinPct": 0.70,
        "onReturnWinPct": 0.46,
        "serverWinPct": 0.72,
        "gameWinningPoints": 6,
        "setWinningPoints": 1,
        "clutchPoints": 10,
        "pointsBySet": { "1": 30, "2": 22 }
      }
    }
  },
  "pointLog": [
    {
      "playerCode": "A",
      "team": 1,
      "timestamp": "2026-03-17T10:00:08Z",
      "servingPlayer": "A",
      "servingTeam": 1,
      "isTiebreak": false,
      "gameTeam1PointsBefore": "0",
      "gameTeam2PointsBefore": "0",
      "tiebreakTeam1Before": null,
      "tiebreakTeam2Before": null,
      "setTeam1GamesBefore": 0,
      "setTeam2GamesBefore": 0,
      "setNumber": 0,
      "matchTeam1SetsBefore": 0,
      "matchTeam2SetsBefore": 0
    }
  ]
}
```

---

## Notes

- **Player codes** are positional for the match: `A`/`B` are always team 1, `C`/`D` are always team 2. The physical court side they play on varies per set.
- **Percentage fields** are `0.0–1.0` floats (not 0–100). Use `null` when there is no data (e.g. a team never served).
- **`pointsBySet` keys** are 1-indexed strings (`"1"`, `"2"`) since JSON object keys must be strings.
- **`pointLog`** is sorted chronologically and contains every point of the match. It can be used server-side to recompute any stat independently.
- The watch app sends this request once when the user stops or completes a match. There is no incremental/streaming endpoint.
