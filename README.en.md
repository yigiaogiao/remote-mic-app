# SayAll · Mac mini Sleep Isolation Experiment

[简体中文](README.md)

A personal experimental fork maintained by **yigiaogiao**, based on [HD838A/remote-mic-app](https://github.com/HD838A/remote-mic-app). It explores RC003 remote sleep isolation and wake reconnection on a Mac mini. It is not an official upstream release.

## Purpose and limitations

The maintainer's Mac previously woke without any remote button input. This branch attempts to isolate the selected remote before system sleep, preserve pairing, and restore connection after full wake. Screen saver events alone do not trigger isolation; global Bluetooth and system sleep timers are not changed.

Positive usage reports cover one Mac mini only. Other Mac mini systems and other Mac models are unverified. The mechanism uses undocumented macOS CoreBluetooth options: an app disconnection does not prove removal as a system wake source.

The upstream author independently tested the same isolation mechanism on a MacBook Pro and observed Bluetooth HID FullWake twice. This is a documented counterexample; this project does not claim a general fix. [Upstream PR #778](https://github.com/HD838A/remote-mic-app/pull/778) is closed.

## Changes in this branch

- Opt-in, machine-local RC003 sleep isolation and target reconnect gating.
- Recovery after full system wake, an awake display and an on-console session.
- Local candidate **2.0.0 / 267.3** keeps discovering the recovery target to reduce the previous gaps of up to one minute.
- One bounded fast retry for an unexpected ready-link loss while awake, plus recovery timing logs.

Real wake-recovery improvement and sleep regression for 267.3 remain unverified. The full SwiftPM suite was blocked by the local XCTest environment. Unit tests and successful startup reconnection do not establish real sleep protection.

## Availability and usage

**Source only: no experimental installer is published here.** Upstream version fields do not identify a published 267.3 candidate, and upstream website downloads do not contain these changes.

Existing local candidate users can select the paired RC003 in Connection & Voice and enable the experimental sleep-isolation option while keeping the app running. Wake the Mac with another input device; a remote button press may be needed to reconnect. No fixed reconnection time is guaranteed.

Disable the option to stop future isolation. To revert, quit the candidate before launching the original app; do not run both against the same device.

## Attribution and license

Thanks to **HD838A and upstream contributors** for SayAll. Original Git history, source copyright notices and the [GPL-3.0 license](LICENSE.md) are retained. See the [upstream README](https://github.com/HD838A/remote-mic-app/blob/main/README.md) for the original product introduction.

This fork's description does not imply upstream endorsement.

[Developer documentation](DOCUMENTATION.md)
