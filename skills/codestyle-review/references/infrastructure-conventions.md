# Infrastructure Conventions Reference

## YAML

- 2-space indentation. Flag any other indentation width.
- No trailing whitespace.
- Meaningful key names that describe their purpose.
- Comments for non-obvious values, magic numbers, or complex configurations.
- Consistent quoting style (prefer unquoted unless quoting is required).
- Use `---` document separators when multiple documents are in one file.

## Helm

- Values file keys in camelCase (e.g., `replicaCount`, `servicePort`).
- Templates should use `nindent` for proper indentation in rendered output.
- Helper templates in `_helpers.tpl` — reusable labels, names, and selectors.
- Chart.yaml must have accurate `version` and `appVersion`.
- Flag hardcoded values in templates that should be in `values.yaml`.

## Makefiles

- All phony targets must have `.PHONY` declarations.
- Brief comments above non-obvious targets explaining what they do.
- Tab indentation for recipes (required by Make).
- Target names in lowercase with hyphens (e.g., `build-backend`, `deploy-staging`).
- Group related targets together with blank line separation.
- Include a `help` target that lists available targets.

## Dockerfile

- Use multi-stage builds.
- Pin base image versions (no `latest` tag).
- Minimize layers — combine related `RUN` commands.
- Use `.dockerignore` to exclude unnecessary files.
- Non-root user for the runtime stage.
- Labels for image metadata (`maintainer`, `version`).
