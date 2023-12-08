# Contributing

Thank you for considering contributing to Mammoth 🐘

You can contribute in the following ways:

- Finding and reporting bugs
- Contributing code to Mammoth by fixing bugs or implementing features
- Improving the documentation

## Bug reports

Bug reports and feature suggestions must use descriptive and concise titles and be submitted to [GitHub Issues](https://github.com/TheBLVD/mammoth/issues). Please use the search function to make sure that you are not submitting duplicates, and that a similar report or request has not already been resolved or rejected.

## Pull requests

**Please use clean, concise titles for your pull requests.** Unless the pull request is about refactoring code, updating dependencies or other internal tasks, assume that the person reading the pull request title is not a programmer or Mammoth developer, but instead a Mammoth user or server administrator, and **try to describe your change or fix from their perspective**. We use commit squashing, so the final commit in the main branch will carry the title of the pull request, and commits from the main branch are fed into the changelog. Start your pull request titles using one of the verbs "Add", "Change", "Deprecate", "Remove", or "Fix" (present tense).

Example:

| Not ideal                       | Better                                                               |
| ------------------------------- | -------------------------------------------------------------------- |
| Fixed NilPointer in AppDelegete | Fix nil error when removing favorite by tap caused by race condition |

It is not always possible to phrase every change in such a manner, but it is desired.

**The smaller the set of changes in the pull request is, the quicker it can be reviewed and merged.** Splitting tasks into multiple smaller pull requests is often preferable.

**Pull requests that do not pass automated checks may not be reviewed**. In particular, you need to keep in mind:

- Unit and integration tests (xctest)
- Code style rules (Swift Lint)
