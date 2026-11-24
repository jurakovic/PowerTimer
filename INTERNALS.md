# Power Timer internals

How Power Timer is built and how it works: the structure of the code, the countdown, the power actions, the main window, the settings, the Windows details, testing, making changes and releasing.

## Contents

- [Overview](#overview)
- [Building](#building)
- [Source layout](#source-layout)
- [Countdown](#countdown)
- [Power actions](#power-actions)
- [Main window](#main-window)
- [Settings](#settings)
- [Windows details](#windows-details)
- [Tests](#tests)
- [Making changes](#making-changes)
- [Releasing](#releasing)
- [Known limitations](#known-limitations)

## Overview

- A Windows GUI program in **Free Pascal** (FPC 3.2.2) with the **Lazarus** component library, the LCL (Lazarus 4.8). Every unit is in `{$mode objfpc}{$H+}`.
- Its only dependencies are the LCL and the libraries that come with FPC; the tests use fpcunit. The result is a single `PowerTimer.exe` with no installer and no runtime dependencies.
- It is built and released for 64-bit Windows. The time logic, the input rules of the time fields and the countdown (`TimerLogic`, `TimeFields`, `Countdown`) have no UI or OS dependencies, and the Windows calls elsewhere are behind `{$IFDEF WINDOWS}`, so the tests build on any platform `fpc` targets, see [Tests](#tests).
- The settings are stored in the registry of the current user, see [Settings](#settings).
- Power Timer makes no network connections. The About box only opens its home page, `AppInfo.AppUrl`, in the browser (`OpenURL`).

## Building

Power Timer is built with [Lazarus](https://www.lazarus-ide.org/) 4.8 and FPC 3.2.2.

- **IDE**: open `src/PowerTimer.lpi` in Lazarus and press *Run*.
- **Command line**:

	```
	lazbuild --build-mode=Release src/PowerTimer.lpi
	```

	The executable is written to `src/bin/<cpu>-<os>/`, on 64-bit Windows `src/bin/x86_64-win64/PowerTimer.exe`.

`PowerTimer.lpi` has two build modes:

- **Release**, the default: optimization level 2, smart linking, no debug information, symbols stripped.
- **Debug**: range, overflow, I/O and stack checks, DWARF 3 debug information and heaptrc, with its units in `src/lib/<cpu>-<os>-debug/`.

Both are GUI programs (no console window). The manifest makes the program DPI aware per monitor (`PM_V2`), and `Application.Scaled` scales the forms.

**The version is supplied at build time.** The project's own version is 0.0.0, so a build from the IDE or with `lazbuild` shows 0.0.0 in the About box. `publish.sh build -v <version>` writes the version into `src/PowerTimer.lpi` before it builds and puts the file back when the script ends, also when the build fails: `x.y.z.0` as the file version, from the version without its `-` or `+` part, and the whole version, e.g. `1.0.1-preview.2`, as the product version. `AppInfo.AppVersion` reads the product version from the running executable's version resource, and the About box shows it. Nothing compares versions: Power Timer stores no version anywhere.

The "Build" workflow, `.github/workflows/build.yml`, builds Power Timer, runs the tests and uploads `PowerTimer.exe`. It runs for pushes to `master` that change `src/`, `tests/`, `publish.sh`, `.gitattributes` (the line ends of `publish.sh` on the Windows runner), the workflow itself or `.github/actions/setup-lazarus/`, and when run from the *Actions* tab (*Build* → *Run workflow*, for any branch). Changes to the docs alone don't run it.

- It runs on `windows-latest` and fetches the tags, since the version is computed from them: `<next release>-build.<run number>`, e.g. `1.0.1-build.42`, where the next release is what `publish.sh version -p false` gives, the version the Publish workflow would release from `master` next.
- It builds with `./publish.sh build -v <version> -u true`, the way releases are built, so the tests run first, see [Releasing](#releasing).
- It uploads `src/bin/x86_64-win64/PowerTimer.exe` as the artifact `PowerTimer_v<version>_win-x64`, which downloads as a zip named like a release.
- `.github/actions/setup-lazarus` installs Lazarus and FPC from the official Windows installer on SourceForge, in the versions above. The installer is cached, and its SHA-256 is checked before it runs. A new Lazarus version needs its version, its FPC version and the installer's SHA-256 in the action's defaults.

Both workflows pin their actions by commit hash.

## Source layout

All code is in `src/`; each form is a `.pas` unit with its `.lfm` form file.

| Area | Units |
|---|---|
| Startup | `PowerTimer.lpr`, `SystemLibraries` |
| Main window | `MainForm`, `AccessKeyLabel`, `TaskbarProgress` |
| Countdown | `Countdown`, `TimerLogic`, `TimeFields` |
| Actions | `PowerActions` |
| Warning | `WarningForm` |
| Settings | `AppSettings`, `OptionsForm` |
| About | `AboutForm`, `AppInfo` |

- `PowerTimer.lpr` lists `SystemLibraries` first in its `uses`, see [Windows details](#windows-details). It sets the title, lets the main form own the taskbar button (`MainFormOnTaskBar`), so hiding it to the tray removes the button, and creates the main form.
- `src/PowerTimer.ico` is the application icon; the main window, the tray icon and the About box use `Application.Icon`.
- `img/` holds the screenshot and the icon of the README.
- The unit tests are in `tests/`, see [Tests](#tests).

## Countdown

`TCountdown` in `Countdown` decides when the action runs. It gets the time (`Now`) and the tick count (`GetTickCount64`) passed in and runs the action through an event, so it has no UI or OS dependencies and is unit tested. The main form calls `Tick` from its countdown timer every 250 ms.

**Two modes** (`TCountdownMode`):

- `cmCountdown` waits for the entered duration by the tick count: the end is a deadline in ticks, so a change of the clock doesn't change it.
- `cmClockTime` waits until the clock shows the entered time: it keeps the target as a local date and time, today or tomorrow (`TimerLogic.NextOccurrence`: tomorrow when the time isn't at least 1 ms in the future), and compares it with the time on every tick. So it follows a change of the clock, e.g. to or from daylight saving time, and a clock set forward past the target runs the action at once.

**Start.** `Start` returns False and starts nothing for 00:00:00 in Countdown mode; the main form then asks, if *Warn me if countdown time is zero* is on, and runs the action itself. At time always starts: a clock time always has a next occurrence. Before it starts, the main form checks whether Sleep or Hibernate can run, see [Power actions](#power-actions).

**The end time.** `EndTime` is when the action runs, for the status bar. In At time mode it is the target. In Countdown mode it is the end computed at `Start`, kept as long as the time and the tick count move on together, so it doesn't flicker when they drift by a millisecond; once the time plus the time left differs from it by more than 2 seconds, e.g. after the clock was changed, it is that instead. The seconds left are rounded up, so 00:00:00 shows only when it is time.

**The warning.** `OnWarn` fires once when at most `WarnSeconds` are left. The main form sets `WarnSeconds` to `TimerLogic.WarnSeconds`, 60, or to 0 when *Warn 1 minute before the action* is off. A countdown that isn't longer than `WarnSeconds` doesn't warn: whoever started it knows when it ends.

**Adding time.** `Postpone` moves the end later, the deadline in Countdown mode and the target in At time mode, and warns again before the new end. The entered time stays, so a stop shows the time that was entered. The minutes are `AddMinutes` of the settings, from `MinAddMinutes` (1) to `MaxAddMinutes` (120), `DefaultAddMinutes` (10) by default.

**Sleep.** The ticks run only while the computer is awake, but the tick count goes on while it sleeps or hibernates. A gap of more than `SleepGapMs` (10 seconds) between two ticks means the computer was asleep. When the end passed during such a gap, the action doesn't run on waking: the end moves to `WakeGraceSeconds` (60) after waking, `EndedDuringSleep` is set and `OnWarn` fires, whatever `WarnSeconds` is, and the warning says that the time passed while the computer was asleep. `Postpone` and a new `Start` clear `EndedDuringSleep`.

**The time fields.** The fields take two digits each, up to 23:59:59 (`MaxHour`, `MaxMinute`, `MaxSecond`); `TimeFields` has their input rules: what a key press may type, the Up/Down steps, which wrap around, and the parsing, which clamps. The default delay of the settings (1 to 24 hours) fills them: in Countdown mode as hours (`DefaultCountdown`, which shows 24 hours as 23:59:59), in At time mode as the time that many hours from now (`DefaultClockTime`). While running, Countdown mode counts down in the fields, up to 99:59:59 (`MaxFieldSeconds`, `SecondsToFieldParts`), and At time mode shows the end time there.

**The texts** of the status bar, the window title and the tray menu are built in `TimerLogic` (`CountdownStatus`, `CountdownTitle`, `TrayTimeLeft`), and the warning's message in `WarningForm`, with the seconds left from `TimerLogic.FormatSecondsLeft`. The end times use the time format of the user's Windows settings (`DefaultFormatSettings`): the short time format, or the long one, with seconds, in At time mode when the entered seconds aren't zero. Their formats are resource strings; the action names in them are the constants of `PowerActionInfo`, see [Power actions](#power-actions).

## Power actions

`PowerActions` describes each action once, in `PowerActionInfo`. A new action is one entry there, and the table doesn't compile without an entry for every `TPowerAction`.

| Action | Runs through | `shutdown.exe` arguments | Can force |
|---|---|---|---|
| Shut down | `shutdown.exe` | `/s /t 0` | yes |
| Restart | `shutdown.exe` | `/r /t 0` | yes |
| Sign out | `ExitWindowsEx` with `EWX_LOGOFF` | | yes |
| Lock | `LockWorkStation` | | no |
| Sleep | `SetSuspendState` in `powrprof.dll` | | no |
| Hibernate | `shutdown.exe` | `/h` | no |

- **Forcing.** With *Force apps to close*, the actions that can force close the apps without saving: `shutdown.exe` gets `/f` (`ShutdownArguments`), and Sign out `EWX_FORCE`. Without `/f`, `shutdown.exe /t 0` waits for apps that don't close by themselves; only a time-out above 0 implies `/f`. Sign out uses `ExitWindowsEx`, since `shutdown.exe /l` takes no other options and can't be forced. Lock, Sleep and Hibernate don't close apps.
- **`shutdown.exe`** is started by its full path in the system directory (`ShutdownExePath`), hidden, and waited for; an exit code other than 0 is an error.
- **Sleep** calls `SetSuspendState(False, False, False)`: sleep, not hibernate, with wake events left on, so a wake timer such as a scheduled task can wake the computer, as after Sleep from the Start menu. It needs the shutdown privilege, which interactive users have but disabled, so `EnableShutdownPrivilege` enables it in the process's own token first. `powrprof.dll` is loaded on first use, see [Windows details](#windows-details).
- **Availability.** `PowerActionUnavailableReason` asks `GetPwrCapabilities` whether Sleep and Hibernate can run, and `UnavailableReason` decides: Sleep needs one of the sleep states S1 to S3, or Modern Standby, on which Windows reports no sleep state although `SetSuspendState` puts the computer to sleep; Hibernate needs S4 and the hibernation file, and without the file the reason says how to turn hibernation on. When the capabilities can't be read, the action counts as available. *Start* shows the reason and asks whether to start anyway, in case the check is wrong on some computer. `TSystemPowerCapabilities` is the Windows SDK's `SYSTEM_POWER_CAPABILITIES`, 76 bytes; a test checks its layout.
- **Errors.** `ExecutePowerAction` returns False with a message when the action can't be started, and the main form shows it.
- **Stored order.** The ordinal of a `TPowerAction` is stored in the settings (`defaultAction`), and the action combo boxes are filled from the table (`FillPowerActionList`) so that an item's index is its action's ordinal. New actions are only appended; an action is never reordered or removed.

## Main window

`TfrmMain` in `MainForm` holds the window, the tray icon and the `TCountdown`, and connects them.

- **Status bar.** While idle, its text follows the mode, the fields, the action and the clock: the status timer updates it every 250 ms, with `CountdownStatus` and `skCountdownIdle` (when the action would run if started now) or `skClockIdle` (when it runs, *tomorrow* once the entered time has passed today). While running, the countdown timer updates it with `skRunning`: the end time and the time left. Its links are labels with actions: *Options* (Alt+O) and *About* (Alt+A) while idle, and in their place *+10 min* (Alt+M) while running. The caption of *+10 min* names the minutes set in the options.
- **Running.** The mode buttons, the action and *Options* and *About* are disabled. The time fields become read-only rather than disabled, which Windows would draw greyed out, so the time stays readable, and they leave the tab order. *Start* becomes *Stop* and is no longer the default button, so Enter doesn't stop by accident; Esc stops (`FormKeyDown`). Closing the window while running asks first.
- **Title and taskbar.** While running, the title is the time left first (`CountdownTitle`), so a narrow taskbar button and Alt+Tab show it. `TaskbarProgress` shows the progress on the taskbar button through the shell's `ITaskbarList3`: the time passed, out of the seconds left at the start plus the time added since. Windows drops the bar when the button is created again, e.g. after the window comes back from the tray, so it is set again with every change of the seconds left. Every failure there is ignored.
- **Tray.** With *Minimize to system tray*, minimizing hides the window and shows the tray icon; a click on it, or *Show*, brings the window back. While running, the tooltip shows the time left, the tray menu's first line is the time left (`TrayTimeLeft`), and *Stop countdown* and *Add 10 minutes*, with the minutes set in the options, appear. The countdown timer keeps firing while the menu is open, and since Windows doesn't promise to repaint an open menu when an item changes, `RepaintOpenMenu` invalidates the menu's window, of the class `#32768`.
- **Texts.** The tray tooltip, the window title and the status text are only set when they change: the timers fire four times a second.
- **Access keys.** `AccessKeyLabel` declares a `TLabel` that underlines its access key only while Alt is held down in its form, or always with *Underline access keys* on in the Windows settings; LCL labels underline it all the time. The class keeps the name `TLabel`, so `MainForm`, which lists the unit after `StdCtrls`, gets it for all its labels, while its form file and the designer keep plain `TLabel`s. The main form repaints the labels (`RepaintAccessKeys`) when Alt goes down or up and when the window is activated or deactivated, since Alt may have been released in another window.
- **Focus.** At startup an empty, zero-size panel holds the focus, so nothing looks selected until the user clicks a control or presses Tab.
- **Warning.** `TfrmWarning` in `WarningForm` is created at the first warning. It stays above all other windows (`fsSystemStayOnTop`) and has its own taskbar button, also while the main window is in the tray. It may open while the user is typing in another program, so no key presses a button: an empty panel takes the focus on every show, and there is no default or cancel button. *Cancel* stops the countdown, *+10 min*, with the minutes set in the options, adds time; closing the window only hides it, and the action still runs. A line under the countdown says when the time passed while the computer was asleep. The warning hides whenever the countdown stops, ends or gets more time.
- **Options.** `OptionsForm.EditSettings` edits a copy of the settings, written back only on *OK*. They apply as the window would have changed with them: a new default action is selected, and a new default delay resets the time fields; a setting that didn't change changes nothing, so a time the user typed stays. They are saved right away, and a failure is reported.
- **About.** `AboutForm` shows the title with the version (`AppTitleWithVersion`), what Power Timer does and a link to its home page.

## Settings

`AppSettings` keeps the settings in `HKEY_CURRENT_USER\Software\Power Timer` (`DefaultRegistryKey`), one `REG_DWORD` value each. The value names are part of the stored format: renaming one loses that setting.

| Value | Field of `TAppSettings` | Default | Range |
|---|---|---|---|
| `defaultAction` | `DefaultAction` | 0, Shut down | an ordinal of `TPowerAction`; others give Shut down |
| `defaultTimeDelay` | `DefaultDelayHours` | 1 | 1 to 24 hours |
| `addMinutes` | `AddMinutes` | 10 | 1 to 120 minutes |
| `minimizeToTray` | `MinimizeToTray` | 0 | 0 off, else on |
| `rememberWinPos` | `RememberWindowPos` | 0 | 0 off, else on |
| `warnZeroTime` | `WarnZeroTime` | 0 | 0 off, else on |
| `warnBeforeAction` | `WarnBeforeAction` | 1 | 0 off, else on |
| `forceActions` | `ForceActions` | 0 | 0 off, else on |
| `positionX`, `positionY` | `WindowLeft`, `WindowTop` | none | used only when both are there (`HasWindowPos`) |

- `LoadSettings` starts from `DefaultSettings`. A missing key or value, or one that isn't a number, gives the default, and `NormalizeSettings` brings the values into their ranges, e.g. after the registry was edited by hand. `SaveSettings` normalizes too, and writes 0 or 1 for the switches.
- The window position is the normal position (`RestoredLeft`, `RestoredTop`), also while minimized. It is saved every time, and used at startup only with *Remember window position* on and when the window would be on a monitor, e.g. not after a second monitor was disconnected.
- The settings are saved when the window closes, on *OK* in the Options dialog, before an action runs, since shutting down, restarting and signing out may end the process without the window being closed, and when Windows ends the session (`AppEndSession`): the LCL closes no forms then, it only runs the end-session handlers. Only *OK* reports a failure; elsewhere saving is silent.

## Windows details

- **DLLs from the system directory only.** A DLL loaded by its name alone is looked for in the folder of `PowerTimer.exe` first, so a DLL of that name planted there, e.g. in Downloads, would be loaded and run. `SystemLibraries` prevents that: its initialization makes every later load of a DLL by its name alone, also by the LCL, search only the system directory (`SetDefaultDllDirectories`). That needs Windows 8, or Windows 7 with update KB2533623; without it, it at least takes the current directory out of the search (`SetDllDirectoryW`). The LCL units load DLLs by name, some in their own initialization, so `PowerTimer.lpr` lists `SystemLibraries` first, and it uses only `Windows` and `SysUtils`.
- **`LoadSystemLibrary`** loads a DLL from the system directory, never from the program's folder, by its full path where the flag isn't known. `powrprof.dll` is loaded with it on first use instead of being imported: Windows loads an imported DLL when the program starts, and since `powrprof.dll` isn't one of the known DLLs, it would look for it next to `PowerTimer.exe` first. `user32.dll` is one of the known DLLs, which Windows always loads from the system directory, so `LockWorkStation`, `FindWindowA` and `InvalidateRect` stay imported.
- **`shutdown.exe`** is started by its full path (`ShutdownExePath`), since a bare `shutdown.exe` would be looked for in the program's folder first.
- **Privileges.** Power Timer runs as the user and asks for no elevation. It only enables the shutdown privilege in its own token, for Sleep.
- **COM.** `TaskbarProgress` initializes COM on the main thread on first use and creates the shell's taskbar object; it releases both when the program ends.

## Tests

The unit tests are an fpcunit console program, `tests/PowerTimerTests.lpi`:

```
lazbuild tests/PowerTimerTests.lpi
tests/bin/x86_64-win64/PowerTimerTests.exe
```

The runner runs all tests and prints plain text; `--help` lists its other options, e.g. `--format=xml`. It is built for the platform `fpc` targets, so it also runs elsewhere, e.g. on Linux (`tests/bin/x86_64-linux/PowerTimerTests`, with the registry emulated in a file). `publish.sh build` builds and runs it before every build of Power Timer, so the Build and Publish workflows fail on a failing test.

| Unit | Covers |
|---|---|
| `TimerLogicTests` | Seconds to hours, minutes and seconds and back, 24 hours and more, the 99:59:59 of the fields; the next occurrence of a clock time, later today, earlier or now meaning tomorrow; rounding up of the seconds left; the clamped delay and minutes; the default countdown and clock time; the texts: durations, seconds left, the end time today, tomorrow, on a later day and with seconds, the status bar idle, right away, tomorrow, running and over midnight, the window title and the tray menu |
| `TimeFieldsTests` | Parsing with invalid text and clamping, two digits, Up/Down wrapping around, what may be typed, a key at the caret, over a selection, backspace and other control keys |
| `CountdownTests` | Countdown and At time to the end and after it, a zero countdown, stopping, a clock set back and forward, Countdown mode ignoring the clock; the end time, also after a clock change; the warning once, not for a short countdown, never with 0, in At time mode, again after a restart; adding time in both modes; sleeping through the end in both modes, also with the warning off, waking before the end, no gap, stopping or adding time during the announcement, sleeping again |
| `PowerActionsTests` | The stored order and out of range indexes, the list order, the names and kinds, the `shutdown.exe` arguments with and without forcing, which actions can force, the path of `shutdown.exe`, the availability of Sleep and Hibernate, the layout of `TSystemPowerCapabilities` |
| `SystemLibrariesTests` | Paths in the system directory, loading a DLL from there, a missing DLL |
| `AppSettingsTests` | The defaults, clamping, a missing key, saving and loading, invalid values, a position with only one coordinate; under `Software\Power Timer Tests`, which the tests delete again |
| `AppInfoTests` | The title with and without a version, no version resource |

The tests of the system directory and of `shutdown.exe`'s path check real paths only on Windows. The forms, the tray, the taskbar, the actions themselves and anything that needs sleeping or a change of the clock are tested by hand, see [Manual tests](#manual-tests).

### Manual tests

What the unit tests don't cover, worth checking on a real computer before a release:

- Each action, with *Force apps to close* off and on: with an editor holding an unsaved document, Shut down, Restart and Sign out wait at Windows' *closing apps* screen when off, and close the editor when on.
- Hibernate with hibernation turned off (`powercfg /hibernate off`): *Start* says how to turn it on and asks; *No* starts nothing. Turning hibernation off doesn't affect Sleep, which *Start* only questions on a computer without a sleep state, e.g. some virtual machines.
- A countdown of a few minutes: the warning a minute before, above other windows, without taking the keys typed in another program; *Cancel* stops, *+10 min* adds the minutes set in the options and warns again.
- Put the computer to sleep past the end, then wake it: the warning says that the time passed while asleep, and the action runs a minute later, also with the warning turned off.
- At time across a change of the clock: set the clock past the time, the action runs at once; set it back, it waits longer.
- While running: the title, the taskbar progress, also after the window comes back from the tray, the tray tooltip, and the tray menu's time left counting down while it is open, *Stop countdown* and *Add 10 minutes*.
- Alt underlines the access keys only while held, also after Alt+Tab; Alt+O, Alt+A and, while running, Alt+M.
- Options: each one is stored on *OK* and read back after a restart, and the window comes back at its position with *Remember window position*.
- The About box shows the version of a release build.

## Making changes

### Adding a power action

1. Append it to `TPowerAction`, never in the middle: the ordinals are stored.
2. Add its entry to `PowerActionInfo`: its name, how it runs (a new `TActionKind` with its branch in `ExecutePowerAction`, if none fits), its `shutdown.exe` arguments and whether it can force.
3. If it can be unavailable on some computers, a reason in `UnavailableReason` and the check in `PowerActionUnavailableReason`.
4. Tests in `PowerActionsTests`; the README's list of actions and the table in [Power actions](#power-actions).

### Adding a setting

1. A field in `TAppSettings`, its default in `DefaultSettings`, and its range in `NormalizeSettings` if it has one.
2. A value name constant in `AppSettings`, read in `LoadSettings` and written in `SaveSettings`. The name is part of the stored format.
3. Its control in `OptionsForm` and `OptionsForm.lfm`, in `ReadSettings` and `WriteSettings`, and what changes in the main window on *OK* in `TfrmMain.ShowOptions`.
4. Tests in `AppSettingsTests`; the README's Options section and the table in [Settings](#settings).

## Releasing

Releases are made with the "Publish" workflow, `.github/workflows/publish.yml`, from the *Actions* tab (*Publish* → *Run workflow*). The work is done by `publish.sh`, which runs locally as well, in Git Bash on Windows, see `./publish.sh --help`.

1. **Build** (`publish.sh build`): runs the tests and builds `PowerTimer.exe` with the version, see [Building](#building).
2. **Package** (`publish.sh package`): checks with PowerShell that `PowerTimer.exe` has that product version, where PowerShell is there, zips it (with `zip`, else `7z`) as `release/PowerTimer_v<version>_win-x64.zip`, and writes its SHA-256 to `release/checksums.txt`.
3. **Release**, in a second job, the only one with write access: tags the built commit `v<version>` and pushes the tag (`publish.sh release`; the tag may already be on that commit when a failed release is run again), then creates the GitHub release `v<version>` with the zip and `checksums.txt` and generated notes, as a pre-release if the version has a `-`. Run locally, `publish.sh release` asks before it tags and pushes, and creates no GitHub release.

**The version** (`publish.sh version`) is computed from the tags of one major version stream, by default the major of the latest release or preview tag (`v1.2.3` or `v1.2.3-preview.1`), but at least `FIRST_MAJOR`, 1. *Base Ver* picks another stream, e.g. `1` for a fix of 1.x after 2.0.0. Run from `master`, the version is the next release, e.g. `1.0.1` after `1.0.0`; from another branch, or with *Preview*, the next preview, e.g. `1.0.1-preview.1`, then `1.0.1-preview.2`. *Bump Type* (major, minor or patch, by default patch) picks the part that is increased. While a preview is open, ahead of the latest release, a bump it doesn't pass continues it (a patch always does), and one that passes it starts a new version from the latest release: after `1.0.0` and `1.0.1-preview.2`, patch gives `1.0.1` (or `1.0.1-preview.3` from another branch), minor gives `1.1.0` (or `1.1.0-preview.1`). With no tag in the stream it is `<stream>.0.0`, or `<stream>.0.0-preview.1` for a preview. *Version* sets the version directly; it must be a semantic version. An existing tag is an error.

- The *Step* inputs turn off building, packaging or releasing, e.g. to build a zip for testing without a release; packaging needs building, and releasing needs both.
- *Source branch* builds another branch, with the `publish.sh` and `.github/actions` of the branch the workflow runs from.
- Runs don't overlap (`concurrency`), so two runs can't pick the same version.
- The run summary shows the version, the commit and the SHA-256 of the zip, and the run keeps `release/` as an artifact.

## Known limitations

- The texts are in English only, and there are no translations. The texts in the code are resource strings, except the action names, which are constants in `PowerActionInfo`; the forms' texts are in their `.lfm` files.
- In Countdown mode, the time fields show at most 99:59:59 while running; with more time left after adding time, they stay there, while the status bar, the title and the tray show the real time left.
