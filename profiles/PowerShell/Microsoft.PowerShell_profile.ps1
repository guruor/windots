# File for Current User, Current Host - $PROFILE.CurrentUserCurrentHost
function StartKanata {
    kanata-tray
}

function StopKanata {
    taskkill /f /im kanata-tray.exe
}

function StartTiling {
    komorebic start -c "$Env:USERPROFILE\.config\komorebi\komorebi.json" --whkd
}

function StopTiling {
    taskkill /f /im komorebi.exe
}