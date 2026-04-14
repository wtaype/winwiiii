class wii {
  static const String id = 'winwii';
  static const String app = 'Winwii';
  static const String repo = 'winwiiii';
  static const String desc = 'Gestiona como creador de contenidos profesionales';
  static const int lanzamiento = 2026;
  static const String by = '@wilder.taype';
  static const String link = 'https://wtaype.github.io/';
  static const String version = 'v10.10';
}

/** ACTUALIZACIÓN PRINCIPAL ONE DEV [MAIN] (1)
git add . ; git commit -m "Actualizacion Principal v10.10.10" ; git push origin main

//  Actualizar versiones de seguridad [TAG NUEVO] (2)
git tag v10 -m "Version v10" ; git push origin v10

// Actualizar versiones de seguridad [TAG REMPLAZO] (3)
git tag -d v10 ; git tag v10 -m "Version v10 actualizada" ; git push origin v10 --force

// Compiplacion + exe windows
flutter build windows --release
C:\midev\miflutter\wimp3\build\windows\x64\runner\Release\

 ACTUALIZACION TAG[END] */
