# Первый релиз

## Общие проверки

1. Обновить version в pubspec.yaml.
2. Выполнить flutter analyze и flutter test.
3. Проверить длинную рукопись, импорт EPUB/FB2 и все форматы экспорта.
4. Проверить восстановление резервной копии после принудительного закрытия.
5. Проверить Windows, телефон и планшет в портретной и альбомной ориентациях.

## Android

1. До публикации окончательно выбрать applicationId: после выхода в Google
   Play изменить его для существующего приложения нельзя.
2. Создать закрытый upload keystore:

       keytool -genkeypair -v -keystore android\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

3. Скопировать android/key.properties.example в android/key.properties и
   указать реальные пароли.
4. Не добавлять .jks и key.properties в Git; хранить их отдельную
   зашифрованную резервную копию.
5. Собрать подписанный AAB:

       .\tool\build_android_release.ps1 -Flutter C:\Users\va97r\.flutter-sdk\flutter\bin\flutter.bat

6. Проверить AAB во внутреннем тестировании Google Play до production.

## Windows

1. Создать release ZIP:

       .\tool\package_windows_release.ps1 -Flutter C:\Users\va97r\.flutter-sdk\flutter\bin\flutter.bat -Version 1.0.0

2. Установить/распаковать пакет на другом компьютере без Flutter SDK.
3. Перед публичным распространением добавить установщик и подпись кода,
   чтобы Windows SmartScreen мог проверять издателя.
4. Опубликовать SHA-256 рядом с файлом загрузки.

## Перед публикацией

- Финальные название, значок, скриншоты и описание магазина.
- Политика конфиденциальности и адрес поддержки.
- Release notes и известные ограничения.
- Тег Git v1.0.0 только после приёмочного теста артефактов.
