# Executable acceptance requirements

| ID | Requirement | Evidence |
|---|---|---|
| R01 | Nominal start creates one cycle and returns within 6 mm of home | `nominal` |
| R02 | Normal travel stays below 20 mm overshoot | `nominal`, `payload_disturbance` |
| R03 | Force never exceeds configured actuator limit | Every scenario |
| R04 | Inhibited states command zero motor force | Every scenario |
| R05 | Emergency is latched; live reset cannot clear it | `emergency_stop` and unit test |
| R06 | Reset while disabled clears a recovered fault without restarting | `emergency_stop` |
| R07 | Nominal modeled emergency stopping distance is below 60 mm | `emergency_stop`; model-only criterion |
| R08 | Invalid encoder quality inhibits motion by the next scan | `encoder_fault` |
| R09 | Missing part prevents cycle start and motion | `missing_part` |
| R10 | Missing work-station acknowledgment trips without counting a cycle | `process_timeout` |
| R11 | Held start cannot trigger repetitive cycling | `held_start` |
| R12 | Out-of-range initial position is detected before motion | `travel_limit` |
| R13 | Insufficient actuator force causes timeout, not false completion | `weak_actuator` |
| R14 | Manual jog remains below 0.18 m/s in the defined jog scenario | `manual_jog` |
| R15 | Reference acceleration stays within configured limit | Unit test |
| R16 | Sustained saturation does not accumulate an unbounded integrator | Unit test |
| R17 | A fast target crossing cannot complete a move | Unit test |
| R18 | A stale acknowledgment cannot release the return move | `stale_ack` and unit test |

All numeric criteria are declared before the reported run. They are demonstrator requirements, not requirements for a physical installation. `run_acceptance` throws on the first violation; an unexecuted scenario is never marked as passed. The exported traces are decimated to 10 ms for review, while assertions use the full solver trace.
