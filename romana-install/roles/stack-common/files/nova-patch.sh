# nova-patch.sh

if [[ "$1" == "stack" && "$2" == "install" ]]; then
    if is_service_enabled nova; then
        echo_summary "Patching nova module"
        patch -d "$NOVA_DIR" -p1 < "$TOP_DIR/files/romana-nova-reschedule.patch"
    fi
fi

