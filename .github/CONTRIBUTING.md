# Contributing

Quick set of guidelines for contributing to this repository. After you have checked out the code and are ready to send in your PR, just make sure to follow these steps:

- Your changes are covered by the tests, run `make qa` to lint and test your changes.
- Your changes are reflected in the [README.md](../README.md) or any other docs that are relevant.
- Once you are ready to make your commits, ensure they are:
  - atomic, meaning they focus on a single set of changes
  - the commit message is clear, we suggest [this standard](https://chris.beams.io/posts/git-commit/).
- Follow our PR template when opening the PR.

What kind of changes are we looking for?

- More tests and quality assurance processes
- Vulnerability scanning improvements
- Docker helper/scripts that are generic enough for more people

What should you be careful about?

- Breaking backward compatibility changes
- Introducing very specific changes limited to a single use case. These are better done via extending the image

Thank you for contributing!
