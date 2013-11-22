TEMPLATE = subdirs
SUBDIRS = 3rdParty src

src.depends = 3rdParty

check.target = check
check.commands = "echo No tests yet"
QMAKE_EXTRA_TARGETS = check
