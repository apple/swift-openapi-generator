# Proposals

Collaborate on API changes to Swift OpenAPI Generator by writing a proposal.

## Overview

For non-trivial changes that affect the public API, the Swift OpenAPI Generator project adopts a ligthweight version of the [Swift Evolution](https://github.com/apple/swift-evolution/blob/main/process.md) process.

Writing a proposal first helps discuss multiple possible solutions early, apply useful feedback from other contributors, and avoid re-implementing the same feature multiple times.

While it's encouraged to get feedback by opening a pull request with a proposal early in the process, it's also important to consider the complexity of the implementation when evaluating different solutions (as per <doc:Project-scope-and-goals>). For example, this might mean including a prototype implementation of the feature in the same PR as the proposal document.

> Note: The goal of this process is to help solicit feedback from the whole community around the project, and we will continue to refine the proposal process itself. Use your best judgement, and don't hesitate to  propose changes to the proposal structure itself!

### Steps

1. Make sure there's a GitHub issue for the feature or change you would like to propose.
2. Duplicate the `SOAR-NNNN.md` document and replace `NNNN` with the next available proposal number.
3. Link the GitHub issue from your proposal, and fill in the proposal.
4. Open a pull request with your proposal and solicit feedback from other contributors.
5. Once a maintainer confirms that the proposal is ready for review, the state is updated accordingly. The review period is 7 days, and ends when one of the maintainers marks the proposal as Ready for Implementation, or Deferred.
6. Before the pull request is merged, there should be an implementation ready, either in the same pull request, or a separate one, linked from the proposal.
7. The proposal is considered Approved once the implementation and proposal PRs have been merged.

If you have any questions, tag [Honza Dvorsky](https://github.com/czechboy0) or [Si Beaumont](https://github.com/simonjbeaumont) in your issue or pull request on GitHub.

### Possible review states

- Awaiting Review
- In Review
- Ready for Implementation
- Approved
- Deferred

### Possible affected components

- generator
- runtime
- client transports
- server transports

## Topics

- <doc:SOAR-NNNN>
