# nova-patch.sh

if [[ "$1" == "stack" && "$2" == "install" ]]; then
    if is_service_enabled nova; then
        nova_patch="$TOP_DIR/files/romana-nova-reschedule.patch"
        if patch -d "$NOVA_DIR" -N --dry-run --silent -p1 < "$nova_patch"; then
            echo_summary "Patching nova module"
            patch -d "$NOVA_DIR" -p1 < "$nova_patch"
        fi
    fi
fi

