# Curator and Guardian

| Function Name         | Prev. Step  | Permission           | Action |
| --------------------- | ----------- | -------------------- | ------ |
| applyName             |             | curator              | ...    |
| applySymbol           |             | curator              | ...    |
|                       |             |                      |        |
| setCurator            |             | curator              | ...    |
| revokePendingCurator  | setCurator  | curator              | ...    |
| acceptCurator         | setCurator  | new curator          | ...    |
|                       |             |                      |        |
| setGuardian           |             | curator              | ...    |
| revokePendingGuardian | setGuardian | curator OR guardian  | ...    |
| acceptGuardian        | setGuardian |                      | ...    |
|                       |             |                      |        |
| setTimelock           |             | curator              | ...    |
| revokePendingTimelock | setTimelock | curator OR guardian  | ...    |
| acceptTimelock        | setTimelock |                      | ...    |
|                       |             |                      |        |
| setModule             |             | curator              | ...    |
| revokePendingModule   | setModule   | curator OR guardian  | ...    |
| acceptModule          | setModule   |                      | ...    |
|                       |             |                      |        |
| applyFreeze           |             | curator              | ...    |
| removeFreeze          | applyFreeze | curator AND guardian | ...    |
