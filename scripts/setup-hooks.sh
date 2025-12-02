#!/bin/sh
# Setup git hooks for development

HOOK_FILE=".git/hooks/pre-commit"

cat > "$HOOK_FILE" << 'EOF'
#!/bin/sh
stylua --check lua/ tests/ || exit 1
EOF

chmod +x "$HOOK_FILE"
echo "Pre-commit hook installed."
