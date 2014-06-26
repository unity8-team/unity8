# export_qmlplugin macro
include(Plugins)

add_subdirectory(artwork)

# export the qmldir, *.qml files.
export_qmlfiles(Ubuntu.Settings.Components Ubuntu/Settings/Components)
