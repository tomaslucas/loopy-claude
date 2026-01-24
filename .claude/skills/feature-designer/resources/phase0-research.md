# Phase 0: Mandatory Research Checklist

Before designing anything:

1. ✅ Read `specs/README.md` (PIN lookup table)
2. ✅ Search for related specs:
   ```
   grep -r "keyword" specs/
   ```
3. ✅ Read related specs COMPLETELY
4. ✅ Review actual code implementation:
   ```
   grep -r "pattern" src/
   ```
5. ✅ Verify assumptions with user via AskUserQuestion

**Red flags:**
- ❌ Starting design without reading PIN
- ❌ Assuming how things work without reading code
- ❌ Skipping research phase
