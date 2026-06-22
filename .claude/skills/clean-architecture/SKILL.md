---
name: clean-architecture
description: Use when deciding WHERE code belongs in the Quran app, reviewing layering, or fixing architecture violations (logic in screens, interfaces mixed with implementations, datasource/Hive/Dio called from UI). Triggers on "which layer", "where should this go", "clean architecture", "refactor layers", "dependency direction". Enforces data/domain/presentation separation and the interface-in-domain / impl-in-data rule.
---

# Clean Architecture (Quran app)

Dependencies point inward: **presentation → domain ← data**. Domain knows nothing about Flutter, Dio, or Hive.

## Layer responsibilities
| Layer | Holds | Knows about | Never |
|-------|-------|-------------|-------|
| **domain** | `param_*`/`e_*` entities, `r_*` interfaces, `uc_*` usecases | nothing external (pure Dart + dartz) | Flutter, Dio, Hive, JSON |
| **data** | `m_*` models, `ds_*` datasources, `box_*` Hive boxes, `r_impl_*` | Dio, Hive, JSON, bundled assets, domain interfaces | presentation |
| **presentation** | `sn_*` screens, `w_*` widgets, `cb_*` cubits + `s_*` states | domain (usecases/entities) | data internals, Dio, Hive |

## The hard rule
- **Interfaces (`r_*.dart`) live in `domain/repos/`.**
- **Implementations (`r_impl_*.dart`) live in `data/repos/`.**
- Never put them in the same folder.

## Flow (one direction)
```
SN<X> (screen)
  → CB<X> (cubit) emits S<X> (freezed state)
    → UC<Verb> (usecase)
      → R<X> (interface, domain)
        ⇧ implemented by RImpl<X> (data)
          → Ds(Local|Remote)<X>  /  Box<X> (Hive)  /  BaseDio
```

## Decision guide
- Parsing JSON, talking to Dio, reading a Hive box, or loading a bundled asset → **data** (`ds_*`, `box_*`, `m_*`).
- Mapping `DioException`/exceptions → `Failure` → **data** (`r_impl_*`, returns `Either<Failure, T>`).
- A single business action ("play range", "save bookmark") → **domain** (`uc_*`).
- Holding screen state / load status → **presentation** (`cb_*` + `s_*`).
- Formatting for display → **presentation** (widgets / extensions).

## Violations to fix on sight
- ❌ Screen/cubit importing Dio, a `ds_*`, or a Hive box directly.
- ❌ `Either`/`Failure` handling inside a cubit (do it in the repo, surface `failure.message` into state).
- ❌ Model (`M*`) used as the UI type — map to a `Param*`/`E*` entity or hold it deliberately in state.
- ❌ Business logic in `cb_*` or `sn_*` (belongs in a `uc_*`).
- ❌ `r_*` interface placed inside `data/`, or `r_impl_*` placed inside `domain/`.
- ❌ Repo method that doesn't return `Either<Failure, T>` (data sources may throw; repos catch and convert).
