# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in loopy-claude, please report it via [GitHub Issues](https://github.com/tomaslucas/loopy-claude/issues).

Please include:
- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes (if you have them)

I will review security reports as time permits. Please note this is a personal project with no guaranteed response timeline.

## Scope

### In Scope

Security vulnerabilities in loopy-claude are limited to:
- Command injection vulnerabilities in the orchestrator
- Path traversal issues in file operations
- Unsafe handling of user input in bash scripts
- Privilege escalation through improper script execution
- Exposure of sensitive data through logs or error messages

### Out of Scope

The following are not considered security vulnerabilities:
- Security issues in Claude API itself (report to Anthropic)
- Security issues in third-party dependencies (report to maintainers)
- Issues requiring social engineering or physical access
- Denial of service through resource exhaustion (use responsibly)
- Security features that are intentionally absent (see philosophy)

## Security Design

Loopy-claude follows a "simple and transparent" security model:

1. **No Secret Management**: The tool does not store or manage API keys. Users must provide credentials via environment variables.

2. **Limited Blast Radius**: Each mode (prime, plan, build, audit, validate) has focused permissions and operates in a sandboxed manner.

3. **Human in the Loop**: All destructive operations require explicit human approval before execution.

4. **Auditable Execution**: All actions are logged to session files for review and debugging.

5. **No Network Access**: Beyond Claude API calls, the tool does not make network requests or download arbitrary code.

## What We Don't Do

Loopy-claude intentionally does not include:
- Automatic dependency updates
- Complex CI/CD pipelines
- Binary distribution
- Auto-update mechanisms
- Telemetry or analytics

These omissions are by design to maintain simplicity and transparency.

## Safe Usage

To use loopy-claude safely:

1. **Protect Your API Keys**: Never commit `ANTHROPIC_API_KEY` to version control
2. **Review Generated Code**: Always review code before committing or deploying
3. **Use in Isolated Environments**: Test in development environments first
4. **Keep Dependencies Updated**: Regularly update Anthropic SDK and other dependencies
5. **Review Session Logs**: Check `.claude/sessions/` for unexpected behavior

## Security Philosophy

Loopy-claude prioritizes:
- **Transparency over obscurity**: All code is readable bash and simple logic
- **Simplicity over features**: Fewer features mean smaller attack surface
- **Human judgment over automation**: You remain in control at all times

This approach may not satisfy all enterprise security requirements, and that's intentional. If you need more security features, consider forking and extending the tool.
