# Multipart parsing

```mermaid
---
title: Multipart Serializer
---
stateDiagram-v2
    [*] --> s_initial
    s_initial : initial

    s_pending_next : pending next
    s_initial --> s_pending_next: [D] next called
    
    s_received_part : received part
    s_pending_next --> s_received_part: [A] pull part

    state inspect_part <<choice>>
    s_received_part --> inspect_part
    inspect_part --> s_finished: nil
    inspect_part --> s_has_nonnil_part: non-nil

    s_has_nonnil_part: has a non-nil part

    s_finished : finished
    s_finished --> s_finished: [D] next called, [A] return nil
    s_finished --> [*]
```

- Available methods on the parser:
    - `next called`: called by the consumer

- Available actions made by the parser:
    - `pull part`: pull a part from the upstream iterator
    - `return nil`: return nil (end of sequence)
    - `return chunk`: return a chunk
