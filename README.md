# GameMaker Exception Base Class

[![Donate](https://img.shields.io/badge/donate-%E2%9D%A4-blue.svg)](https://musnik.itch.io/donate-me)
[![License](https://img.shields.io/github/license/KeeVeeGames/Exception.gml)](#!)

`Exception.gml` is a base class for custom exceptions in GameMaker.
It mirrors native exception fields and adds a consistent workflow for:

- `try...catch`
- `exception_unhandled_handler`
- crash report generation (`.exception` files)

The goal is to provide cleaner diagnostics across VM and YYC, with practical debugging metadata.

## Features

- Consistent exception fields: `message`, `longMessage`, `script`, `line`, `stacktrace`
- Crash report file generation with environment metadata
- Stable short crash signature (`Crash ID`)
- Runtime metadata in reports (OS, Runtime, Build Type, etc.)
- Snapshot capture support via `Snapshot(_value)`
- Breadcrumb trail support via `Exception.Breadcrumb("...")`
- Robust file save flow with `try...catch...finally` and JSON fallback to console

## Quick Start

Create a custom exception by inheriting from `Exception()`, setting `message` and `longMessage`, and calling `init()`.

```js
function TestException() : Exception() constructor {
    message = "Throw a test exception.";
    longMessage = "Long\nMessage\nis\nhere";

    init();
}
```

Arguments are supported:

```js
function ArgumentException(expected_number, given_number) : Exception() constructor {
    message = string("Number of arguments expected {0}, got {1}", expected_number, given_number);
    longMessage = message;

    init();
}
```

## Snapshot and Breadcrumb Usage

Use `Snapshot(_value)` inside the exception constructor before `init()`.

```js
function TestException() : Exception() constructor {
    message = "Throw a test exception.";
    longMessage = "Long\nMessage\nis\nhere";

    Snapshot({ id: "EX-88902", description: "Snapshot example" });
    Snapshot(self);

    init();
}
```

Use breadcrumbs globally before risky operations:

```js
Exception.Breadcrumb("F2 key pressed, about to throw ArgumentException");
throw new ArgumentException(3, 2);
```

Also available:

- `Exception.ClearBreadcrumbs()`

## Example `.exception` Report

```text
========================================
      GMLException Crash Report
========================================
Crash ID: EX-00LY3PZ3
Version: 2.0.0
Timestamp: 10-05-2026 05:42:37 PM
OS Type: Windows (0)
OS Version: 10.0
Browser: not_a_browser (non-browser target or GX.games) (-1)
Runtime Mode: VM
Game Version: 1.0.0.0
Runtime Version: 2024.14.4.268
Build Type: run
Build Date: 10-05-2026 05:42:35 PM
Release Mode: 2025

Snapshot:
---------
[]

Breadcrumbs:
------------
  - [10-05-2026 05:42:37 PM] F2 key pressed, about to throw ArgumentException

Short Message:
--------------
ArgumentException: Number of arguments expected 3, got 2

Long Message / Formatted Output:
--------------------------------
ERROR in action number 1
of  Step Event0 for object obj_exception_test:
ArgumentException: Number of arguments expected 3, got 2

 at gml_Object_obj_exception_test_Step_0 (line 14) -     throw new ArgumentException(3, 2);


Stacktrace:
-----------
  -> gml_Script_Exception (line 83)
  -> gml_Script___handler@anon@19178@UnhandledHandler@anon@19141@Exception@Exception (line 606)
  -> gml_Object_obj_exception_test_Step_0 (line 14)

========================================
End of Report
```

## Installation

Copy the [Exception script](https://github.com/KeeVeeGames/Exception.gml/blob/master/Exception/scripts/Exception/Exception.gml) into your project.

Or get the latest asset package from the [releases page](../../releases) and import it into the IDE.

## Compatibility Notes

- Confirmed in current work: Windows VM and Windows YYC.
- HTML5/OperaGX parsing improvements are planned for a future release.
- `os_browser` follows GameMaker behavior: GX.games returns `browser_not_a_browser`.

## Manual References

- [try...catch...finally](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Overview/Language_Features/try_catch_finally.htm)
- [exception_unhandled_handler](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/Debugging/exception_unhandled_handler.htm)
- [os_browser](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/OS_And_Compiler/os_browser.htm)
- [weak_ref_create](https://manual.gamemaker.io/beta/en/GameMaker_Language/GML_Reference/Garbage_Collection/weak_ref_create.htm)

## Author

Nikita Musatov - [MusNik / KeeVee Games](https://twitter.com/keeveegames)

**License**: [MIT](https://en.wikipedia.org/wiki/MIT_License)
