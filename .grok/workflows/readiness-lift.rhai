let meta = #{
    name: "readiness-lift",
    description: "Parallel-check the dsh-watcher readiness edits, fix only real breakages, and store a new local report",
    when_to_use: "After readiness edits on dsh-watcher, verify the tree in parallel and rescore it",
    phases: [
        #{ title: "Verify", detail: "four auditors, no edits" },
        #{ title: "Finish", detail: "fix real breakages and store the report" },
    ],
};

let audit_schema = #{
    "type": "object",
    "required": ["items"],
    "properties": #{
        "items": #{
            "type": "array",
            "maxItems": 30,
            "items": #{
                "type": "object",
                "required": ["id", "numerator", "skipped", "rationale"],
                "properties": #{
                    "id": #{ "type": "string" },
                    "numerator": #{ "type": "integer" },
                    "skipped": #{ "type": "boolean" },
                    "rationale": #{ "type": "string" },
                    "evidence": #{ "type": "string" },
                },
            },
        },
    },
};

let report_schema = #{
    "type": "object",
    "required": ["level", "percent", "report", "markdown", "blockers"],
    "properties": #{
        "level": #{ "type": "integer" },
        "percent": #{ "type": "string" },
        "report": #{ "type": "string" },
        "markdown": #{ "type": "string" },
        "blockers": #{
            "type": "array",
            "maxItems": 12,
            "items": #{ "type": "string" },
        },
    },
};

let repo = "/Volumes/Workspace/Projects/dsh-watcher";
let cli = "/Users/wu/.grok/skills/agent-readiness/_runtime/scripts/readiness.py";
let state_dir = "/tmp/dsh-watcher-readiness-state";

phase("Verify");

let style_prompt = "You are a read-only auditor. Repository: " + repo + ". ";
style_prompt += "Do not create, edit, or delete any file. Use read_file, grep, and shell only to inspect. ";
style_prompt += "Score each id for the ONE app at '.'. numerator is 1 pass, 0 fail, or 0 with skipped true. ";
style_prompt += "Skip only when the rubric text says the criterion does not apply. ";
style_prompt += "Ids: lint_config, type_check, formatter, pre_commit_hooks, strict_typing, naming_consistency, ";
style_prompt += "cyclomatic_complexity, large_file_detection, dead_code_detection, duplicate_code_detection, ";
style_prompt += "code_modularization, tech_debt_tracking, n_plus_one_detection, unit_tests_exist, ";
style_prompt += "integration_tests_exist, unit_tests_runnable, test_performance_tracking, flaky_test_detection, ";
style_prompt += "test_coverage_thresholds, test_naming_conventions, test_isolation, interactive_qa_exists, ";
style_prompt += "interactive_qa_runnable. ";
style_prompt += "unit_tests_runnable passes only with a Node/Vitest/Jest list or collect command that exits 0 and does not execute tests. ";
style_prompt += "node --test has no list mode; do not mark it passed just because pnpm test succeeds. ";
style_prompt += "Read package.json, eslint.config.js, scripts/run-tests.mjs, .husky/pre-commit, AGENTS.md, and tests/acceptance/restore-session.mjs. ";
style_prompt += "Run: pnpm lint; pnpm format:check; pnpm test:coverage. Record real exit codes in evidence. ";
style_prompt += "Return one item per id. rationale under 400 characters. evidence is a short file:line or command excerpt.";

let build_prompt = "You are a read-only auditor. Repository: " + repo + ". ";
build_prompt += "Do not create, edit, or delete any file. ";
build_prompt += "Score each id. numerator 1 pass, 0 fail, or 0 with skipped true only when the rubric says skip. ";
build_prompt += "Ids: build_cmd_doc, deps_pinned, vcs_cli_tools, automated_pr_review, agentic_development, ";
build_prompt += "fast_ci_feedback, build_performance_tracking, deployment_frequency, single_command_setup, ";
build_prompt += "feature_flag_infrastructure, release_notes_automation, progressive_rollout, rollback_automation, ";
build_prompt += "monorepo_tooling, heavy_dependency_detection, unused_dependencies_detection, version_drift_detection, ";
build_prompt += "release_automation, dead_feature_flag_detection, agents_md, readme, automated_doc_generation, ";
build_prompt += "skills, documentation_freshness, api_schema_docs, service_flow_documented, agents_md_validation. ";
build_prompt += "This is one npm plugin, not a monorepo and not an infra service. ";
build_prompt += "fast_ci_feedback and automated_pr_review require live gh evidence of merged PR checks or bot review comments. ";
build_prompt += "A workflow file alone does not pass those two. dependency configuration alone does not pass historical deploy frequency. ";
build_prompt += "dead_feature_flag_detection skips when feature_flag_infrastructure fails. agents_md_validation is NOT skippable; score 0 if no AGENTS.md check exists. ";
build_prompt += "Read AGENTS.md, docs/architecture.md, .github/workflows/ci.yml, .github/workflows/publish.yml, ";
build_prompt += "renovate.json, .size-limit.json, knip.json, .jscpd.json, scripts/check-agents-md.mjs, scripts/measure-build.mjs, ";
build_prompt += ".claude/skills/dsh-watcher/SKILL.md. ";
build_prompt += "Run: gh pr list --state merged --limit 5 --json number,statusCheckRollup; pnpm deadcode; pnpm duplicates; pnpm size; pnpm check:agents. ";
build_prompt += "Return one item per id.";

let security_prompt = "You are a read-only auditor. Repository: " + repo + ". ";
security_prompt += "Do not create, edit, or delete any file. ";
security_prompt += "Score each id. numerator 1 pass, 0 fail, or 0 with skipped true only when the rubric says skip. ";
security_prompt += "Ids: branch_protection, secret_scanning, codeowners, automated_security_review, ";
security_prompt += "dependency_update_automation, gitignore_comprehensive, dast_scanning, pii_handling, ";
security_prompt += "privacy_compliance, secrets_management, log_scrubbing, min_release_age, ";
security_prompt += "issue_templates, issue_labeling_system, backlog_health, pr_templates, ";
security_prompt += "product_analytics_instrumentation, error_to_insight_pipeline. ";
security_prompt += "Repo is https://github.com/aa2246740/dsh-watcher. gh is logged in as aa2246740 with admin. ";
security_prompt += "dependency_update_automation passes only if a real Dependabot or Renovate PR exists; renovate.json alone is not enough. ";
security_prompt += "Do not treat a local plugin as having product analytics or a Sentry issue pipeline. ";
security_prompt += "dast_scanning skips for a plugin that is not its own web service. privacy_compliance skips because the plugin does not collect end-user data. ";
security_prompt += "Read .gitignore, renovate.json, .github/CODEOWNERS, .github/ISSUE_TEMPLATE, .github/pull_request_template.md, ";
security_prompt += "docs/data-handling.md, src/log.ts, .github/workflows/publish.yml, scripts/security-review.mjs. ";
security_prompt += "Run: gh api repos/aa2246740/dsh-watcher/branches/main/protection; gh label list --limit 40; ";
security_prompt += "gh issue list --state open --limit 20 --json title,labels; gh pr list --state all --limit 5 --search author:app/renovate --json number,title; ";
security_prompt += "node scripts/security-review.mjs. Return one item per id.";

let ops_prompt = "You are a read-only auditor. Repository: " + repo + ". ";
ops_prompt += "Do not create, edit, or delete any file. ";
ops_prompt += "Score each id. numerator 1 pass, 0 fail, or 0 with skipped true only when the rubric says skip. ";
ops_prompt += "Ids: devcontainer, env_template, local_services_setup, database_schema, devcontainer_runnable, ";
ops_prompt += "structured_logging, distributed_tracing, metrics_collection, code_quality_metrics, ";
ops_prompt += "error_tracking_contextualized, alerting_configured, runbooks_documented, deployment_observability, ";
ops_prompt += "health_checks, circuit_breakers, profiling_instrumentation. ";
ops_prompt += "This is an in-host UI plugin with no database, no sidecar, and no long-running service. ";
ops_prompt += "Skip local_services_setup, database_schema, health_checks, circuit_breakers, profiling_instrumentation for that reason. ";
ops_prompt += "Skip devcontainer_runnable if `command -v devcontainer` exits non-zero. ";
ops_prompt += "Do not pass tracing, metrics, Sentry, alerting, or deployment dashboards unless the code or docs actually wire them. ";
ops_prompt += "code_quality_metrics can pass from the coverage floors in scripts/run-tests.mjs. ";
ops_prompt += "Read .devcontainer/devcontainer.json, .env.example, src/log.ts, docs/runbook.md, scripts/run-tests.mjs, AGENTS.md. ";
ops_prompt += "Run: command -v devcontainer; test -f .env.example; pnpm check:todos. Return one item per id.";

let audits = parallel([
    #{ prompt: style_prompt, label: "audit:style-tests", capability_mode: "execute", output_schema: audit_schema },
    #{ prompt: build_prompt, label: "audit:build-docs", capability_mode: "execute", output_schema: audit_schema },
    #{ prompt: security_prompt, label: "audit:security-tasks", capability_mode: "execute", output_schema: audit_schema },
    #{ prompt: ops_prompt, label: "audit:env-ops", capability_mode: "execute", output_schema: audit_schema },
]);

let packed = [];
let audit_notes = "";
for row in audits {
    if row != () && row.success && row.output != () && row.output.items != () {
        for item in row.output.items {
            packed.push(item);
        }
    } else {
        audit_notes += "one auditor returned nothing usable. ";
    }
}
log("audited items: " + packed.len().to_string());

phase("Finish");

let finish_prompt = "Repository " + repo + " already has uncommitted readiness edits. Do not revert them, do not git checkout, and do not commit. ";
finish_prompt += "Auditor notes: " + json_encode(packed) + ". Gaps: " + audit_notes + ". ";
finish_prompt += "First re-run pnpm lint, pnpm format:check, pnpm deadcode, pnpm duplicates, pnpm size, pnpm check:agents, pnpm check:todos, pnpm test:coverage. ";
finish_prompt += "If one of those fails because of a real bug in the new tooling, fix that bug only. ";
finish_prompt += "Do not add Sentry, analytics, OpenTelemetry, PagerDuty, fake PRs, fake CI history, or branch protection. ";
finish_prompt += "Do not retitle the open GitHub issue. ";
finish_prompt += "Then score all 84 readiness criteria yourself by reading the tree. ";
finish_prompt += "Use python3 " + cli + " prepare " + repo + " --output /tmp/dsh-watcher-readiness-work-3 --state-dir " + state_dir + ". ";
finish_prompt += "Fill that evaluation.json. Skipped criteria use numerator null only when the rubric marks them skippable. ";
finish_prompt += "agents_md_validation is not skippable. App denominators stay null. ";
finish_prompt += "Then run python3 " + cli + " report " + repo + " --input /tmp/dsh-watcher-readiness-work-3/evaluation.json --state-dir " + state_dir + " --json. ";
finish_prompt += "Return level, percent, the report JSON path, the markdown path, and blockers that still prevent Level 5.";

let fin = agent(finish_prompt, #{
    label: "finish:rescore",
    capability_mode: "execute",
    output_schema: report_schema,
});

if fin == () || fin.success != true || fin.output == () {
    complete(#{
        status: "verify-only",
        audited: packed.len(),
        note: "The finish agent did not store a report.",
    });
}

complete(#{
    status: "scored",
    level: fin.output.level,
    percent: fin.output.percent,
    report: fin.output.report,
    markdown: fin.output.markdown,
    blockers: fin.output.blockers,
    audited: packed.len(),
});
