## PowerTimer

[![Build](https://github.com/jurakovic/PowerTimer/actions/workflows/build.yml/badge.svg)](https://github.com/jurakovic/PowerTimer/actions/workflows/build.yml)

![Screenshot](img/screenshot.png)

A small Windows tool that shuts down, restarts, logs off, locks, suspends (sleep) or hibernates the computer after a countdown or at a set time.

- **Countdown** – run the action after the entered hours, minutes and seconds
- **Set time** – run the action at the entered clock time (tomorrow if that time has already passed today)
- Up/Down arrow keys change the focused field
- Optional minimize to the system tray, with the remaining time in the tray tooltip
- Options for the default action, the default time delay, remembering the window position and a warning for a zero countdown; they are stored in `HKEY_CURRENT_USER\Software\Power Timer`

### Download

Every build on GitHub Actions uploads `PowerTimer.exe` as the **PowerTimer-win64** artifact (open the latest [Build run](https://github.com/jurakovic/PowerTimer/actions/workflows/build.yml) and download it from the *Artifacts* section). It is a single native executable with no runtime dependencies.

### Build

Power Timer is written in Free Pascal with [Lazarus](https://www.lazarus-ide.org/) (Lazarus 4.8 / FPC 3.2.2).

- **IDE** – open `src/PowerTimer/PowerTimer.lpi` in Lazarus and press *Run*
- **Command line**

	```
	lazbuild --build-mode=Release src/PowerTimer/PowerTimer.lpi
	```

	The executable is written to `src/PowerTimer/bin/x86_64-win64/PowerTimer.exe`.

### Tests

The unit tests are an fpcunit console application:

```
lazbuild tests/PowerTimerTests.lpi
tests/bin/x86_64-win64/PowerTimerTests.exe
```
