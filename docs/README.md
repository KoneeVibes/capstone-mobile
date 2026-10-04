# Property Intel — developer docs

Everything that does not fit in the [root README](../README.md) but that a
contributor needs to work on this app without guessing.

| Guide | Read it when you are… |
| --- | --- |
| [Architecture](architecture.md) | adding a feature, or wondering where a file belongs |
| [State management](state-management.md) | writing a provider or a notifier |
| [Dependency injection](dependency-injection.md) | wiring a new datasource, or overriding something in a test |
| [Error handling](error-handling.md) | catching anything, or showing an error to the user |
| [Networking](networking.md) | calling a new endpoint |
| [Navigation and auth](navigation-and-auth.md) | adding a route, a tab, or anything that depends on who is signed in |
| [UI and design system](ui-and-design-system.md) | building a screen or a widget |
| [Accessibility](accessibility.md) | building anything a user touches |
| [Testing](testing.md) | writing or running tests, or checking a feature against the live API |
| [Tooling](tooling.md) | running the app, regenerating icons, or driving the emulator |
| [Coding standards](standards.md) | reviewing or writing any code |
| [Architecture decisions](adr/README.md) | asking "why is it like this?" |

## Keeping these current

A doc that is wrong is worse than no doc. When a change makes a statement here
untrue, fix the statement in the same pull request. When a decision changes,
add a new ADR that supersedes the old one rather than editing history.
