#!/usr/bin/env bash
# Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
# Licensed under the Business Source License 1.1 (BUSL-1.1).
#
# Full Automated Validation Gate for SarvMD Workspaces.
# Ensures static analysis and test suites pass across core, UI, and CLI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_step() {
  echo -e "\n${BOLD}${BLUE}===> $1${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_failure() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

log_step "1/7 Running Static Analysis on sarvmd_core..."
(cd "$WORKSPACE_ROOT/packages/sarvmd_core" && dart analyze) \
  && log_success "sarvmd_core analyze passed" \
  || log_failure "sarvmd_core analyze failed"

log_step "2/7 Running Unit Tests on sarvmd_core..."
(cd "$WORKSPACE_ROOT/packages/sarvmd_core" && dart test) \
  && log_success "sarvmd_core test passed" \
  || log_failure "sarvmd_core test failed"

log_step "3/7 Running Static Analysis on sarvmd_composer..."
(cd "$WORKSPACE_ROOT/packages/sarvmd_composer" && dart analyze) \
  && log_success "sarvmd_composer analyze passed" \
  || log_failure "sarvmd_composer analyze failed"

log_step "4/7 Running Unit Tests on sarvmd_composer..."
(cd "$WORKSPACE_ROOT/packages/sarvmd_composer" && dart test) \
  && log_success "sarvmd_composer test passed" \
  || log_failure "sarvmd_composer test failed"

log_step "5/7 Running Static Analysis on sarvmd_ui..."
(cd "$WORKSPACE_ROOT/apps/sarvmd_ui" && flutter analyze) \
  && log_success "sarvmd_ui analyze passed" \
  || log_failure "sarvmd_ui analyze failed"

log_step "6/7 Running Widget & Unit Tests on sarvmd_ui..."
(cd "$WORKSPACE_ROOT/apps/sarvmd_ui" && flutter test) \
  && log_success "sarvmd_ui test passed" \
  || log_failure "sarvmd_ui test failed"

log_step "7/7 Running Static Analysis on sarvmd_cli..."
(cd "$WORKSPACE_ROOT/apps/sarvmd_cli" && dart analyze) \
  && log_success "sarvmd_cli analyze passed" \
  || log_failure "sarvmd_cli analyze failed"

echo -e "\n${BOLD}${GREEN}=========================================${NC}"
echo -e "${BOLD}${GREEN}  ALL VALIDATION GATE CHECKS PASSED!     ${NC}"
echo -e "${BOLD}${GREEN}=========================================${NC}\n"

