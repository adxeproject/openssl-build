$install_dir = $args[0]

if ((Test-Path $install_dir -PathType Container)) {
    echo "[windows] Cleaning ${install_dir}..."
    sremove (Join-Path $install_dir 'include')
    sremove (Join-Path $install_dir 'lib/*.lib')
    sremove (Join-Path $install_dir 'lib/*.a')
    ls -R "$install_dir"
}
