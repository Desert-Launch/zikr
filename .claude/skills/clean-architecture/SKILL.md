---
name: clean-architecture
description: Use when deciding WHERE code belongs in Taliah, reviewing layering, or fixing architecture violations (logic in screens, interfaces mixed with implementations, datasource called from UI). Triggers on "which layer", "where should this go", "clean architecture", "refactor layers", "dependency direction". Enforces data/domain/presentation separation and the interface-in-domain / impl-in-data rule.
---

# Clean Architecture (Taliah)

Dependencies point inward: **presentation → domain ← data**. Domain knows nothing about Flutter, Dio, or Hive.

## Layer responsibilities
| Layer | Holds | Knows about | Never |
|-------|-------|-------------|-------|
| **domain** | `param_*` entities, `r_*` interfaces, `uc_*` usecases | nothing external (pure Dart + dartz) | Flutter, Dio, Hive, JSON |
| **data** | `m_*` models, `ds_*` datasources, `r_impl_*` | Dio, Hive, JSON, domain interfaces | presentation |
| **presentation** | `sn_*` screens, `w_*` widgets, `mg_*` managers | domain (usecases/entities) | data internals, Dio |

## The hard rule
- **Interfaces (`r_*.dart`) live in `domain/repos/`.**
- **Implementations (`r_impl_*.dart`) live in `data/repos/`.**
- Never put them in the same folder.

## Flow (one direction)
```
SN<X> (screen)
  → Mg<X> (manager, provider)
    → UC<Verb> (usecase)
      → R<X> (interface, domain)
        ⇧ implemented by RImpl<X> (data)
          → Ds(Remote|Mock)<X>
            → BaseDio / MockDataService
```

## Decision guide
- Parsing JSON / talking to Dio or Hive → **data** (`ds_*` or `m_*`).
- Mapping `DioException` → `Failure` → **data** (`r_impl_*`).
- A single business action ("submit assessment") → **domain** (`uc_*`).
- Holding screen state / loading flags → **presentation** (`mg_*`).
- Formatting for display → **presentation** (extensions in widgets).

## Violations to fix on sight
- ❌ Screen/manager importing Dio or a datasource.
- ❌ `Either`/`Failure` handling inside a manager (do it in repo, surface `.message`).
- ❌ Model (`M*`) used as the UI type — map to `Param*` entity.
- ❌ Business logic in `mg_*` or `sn_*`.
- ❌ `r_*` interface inside `data/`.
