#!/usr/bin/env bash
# install.sh — flip-the-script needs no extra wiring.
#
# The plugin's hooks and skill are loaded automatically by Claude Code from the
# manifest once the plugin is enabled. There is no statusLine, MCP server, or
# writable data tree to set up. This script is a no-op that just confirms that.
set -u
echo "flip-the-script installed — hooks load automatically, no extra setup."
exit 0
