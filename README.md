# repo-revanced
ReVanced Build APK


Этот репозиторий позволит вам создавать ReVanced и ReVanced Music без полномочий root с помощью GitHub Actions. Это поможет людям, которые не хотят настраивать среду сборки на своих машинах.

# Как настроить подпись сборки
Вам понадобится Java Development Kit (JDK), OpenSSL и Linux.

1.Создайте новое хранилище ключей Java с помощью следующей команды

    keytool -keystore clientkeystore.jks -genkey -alias client

2.Экспортируйте свой закрытый ключ с помощью следующей команды

    openssl base64 < clientkeystore.jks | tr -d '\n' | tee clientkeystore.jks.base64.txt

3.Перейдите в Настройки -> Секреты -> Действия.

4.Создайте следующие секреты:

    - SIGNING_KEY: содержимое файла clientkeystore.jks.base64.txt
    
    - ALIAS: псевдоним, указанный ранее с параметром -alias
    
    - KEY_STORE_PASSWORD: пароль хранилища ключей, который вы ввели ранее
    
    - KEY_PASSWORD: пароль ключа, который вы ввели ранее
