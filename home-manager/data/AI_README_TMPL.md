This AI_README.md file provides project information specifically for use in LLM context. The README.md will contain project information that is more generally useful for humans and AI.

# CONVENTIONS

- Use type annotations wherever possible

# DEPENDENCIES 

This section documents select project dependencies. Each dependency below lists where you can find relevant documentation / information. When authoring a change that involves a given dependency, you should use the links below to look up additional context if needed.

# COMMANDS 

This section documents a list of commands that you should be prepared to run if necessary. The section is broken down by the programming language, and then the purpose of the command (linting, testing, running) 

## Nix

### Linting

- `nix flake check -L`: This command is used to check the validity of a nix flake. It should be run on request to check the validity of a project with a `flake.nix` file. 
- `nixfmt <file>`: This command formats a file. It should be run following any edits
