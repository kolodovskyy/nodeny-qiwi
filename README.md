# QIWI модуль для NoDeny 49/50

Модуль для биллинговой системы NoDeny реализует протокол взаимодействия с [платежной системой QIWI](http://www.qiwi.ua).

## Установка

- Скопировать скрипт qiwi.pl в директорию /usr/local/www/apache22/cgi-bin/qiwi
- При необходимости указать нужную платежную категорию в qiwi.pl (category)
- Создать файл /usr/local/nodeny/module/qiwi.log и установить права записи для веб-сервера
- Установить пароль на доступ к скрипту

```shell
<Directory /usr/local/www/apache22/cgi-bin/qiwi>
  AuthName "QIWI"
  AuthType basic
  require valid-user
  AuthUserFile /usr/local/www/apache22/cgi-bin/qiwi/.htpasswd
</Directory>

htpasswd -c /usr/local/www/apache22/cgi-bin/qiwi/.htpasswd qiwi
Password: PASSWORD
```

В качестве платежного кода используется код, который выводится у каждого абонента в его статистике внизу ("Ваш персональный платежный код: …")

## Maintainers and Authors

Yuriy Kolodovskyy (https://github.com/kolodovskyy)

## License

MIT License. Copyright 2013 [Yuriy Kolodovskyy](http://twitter.com/kolodovskyy)
