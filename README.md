# repo-revanced
ReVanced Build APK

## Последняя поддерживаемая версия
- YouTube: 18.04.41 - версия сборки от ([inotia00](https://github.com/inotia00/rvx-builder/tree/revanced-extended))


Этот репозиторий позволит вам создавать ReVanced YouTube без полномочий root с помощью GitHub Actions. Это поможет людям, которые не хотят настраивать среду сборки на своих машинах.

### Как настроить подпись сборки
Вам понадобится Java Development Kit (JDK), OpenSSL и Linux.

1. Создайте новое хранилище ключей Java с помощью следующей команды

    keytool -keystore revancedKeystore.jks -genkey -keyalg RSA -alias revanced

2. Экспортируйте свой закрытый ключ с помощью следующей команды

    openssl base64 < revancedKeystore.jks | tr -d '\n' | tee revancedKeystore.jks.base64.txt

3. Перейдите в Настройки -> Секреты -> Действия(Settings -> Secrets -> Actions).

4. Создайте следующие секреты:

    - SIGNING_KEY: вставить содержимое файла clientkeystore.jks.base64.txt
    
    - ALIAS: псевдоним, указанный ранее с параметром -alias, т.е. revanced
    
    - KEY_STORE_PASSWORD: пароль хранилища ключей, который вы ввели ранее
    
    - KEY_PASSWORD: пароль ключа, который вы ввели ранее
