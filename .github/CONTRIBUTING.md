# Contributing

Thank you for considering contributing to this project! This document outlines how to get set up and what's expected when submitting changes.

## Getting Started

- **Godot version:** This project generally targets the most recent full release of Godot, currently **4.7.x**.
- **Clone and open:**
  1. Get the repository link from the "Code" dropdown on GitHub.
  2. Clone the repository.
  3. Open the Godot project located at `/demo/`.
- **Dependencies:** None external. The project uses the "Plugin Reloader" plugin, which is already included when you clone the repository.

## How to Contribute

- All changes go through **Pull Requests** targeting `main`.
- Branch off of `main` for your changes.
- Both the contributor and the reviewer are required to test all changes before a PR is approved.
- Use the provided issue templates when reporting a bug or requesting a feature.

## Code Conventions

This project generally follows the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html), with one exception: boolean operators are kept in their non-English symbolic form (`&&`, `||`, `!`) rather than the plain-English keywords (`and`, `or`, `not`).

Following the style guide includes, but is not limited to:

- Code order
- Indentation
- Formatting of multiline statements
- Usage of blank lines
- Line length
- Comment spacing
- Usage of whitespace around operators and after commas
- Naming conventions

In addition to the style guide, this project follows these rules:

- Always use **static typing**. Do not use inferred types (`:=`).
- Keep all script content in **English**, including all comments.
- Prefix all function parameters with `p_`.
- Add documentation comments where useful and practical.

## Review Process

- Any contributor who has had at least one PR approved can be requested as a reviewer.
- Reviews should generally happen within **one week**.
- Requested changes should be implemented if they seem reasonable. If a requested change seems unreasonable, it should be discussed calmly and objectively rather than dismissed or implemented without agreement.
